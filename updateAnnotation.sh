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
dashboard_uid="$(jq -r '.[] | .dashboardUID' <<<"${get_result}")"
panel_id="$(jq -r '.[] | .panelId' <<<"${get_result}")"
current_time_seconds="$(jq -r '.[] | .time' <<<"${get_result}")"
current_end_time_seconds="$(jq -r '.[] | .timeEnd' <<<"${get_result}")"
tags_string="$(jq -r '.[] | .tags' <<<"${get_result}")"
text="$(jq -r '.[] | .text' <<<"${get_result}")"

if [ "$(wc -w <<< "${annotation_id}")" -gt 1 ]; then
    echo ""
    echo "||!!!!!!!!!!!!!!!!!!!!!||"
    echo "Multiple annotations found"
    echo "------"
    exit 1
fi

echo ""
echo "||#####################||"
echo EndTime: "$(date -d@"$((current_end_time_seconds / 1000))")" to be set on the annotation: "${annotation_id}"
echo "------"

json_string="$(
    jq -n --arg dashboardUID "$dashboard_uid" \
        --arg panelId "$panel_id" \
        --arg time "$current_time_seconds" \
        --arg timeEnd "$current_time_seconds" \
        --argjson tags "[$tags_string]" \
        --arg text "$text" \
        '{
            "dashboardUID": $dashboardUID,
            "panelId": $panelId,
            "time": ($time | tonumber),
            "timeEnd": ( $timeEnd | tonumber),
            "tags": $tags,
            "text": $text
        }'
)"

curl -X PUT "${grafana_server}/api/annotations/${annotation_id}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${json_string}"

echo ""
echo "||#####################||"
echo "Annotation updated: ${annotation_id}"