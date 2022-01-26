#! /bin/bash

PUBLIC_KEYS=""

# Get public keys from API keymanager:
# - Endpoint: http://web3signer.web3signer-prater.dappnode:9000/api/v1/eth2/publicKeys
# - Returns: string[]
function get_public_keys() {
    PUBLIC_KEYS=$(curl -X GET \
        -H "Content-Type: application/json" \
        --max-time 10 \
        --retry 5 \
        --retry-delay 0 \
        --retry-max-time 40
        "${HTTP_WEB3PROVIDER}/api/v1/eth2/publicKeys") \
        || { echo "Failed to get public keys from API keymanager endpoint /api/v1/eth2/publicKeys"; exit 1}
}

# Creates the validator_definitions.yml file for each public key
# - Parameter: string[] publicKeys
# - Docs: https://lighthouse-book.sigmaprime.io/validator-web3signer.html
# - FORMAT:
# - enabled: true
#   voting_public_key: "0xa5566f9ec3c6e1fdf362634ebec9ef7aceb0e460e5079714808388e5d48f4ae1e12897fed1bea951c17fa389d511e477"
#   type: web3signer
#   url: "https://my-remote-signer.com:1234"
#   root_certificate_path: /home/paul/my-certificates/my-remote-signer.pem
function write_validator_definitions() {
    for PUBLIC_KEY in ${PUBLIC_KEYS}; do
        echo "enabled: true" >> /root/.lighthouse/validators/validator_definitions_${PUBLIC_KEY}.yml
        echo "voting_public_key: \"${PUBLIC_KEY}\"" >> /root/.lighthouse/validators/validator_definitions_${PUBLIC_KEY}.yml
        echo "type: web3signer" >> /root/.lighthouse/validators/validator_definitions_${PUBLIC_KEY}.yml
        echo "url: \"${HTTP_WEB3PROVIDER}\"" >> /root/.lighthouse/validators/validator_definitions_${PUBLIC_KEY}.yml
        # echo "root_certificate_path: /root/.lighthouse/validators/root_certificates/root_certificate.pem" >> /root/.lighthouse/validators/validator_definitions_${PUBLIC_KEY}.yml
    done
}

########
# MAIN #
########

# Get public keys from API keymanager
get_public_keys

# Check public keys is not empty
if [ -z "${PUBLIC_KEYS}" ]; then
    echo "No public keys found in API keymanager endpoint /api/v1/eth2/publicKeys"
    exit 1
fi

# Remove validator_definitions.yml files
rm -f /root/.lighthouse/validators/*

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