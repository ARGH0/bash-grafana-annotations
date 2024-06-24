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
    local environment="$5"
    local build_number="$6"
    local component="$7"

    buildtagsearch="build:${BUILD_NUMBER}"
    servicetagsearch="service:${component}"

    echo ""
    echo "||#####################||"
    echo "Searching for annotations with tags: ${buildtagsearch} and ${servicetagsearch}"
    echo "------"

    get_result=$(curl -X GET "${grafana_server}/api/annotations?tags=${buildtagsearch}&tags=${servicetagsearch}" \
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