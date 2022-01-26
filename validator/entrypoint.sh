#!/bin/bash

# This script does the following:
# 1. Fetches the public keys from the web3signer API
# 2. Checks if the public keys are valid
# 3. Removes and creates again the validator_definitions.yml file
# 4. Appends to the validator_definitions.yml file the public keys
# 5. Starts the validator

PUBLIC_KEYS=""
VALIDATORS_FILE="/root/.lighthouse/validators/validator_definitions.yml"

# Get public keys from API keymanager:
# - Endpoint: http://web3signer.web3signer-prater.dappnode:9000/api/v1/eth2/publicKeys
# - Returns: string[]
function get_public_keys() {
    PUBLIC_KEYS=$(curl -X GET \
        -H "Content-Type: application/json" \
        --max-time 10 \
        --retry 5 \
        --retry-delay 0 \
        --retry-max-time 40 \
        "${HTTP_WEB3PROVIDER}/api/v1/eth2/publicKeys") \
    echo "Found public keys: $PUBLIC_KEYS"
}

# Creates the validator_definitions.yml file for each public key
# - Parameter: string[] publicKeys
# - Docs: https://lighthouse-book.sigmaprime.io/validator-web3signer.html
# - FORMAT for each new pubkey:
# - enabled: true
#   voting_public_key: "0xa5566f9ec3c6e1fdf362634ebec9ef7aceb0e460e5079714808388e5d48f4ae1e12897fed1bea951c17fa389d511e477"
#   type: web3signer
#   url: "https://my-remote-signer.com:1234"
#   root_certificate_path: /home/paul/my-certificates/my-remote-signer.pem
function write_validator_definitions() {
    for PUBLIC_KEY in ${PUBLIC_KEYS}; do
        echo "Adding public key: $PUBLIC_KEY"
        echo "- enabled: true\n  voting_public_key: \"${PUBLIC_KEY}\"\n  type: web3signer\n  url: \"${HTTP_WEB3PROVIDER}\"" >> ${VALIDATORS_FILE}
    done
}

########
# MAIN #
########

# Get public keys from API keymanager
get_public_keys

# Check public keys is not empty
[ -z "${PUBLIC_KEYS}" ] && { echo "No public keys found in API keymanager endpoint /api/v1/eth2/publicKeys"; exit 1; }

# Remove validator_definitions.yml file
[ -f "${VALIDATORS_FILE}" ] && rm -rf "${VALIDATORS_FILE}"

# Create validators file if not exist
[ ! -d "/root/.lighthouse/validators" ] && mkdir -p /root/.lighthouse/validators
[ ! -f "${VALIDATORS_FILE}" ] && touch "${VALIDATORS_FILE}"

# Write validator_definitions.yml files
write_validator_definitions

exec lighthouse \
    --debug-level $DEBUG_LEVEL \
    --network prater \
    validator \
    --init-slashing-protection \
    --datadir /root/.lighthouse \
    --beacon-nodes $BEACON_NODE_ADDR \
    # Must used escaped \"$VAR\" to accept spaces: --graffiti=\"$GRAFFITI\"
    --graffiti=\"$GRAFFITI\" \
    --http \
    --http-allow-origin 0.0.0.0 \
    --http-port 5062 \
    $EXTRA_OPTS