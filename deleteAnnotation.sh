#!/bin/bash

set -e

grafana_server=""

BUILD_NUMBER="1"
application_name="application_name"

token=""
buildtagsearch="build:${BUILD_NUMBER}"
servicetagsearch="service:${application_name}"

echo ""
echo "||#####################||"
echo "Searching for annotations with tags: ${buildtagsearch} and ${servicetagsearch}"
echo "------"

get_result=$(curl -X GET "${grafana_server}/api/annotations?tags=${buildtagsearch}&tags=${servicetagsearch}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}")

if [ -z "${get_result}" ]; then
    echo ""
    echo "||!!!!!!!!!!!!!!!!!!!!!||"
    echo "No annotations found"
    echo "------"
    exit 1
fi

annotation_id="$(jq -r '.[] | .id' <<<"${get_result}")"

if [ "$(wc -w <<< "${annotation_id}")" -gt 1 ]; then
    echo ""
    echo "||!!!!!!!!!!!!!!!!!!!!!||"
    echo "Multiple annotations found"
    echo "------"
    exit 1
fi

delete_result=$(curl -X DELETE "${grafana_server}/api/annotations/${annotation_id}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}")

echo ""
echo "||#####################||"
echo "Annotation deleted: ${annotation_id}"
