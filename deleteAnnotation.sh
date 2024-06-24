#!/bin/bash
set -e

delete_annotation() {
    local annotation_id="$1"
    local delete_result=$(curl -X DELETE "${grafana_server}/api/annotations/${annotation_id}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${grafana_token}")
    echo ""
    echo "||#####################||"
    if [ -z "${delete_result}" ]; then
        echo "Failed to delete annotation: ${annotation_id}"
    else
        echo "Annotation deleted: ${annotation_id}"
    fi
}

main() {
    local grafana_server="$1"
    local grafana_token="$2"
    shift 2 # Shift the first two arguments out to process the rest as tags
    local tags=("$@") # Remaining arguments are considered as tags
    local tags_query=""
    for tag in "${tags[@]}"; do
        tags_query+="&tags=${tag}"
    done

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