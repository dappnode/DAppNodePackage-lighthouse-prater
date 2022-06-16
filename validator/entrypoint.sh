#!/bin/bash

CLIENT="lighthouse"
NETWORK="prater"
VALIDATOR_PORT=3500
VALIDATORS_FILE="/root/.lighthouse/validators/validator_definitions.yml"
WEB3SIGNER_API="http://web3signer.web3signer-${NETWORK}.dappnode:9000"

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

    for PUBLIC_KEY in "${PUBLIC_KEYS_WEB3SIGNER[@]}"; do
        if [ -n "${PUBLIC_KEY}" ]; then
            echo "${INFO} adding public key: $PUBLIC_KEY"
            echo -en "- enabled: true\n  voting_public_key: \"${PUBLIC_KEY}\"\n  type: web3signer\n  url: \"${HTTP_WEB3SIGNER}\"\n" >>${VALIDATORS_FILE}
        else
            echo "${WARN} empty public key"
        fi
    done
}

WEB3SIGNER_RESPONSE=$(curl -s -w "%{http_code}" -X GET -H "Content-Type: application/json" -H "Host: validator.${CLIENT}-${NETWORK}.dappnode" "${WEB3SIGNER_API}/eth/v1/keystores")
HTTP_CODE=${WEB3SIGNER_RESPONSE: -3}
CONTENT=$(echo "${WEB3SIGNER_RESPONSE}" | head -c-4)

if [ "${HTTP_CODE}" == "403" ] && [ "${CONTENT}" == "*Host not authorized*" ]; then
    echo "${CLIENT} is not authorized to access the Web3Signer API. Start without pubkeys"
elif [ "$HTTP_CODE" != "200" ]; then
    echo "Failed to get keystores from web3signer, HTTP code: ${HTTP_CODE}, content: ${CONTENT}"
else
    PUBLIC_KEYS_WEB3SIGNER=($(echo "${CONTENT}" | jq -r 'try .data[].validating_pubkey'))
    if [ ${#PUBLIC_KEYS_WEB3SIGNER[@]} -gt 0 ]; then
        echo "found validators in web3signer, starting vc with pubkeys: ${PUBLIC_KEYS_WEB3SIGNER[*]}"
        write_validator_definitions
    fi
fi

exec -c lighthouse \
    --debug-level=${DEBUG_LEVEL} \
    --network=${NETWORK} \
    validator \
    --init-slashing-protection \
    --datadir /root/.lighthouse \
    --beacon-nodes $BEACON_NODE_ADDR \
    --graffiti="$GRAFFITI" \
    --http \
    --http-address 0.0.0.0 \
    --http-port ${VALIDATOR_PORT} \
    --http-allow-origin "*" \
    --unencrypted-http-transport \
    --metrics \
    --metrics-address 0.0.0.0 \
    --metrics-port 8008 \
    --metrics-allow-origin "*" \
    --suggested-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
    $EXTRA_OPTS
