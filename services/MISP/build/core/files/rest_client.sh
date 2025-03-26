#!/bin/bash

if ! command -v jq &> /dev/null
then
    echo "aborting. jq could not be found"
    exit
fi

if ! command -v curl &> /dev/null
then
    echo "aborting. curl could not be found"
    exit
fi

add_organization() {
    # empty uuid fallbacks to auto-generate
    curl -s --show-error -k \
     -H "Authorization: ${2}" \
     -H "Accept: application/json" \
     -H "Content-type: application/json" \
     -d "{ \
        \"uuid\": \"${5}\", \
        \"name\": \"${3}\", \
        \"local\": ${4} \
     }" ${1}/admin/organisations/add
}

get_organization() {
    curl -s --show-error -k \
     -H "Authorization: ${2}" \
     -H "Accept: application/json" \
     -H "Content-type: application/json" ${1}/organisations/view/${3} | jq -e -r ".Organisation.id // empty"
}

add_server() {
    curl -s --show-error -k \
     -H "Authorization: ${2}" \
     -H "Accept: application/json" \
     -H "Content-type: application/json" \
     -d "${3}" ${1}/servers/add
}

get_server() {
    curl -s --show-error -k \
     -H "Authorization: ${2}" \
     -H "Accept: application/json" \
     -H "Content-type: application/json" ${1}/servers | jq -e -r ".[] | select(.Server[\"name\"] == \"${3}\") | .Server.id"
}
