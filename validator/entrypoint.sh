#!/bin/bash
#
# 1. Fetches the public keys from the web3signer API
# 2. Checks if the public keys are valid
# 3. CUSTOM: create validator_definitions.yml
#   3.1 Removes and creates again the validator_definitions.yml file
#   3.2 Appends to the validator_definitions.yml file the public keys
# 4. Starts the validator

ERROR="[ ERROR ]"
WARN="[ WARN ]"
INFO="[ INFO ]"

# Checks the following vars exist or exits:
# - VALIDATORS_FILE
# - PUBLIC_KEYS_FILE
# - HTTP_WEB3SIGNER
# - BEACON_NODE_ADDR
function ensure_envs_exist() {
    [ -z "$VALIDATORS_FILE" ] && echo "$ERROR: VALIDATORS_FILE is not set" && exit 1
    [ -z "$PUBLIC_KEYS_FILE" ] && echo "$ERROR: PUBLIC_KEYS_FILE is not set" && exit 1
    [ -z "$HTTP_WEB3SIGNER" ] && echo "$ERROR: HTTP_WEB3SIGNER is not set" && exit 1
    [ -z "$BEACON_NODE_ADDR" ] && echo "$ERROR: BEACON_NODE_ADDR is not set" && exit 1
}

# Get public keys from API keymanager: BASH ARRAY OF STRINGS
# - Endpoint: http://web3signer.web3signer-prater.dappnode:9000/eth/v1/keystores
# - Returns:
# { "data": [{
#     "validating_pubkey": "0x93247f2209abcacf57b75a51dafae777f9dd38bc7053d1af526f220a7489a6d3a2753e5f3e8b1cfe39b56f43611df74a",
#     "derivation_path": "m/12381/3600/0/0/0",
#     "readonly": true
#     }]
# }
function get_public_keys() {
    # Try for 3 minutes    
    if PUBLIC_KEYS_API=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    --retry 60 \
    --retry-delay 3 \
    --retry-connrefused \
    "${HTTP_WEB3SIGNER}/eth/v1/keystores"); then
        if PUBLIC_KEYS_API=$(echo ${PUBLIC_KEYS_API} | jq -r '.data[].validating_pubkey'); then
            if [ ! -z "$PUBLIC_KEYS_API" ]; then
                echo "${INFO} found public keys: $PUBLIC_KEYS_API"
            else
                echo "${WARN} no public keys found"
            fi
        else
            echo "${WARN} something wrong happened parsing the public keys"
        fi
    else
        echo "${WARN} web3signer not available"
    fi
}

function clean_public_keys() {
    rm -rf ${PUBLIC_KEYS_FILE}
    touch ${PUBLIC_KEYS_FILE}
}

# Writes public keys
# - by new line separated
# - creates file if it does not exist
function write_public_keys() {
    echo "${INFO} writing public keys to file"
    for PUBLIC_KEY in ${PUBLIC_KEYS_API}; do
        if [ ! -z "${PUBLIC_KEY}" ]; then
            echo "${INFO} adding public key: $PUBLIC_KEY"
            echo "${PUBLIC_KEY}" >> ${PUBLIC_KEYS_FILE}
        else
            echo "${WARN} empty public key"
        fi
    done
}

# Removes old and creates new validator_definitions.yml which contains all the pubkeys
# - Docs: https://lighthouse-book.sigmaprime.io/validator-web3signer.html
# - FORMAT for each new pubkey:
# - enabled: true
#   voting_public_key: "0xa5566f9ec3c6e1fdf362634ebec9ef7aceb0e460e5079714808388e5d48f4ae1e12897fed1bea951c17fa389d511e477"
#   type: web3signer
#   url: "https://my-remote-signer.com:1234"
#   root_certificate_path: /home/paul/my-certificates/my-remote-signer.pem
function write_validator_definitions() {
    # Remove validator_definitions.yml file
    [ -f "${VALIDATORS_FILE}" ] && rm -rf "${VALIDATORS_FILE}"

    # Create validators file if not exist
    [ ! -d "/root/.lighthouse/validators" ] && mkdir -p /root/.lighthouse/validators
    [ ! -f "${VALIDATORS_FILE}" ] && touch "${VALIDATORS_FILE}"

    for PUBLIC_KEY in ${PUBLIC_KEYS_API}; do
        if [ ! -z "${PUBLIC_KEY}" ]; then
            echo "${INFO} adding public key: $PUBLIC_KEY"
            echo -en "- enabled: true\n  voting_public_key: \"${PUBLIC_KEY}\"\n  type: web3signer\n  url: \"${HTTP_WEB3SIGNER}\"\n" >> ${VALIDATORS_FILE}
        else
            echo "${WARN} empty public key"
        fi
    done
}

########
# MAIN #
########

# Check if the envs exist
ensure_envs_exist

# Get public keys from API keymanager
get_public_keys

# Clean old public keys
clean_public_keys

if [ ! -z "${PUBLIC_KEYS_API}" ]; then
    # Write validator_definitions.yml files
    echo "${INFO} writing validator definitions file"
    write_validator_definitions

    # Write public keys to file
    echo "${INFO} writing public keys file"
    write_public_keys
fi

echo "${INFO} starting cronjob"
CLIENT_ADDRESS=http://validator.lighthouse-prater.dappnode CLIENT_PORT=9000 NETWORK=prater auto-check-remote-keys &

echo "${INFO} starting lighthouse"
exec lighthouse \
    --debug-level $DEBUG_LEVEL \
    --network prater \
    validator \
    --init-slashing-protection \
    --datadir /root/.lighthouse \
    --beacon-nodes $BEACON_NODE_ADDR \
    --graffiti=\"$GRAFFITI\" \
    --http \
    --http-address 0.0.0.0 \
    --http-port 5062 \
    --http-allow-origin "*" \
    --unencrypted-http-transport \
    $EXTRA_OPTS
