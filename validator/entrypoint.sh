#!/bin/bash
#
# 1. Fetches the public keys from the web3signer API
# 2. Checks if the public keys are valid
# 3. CUSTOM: create validator_definitions.yml
#   3.1 Removes and creates again the validator_definitions.yml file
#   3.2 Appends to the validator_definitions.yml file the public keys
# 4. Starts the validator

ERROR="[ ERROR ]"
INFO="[ INFO ]"

# Get public keys from API keymanager as an array of strings
# - Endpoint: http://web3signer.web3signer-prater.dappnode:9000/eth/v1/keystores
# - Returns:
# { "data": [{
#     "validating_pubkey": "0x93247f2209abcacf57b75a51dafae777f9dd38bc7053d1af526f220a7489a6d3a2753e5f3e8b1cfe39b56f43611df74a",
#     "derivation_path": "m/12381/3600/0/0/0",
#     "readonly": true
#     }]
# }
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

function clean_validator_definitions() {
    # Remove validator_definitions.yml file
    [ -f "${VALIDATORS_FILE}" ] && rm -rf "${VALIDATORS_FILE}"

    # Create validators file if not exist
    [ ! -d "/root/.lighthouse/validators" ] && mkdir -p /root/.lighthouse/validators
    [ ! -f "${VALIDATORS_FILE}" ] && touch "${VALIDATORS_FILE}"
}

# Creates the validator_definitions.yml which contains all the pubkeys
# - Docs: https://lighthouse-book.sigmaprime.io/validator-web3signer.html
# - FORMAT for each new pubkey:
# - enabled: true
#   voting_public_key: "0xa5566f9ec3c6e1fdf362634ebec9ef7aceb0e460e5079714808388e5d48f4ae1e12897fed1bea951c17fa389d511e477"
#   type: web3signer
#   url: "https://my-remote-signer.com:1234"
#   root_certificate_path: /home/paul/my-certificates/my-remote-signer.pem
function write_validator_definitions() {
    for PUBLIC_KEY in ${PUBLIC_KEYS_PARSED}; do
        [ -z "${PUBLIC_KEY}" ] && { echo "${ERROR} public key is empty"; exit 1; }
        echo "${INFO} adding public key: $PUBLIC_KEY"
        echo -en "- enabled: true\n  voting_public_key: \"${PUBLIC_KEY}\"\n  type: web3signer\n  url: \"${HTTP_WEB3SIGNER}\"\n" >> ${VALIDATORS_FILE}
    done
}

########
# MAIN #
########

# Get public keys from API keymanager
echo "${INFO} starting lighthouse"
get_public_keys

# Check public keys is not empty
[ -z "${PUBLIC_KEYS_PARSED}" ] && { echo "${ERROR} no public keys found in API keymanager endpoint /eth/v1/keystores"; exit 1; }

# Clean validator_definitions.yml file
echo "${INFO} cleaning previous validator_definitions.yml"
clean_validator_definitions

# Write validator_definitions.yml files
echo "${INFO} writing validator_definitions.yml"
write_validator_definitions

echo "${INFO} comparing keys in background"
./get_new_keys.sh "${HTTP_WEB3SIGNER}" "${PUBLIC_KEYS_PARSED[@]}" & disown

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
    --http-allow-origin 0.0.0.0 \
    --http-port 5062 \
    $EXTRA_OPTS