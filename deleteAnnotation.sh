#!/bin/bash
set -e

build_tags_query() {
    # Function to build tags query
    # Parameters:
    #   - tags: The tags to build the query
    # Returns:
    #   - tags_query: The built tags query
    local tags=("$@")
    local tags_query=""
    local first_tag=1 # Flag to indicate the first tag

    for tag in "${tags[@]}"; do
        if [[ $first_tag -eq 1 ]]; then
            tags_query+="tags=${tag}"
            first_tag=0
        else
            tags_query+="&tags=${tag}"
        fi
    done

    echo "$tags_query"
}

delete_annotation() {
    # Function to delete an annotation
    # Parameters:
    #   - annotation_id: The ID of the annotation to delete
    local annotation_id="$1"
    local delete_result

    echo ""
    echo "||#####################||"
    delete_result=$(curl -X DELETE "${grafana_server}/api/annotations/${annotation_id}" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${grafana_token}")
    if [ -z "${delete_result}" ]; then
        echo "${delete_result}"
    else
        echo "Annotation deleted: ${annotation_id}"
    fi
}

main() {
    # Main function to delete an annotation from Grafana
    # Parameters:
    #   - grafana_server: The URL of the Grafana server
    #   - grafana_token: The authentication token for Grafana
    #   - tags: The tags to search for annotations
    local grafana_server="$1"
    local grafana_token="$2"
    shift 2 # Shift the first two arguments out to process the rest as tags
    local tags=("$@") # Remaining arguments are considered as tags
    local tags_query
    tags_query=$(build_tags_query "${tags[@]}")

    echo ""
    echo "||#####################||"
    echo "Searching for annotations with tags: ${tags[*]}"
    echo "------"
    get_result=$(curl -X GET "${grafana_server}/api/annotations?${tags_query}" \
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

    echo "$get_result" | jq .

    annotation_ids=($(jq -r '.[] | .id' <<<"${get_result}"))
    if [ ${#annotation_ids[@]} -eq 0 ]; then
        echo ""
        echo "||!!!!!!!!!!!!!!!!!!!!!||"
        echo "No annotations found"
        echo "------"
        exit 1
    fi
    for annotation_id in "${annotation_ids[@]}"; do
        delete_annotation "${annotation_id}"
    done
}

# Call the main function
main "$@"