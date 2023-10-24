#!/usr/bin/env bash

curl --location 'https://api.slashid.com/oauth2/clients' \
--header 'SlashID-OrgID: <ORGANIZATION ID>' \
--header 'Content-Type: application/json' \
--header 'SlashID-API-Key: <API KEY>' \
--data '{
    "scopes": ["customers:read", "customers:create", "customers:modify", "customers:delete"],
    "client_name": "example",
    "grant_types": ["client_credentials"]
}'