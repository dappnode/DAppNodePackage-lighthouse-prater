#!/bin/bash
#
# This script must fetch and compare the public keys returned from the web3signer api
# with the public keys in the public_keys.txt file used to start the validator
# if the public keys are different, the script will kill the process 1 to restart the process
# if the public keys are the same, the script will do nothing

#############
# ARGUMENTS #
#############
# $1 First argument: web3signer endpoint
# $2 Second argument: string array of public keys

#############
# VARIABLES #
#############

HTTP_WEB3SIGNER=$1
PUBLIC_KEYS_OLD=("$@")

ERROR="[ ERROR-cronjob ]"
WARN="[ WARN-cronjob ]"
INFO="[ INFO-cronjob ]"

#############
# FUNCTIONS #
#############

# Get public keys in format: string[]
function get_public_keys() {
    if PUBLIC_KEYS=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    --max-time 10 \
    --retry 5 \
    --retry-delay 2 \
    --retry-max-time 40 \
    "${HTTP_WEB3SIGNER}/eth/v1/keystores"); then
        if PUBLIC_KEYS_PARSED=$(echo ${PUBLIC_KEYS} | jq -r '.data[].validating_pubkey'); then
            if [ ! -z "$PUBLIC_KEYS_PARSED" ]; then
                echo "${INFO} found public keys: $PUBLIC_KEYS_PARSED"
            else
                echo "${WARN} no public keys found"
            fi
        else
            { echo "${ERROR} something wrong happened parsing the public keys"; exit 1; }
        fi
    else
        { echo "${ERROR} web3signer not available"; exit 1; }
    fi
}

# Compare two string arrays and check if they are the same
function compare_public_keys() {
    if [ "${#PUBLIC_KEYS_OLD[@]}" -ne "${#PUBLIC_KEYS_PARSED[@]}" ]; then
        echo "${INFO} public keys are different"
        echo "${INFO} old public keys: ${PUBLIC_KEYS_OLD[@]}"
        echo "${INFO} new public keys: ${PUBLIC_KEYS_PARSED[@]}"
        kill 1
    else
        echo "${INFO} public keys are the same"
        echo "${INFO} old public keys: ${PUBLIC_KEYS_OLD[@]}"
        echo "${INFO} new public keys: ${PUBLIC_KEYS_PARSED[@]}"
    fi

}

########
# MAIN #
########

while true; do
    echo "${INFO} starting cronjob"
    get_public_keys
    read_public_keys
    compare_public_keys
    echo "${INFO} finished cronjob"
    sleep 1m
done