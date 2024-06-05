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

current_end_time_seconds=$((1000 * $(date +%s)))

echo ""
echo "||#####################||"
echo EndTime: "$(date -d@"$((current_end_time_seconds / 1000))")" to be set on the annotation: "${annotation_id}"
echo "------"

# create an annotation request body
json_string="$(
    jq -n --arg timeEnd "$current_end_time_seconds" \
        '{
            "timeEnd": ( $timeEnd | tonumber),
        }'
)"

patch_result=$(curl -X PATCH "${grafana_server}/api/annotations/${annotation_id}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${json_string}")

echo ""
echo "||#####################||"
echo "Annotation updated: ${annotation_id}"
