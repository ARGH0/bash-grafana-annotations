#!/bin/bash

# Script to add an annotation to Grafana

set -e

build_tags() {
    # Build tags based on input parameters
    # Parameters:
    #   - kind: The kind of annotation
    #   - type: The type of annotation
    #   - environment: The environment for the annotation
    #   - build_number: The build number for the annotation
    #   - component: The component for the annotation (optional)
    #   - image_tag: The image tag for the annotation (optional)
    #   - collection: The collection for the annotation (optional)
    # Returns:
    #   - tags: A comma-separated string of tags
    local kind="$1"
    local type="$2"
    local environment="$3"
    local build_number="$4"
    local component="$5"
    local image_tag="$6"
    local collection="$7"

    local tags=("kind:${kind}" "type:${type}" "env:${environment}" "build:${build_number}")

    if [[ -n "$component" ]]; then
        tags+=("component:${component}")
    fi

    if [[ -n "$image_tag" ]]; then
        tags+=("image:${image_tag}")
    fi

    if [[ -n "$collection" ]]; then
        tags+=("collection:${collection}")
    fi

    echo $(printf '"%s",' "${tags[@]}" | sed 's/,$//')
}

build_text() {
    # Build text based on input parameters
    # Parameters:
    #   - type: The type of annotation
    #   - component: The component for the annotation
    #   - environment: The environment for the annotation
    #   - build_number: The build number for the annotation
    #   - collection: The collection for the annotation
    # Returns:
    #   - text: The built text for the annotation
    local type="$1"
    local component="$2"
    local environment="$3"
    local build_number="$4"
    local collection="$5"

    local text=""

    if [[ "$kind" == "deployment_pipeline" ]]; then
        text="Deployment for ${type} pipeline ${build_number} to ${environment}"
    fi

    if [[ -z "$text" ]]; then
        if [[ "$type" == "service" ]]; then
            text="Deploying ${component} to ${environment}"
        elif [[ "$type" == "infrastructure" ]]; then
            text="Deploying ${component} to ${environment}"
        elif [[ "$type" == "monitoring" ]]; then
            text="Deploying ${component} to ${environment}"
        elif [[ "$type" == "infrajobs" ]]; then
            text="Running job ${collection} on ${environment}"
        else
            text="No specification for type: ${type}"
        fi
    fi

    echo "$text"
}

main() {
    # Main function to add an annotation to Grafana
    # Parameters:
    #   - grafana_server: The URL of the Grafana server
    #   - grafana_token: The authentication token for Grafana
    #   - kind: The kind of annotation
    #   - type: The type of annotation
    #   - environment: The environment for the annotation
    #   - build_number: The build number for the annotation
    #   - component: The component for the annotation (optional)
    #   - image_tag: The image tag for the annotation (optional)
    #   - collection: The collection for the annotation (optional)
    #   - pipeline_type: The type of pipeline (optional)
    local grafana_server="$1"
    local grafana_token="$2"
    local kind="$3"
    local type="$4"
    local environment="$5"
    local build_number="$6"
    local component="$7"
    local image_tag="$8"
    local collection="$9"
    local pipeline_type="${10}"

    local tags_string
    tags_string=$(build_tags "$kind" "$type" "$environment" "$build_number" "$component" "$image_tag" "$collection" "$pipeline_type")
    local text
    text=$(build_text "$type" "$component" "$environment" "$build_number" "$collection")

    local current_time_seconds=$((1000 * $(date +%s)))

    # create an annotation request body
    local json_string
    json_string="$(
        jq -n --arg time "$current_time_seconds" \
            --arg timeEnd "$current_time_seconds" \
            --argjson tags "[$tags_string]" \
            --arg text "$text" \
            '{
                "time": ($time | tonumber),
                "timeEnd": ( $timeEnd | tonumber),
                "tags": $tags,
                "text": $text
            }'
    )"

    # Send an annotation to Grafana
    local post_result
    post_result=$(curl -X POST "${grafana_server}/api/annotations" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${grafana_token}" \
        -d "${json_string}")

    local annotation_id
    annotation_id="$(jq -r '.id' <<<"${post_result}")"

    echo ""
    echo "||#####################||"
    echo "Annotation created: ${annotation_id}"
}

# Call main function with all arguments
main "$@"