#!/usr/bin/env bash

curl --location 'https://api.slashid.com/oauth2/tokens' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Authorization: Basic <CLIENT ID and CLIENT SECRET>' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'scope=customers:read' # modify scope as appropriate