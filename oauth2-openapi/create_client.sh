#!/usr/bin/env bash

ORG_ID=$1
API_KEY=$2

curl -s -X POST --location 'https://api.slashid.com/oauth2/clients' \
--header "SlashID-OrgID: ${ORG_ID}" \
--header 'Content-Type: application/json' \
--header "SlashID-API-Key: ${API_KEY}" \
--data '{
    "scopes": ["customers:read", "customers:create", "customers:modify", "customers:delete"],
    "client_name": "example",
    "grant_types": ["client_credentials"]
}' | jq -r '.result | "client_id: \(.client_id)\nclient_secret: \(.client_secret)"'