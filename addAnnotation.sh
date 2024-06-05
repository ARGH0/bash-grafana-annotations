#!/bin/bash

set -e

grafana_server=""

environment="test"
BUILD_NUMBER="1"
application_name="application_name"

token=""
tags=("kind:deployment" "env:${environment}" "service:${application_name}" "build:${BUILD_NUMBER}")

current_time_seconds=$((1000 * $(date +%s)))
#echo $(date -d@"$(($current_time_seconds / 1000))")

# Convert the tags array into a string with specific formatting
tags_string=$(printf '"%s",' "${tags[@]}" | sed 's/,$//')

# create an annotation request body
json_string="$(
    jq -n --arg time "$current_time_seconds" \
        --arg timeEnd "$current_time_seconds" \
        --argjson tags "[$tags_string]" \
        --arg text "Running period of deployment for: ${application_name}" \
        '{
            "time": ($time | tonumber),
            "timeEnd": ( $timeEnd | tonumber),
            "tags": $tags,
            "text": $text
        }'
)"

#echo "${grafana_server}/api/annotations"
#echo "${json_string}"

echo ""
echo "||#####################||"
echo "Creating an annotation with: "
echo "tags: ${tags_string}"  
echo "time: $(date -d@"$((current_time_seconds / 1000))")"
echo "------"
# Send an annotation to Grafana
post_result=$(curl -X POST "${grafana_server}/api/annotations" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${json_string}")
echo "${post_result}"

annotation_id="$(jq -r '.id' <<<"${post_result}")"

echo ""
echo "||#####################||"
echo "Annotation created: ${annotation_id}"