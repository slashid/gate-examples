#!/usr/bin/env bash

AUTH="$1:$2"
ENCODED_AUTH=$(echo -n ${AUTH} | base64)

curl -s --location 'https://api.slashid.com/oauth2/tokens' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header "Authorization: Basic ${ENCODED_AUTH}" \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'scope=customers:read customers:create' | jq -r '"access_token: \(.access_token)"'