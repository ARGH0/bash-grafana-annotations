#!/bin/bash

set -e

# Function to build annotation URI
build_annotation_uri() {
    # Build the annotation uri based on input parameters
    # Parameters:
    #   - grafana_server: The Grafana server URL
    #   - kind: The kind of annotation
    #   - type: The type of annotation
    #   - environment: The environment for the annotation
    #   - build_number: The build number for the annotation
    #   - component: The component for the annotation (optional)
    #   - image_tag: The image tag for the annotation (optional)
    #   - collection: The collection for the annotation (optional)
    # Returns:
    #   - annotationGetUri: The built annotation URI
    local grafana_server="$1"
    local kindtagsearch="kind:${kind}"
    local typetagsearch="type:${type}"
    local envtagsearch="env:${environment}"
    local buildtagsearch="build:${build_number}"
    local componenttagsearch="component:${component}"
    local imagetagsearch="image:${image_tag}"
    local collectiontagsearch="collection:${collection}"

    local annotationGetUri="${grafana_server}/api/annotations?tags=${buildtagsearch}&tags=${envtagsearch}"

    if [ -n "${kind}" ]; then
        annotationGetUri="${annotationGetUri}&tags=${kindtagsearch}"
    fi

    if [ -n "${type}" ]; then
        annotationGetUri="${annotationGetUri}&tags=${typetagsearch}"
    fi

    if [ -n "${component}" ]; then
        annotationGetUri="${annotationGetUri}&tags=${componenttagsearch}"
    fi

    if [ -n "${image_tag}" ]; then
        annotationGetUri="${annotationGetUri}&tags=${imagetagsearch}"
    fi

    if [ -n "${collection}" ]; then
        annotationGetUri="${annotationGetUri}&tags=${collectiontagsearch}"
    fi

    echo "$annotationGetUri"
}

# Main function
main() {
    # Main function to update an annotation in Grafana
    # Parameters:
    #   - grafana_server: The Grafana server URL
    #   - grafana_token: The Grafana API token
    #   - kind: The kind of annotation
    #   - type: The type of annotation
    #   - environment: The environment for the annotation
    #   - build_number: The build number for the annotation
    #   - component: The component for the annotation
    #   - image_tag: The image tag for the annotation
    #   - collection: The collection for the annotation
    local grafana_server="$1"
    local grafana_token="$2"
    local kind="$3"
    local type="$4"
    local environment="$5"
    local build_number="$6"
    local component="$7"
    local image_tag="$8"
    local collection="$9"

    local annotationGetUri=$(build_annotation_uri "$grafana_server" "$kind" "$type" "$environment" "$build_number" "$component" "$image_tag" "$collection")

    echo "--"
    echo "${annotationGetUri}"
    echo "--"

    local get_result=$(curl -X GET "${annotationGetUri}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${grafana_token}")

    if [ -z "${get_result}" ]; then
        echo ""
        echo "||!!!!!!!!!!!!!!!!!!!!!||"
        echo "No annotations found"
        echo "------"
        exit 1
    fi

    local annotation_id="$(jq -r '.[] | .id' <<<"${get_result}")"

    if [ "$(wc -w <<< "${annotation_id}")" -gt 1 ]; then
        echo ""
        echo "||!!!!!!!!!!!!!!!!!!!!!||"
        echo "Multiple annotations found"
        echo "------"
        exit 1
    fi

    local current_end_time_seconds=$((1000 * $(date +%s)))

    # create an annotation request body
    local json_string="$(
        jq -n --arg timeEnd "$current_end_time_seconds" \
            '{
                "timeEnd": ( $timeEnd | tonumber),
            }'
    )"

    local patch_result=$(curl -X PATCH "${grafana_server}/api/annotations/${annotation_id}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${grafana_token}" \
        -d "${json_string}")

    echo ""
    echo "||#####################||"
    echo "Annotation updated: ${annotation_id}"
}

# Call main function with all arguments
main "$@"