#!/bin/bash

NETWORK="prater"
VALIDATOR_PORT=3500

# MEVBOOST: https://lighthouse-book.sigmaprime.io/builders.html
if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_PRATER" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_PRATER" == "true" ]; then
    echo "MEVBOOST is enabled"
    MEVBOOST_URL="http://mev-boost.mev-boost-goerli.dappnode:18550"
    if curl --retry 5 --retry-delay 5 --retry-all-errors "${MEVBOOST_URL}"; then
        EXTRA_OPTS="--builder-proposals ${EXTRA_OPTS}"
    else
        echo "MEVBOOST is enabled but ${MEVBOOST_URL} is not reachable"
        curl -X POST -G 'http://my.dappnode/notification-send' --data-urlencode 'type=danger' --data-urlencode title="${MEVBOOST_URL} is not available" --data-urlencode 'body=Make sure the mevboost is available and running'
    fi
fi

#Handle Graffiti Character Limit
oLang=$LANG oLcAll=$LC_ALL
LANG=C LC_ALL=C 
graffitiString=${GRAFFITI:0:32}
LANG=$oLang LC_ALL=$oLcAll

exec -c lighthouse \
    --debug-level=${DEBUG_LEVEL} \
    --network=${NETWORK} \
    validator \
    --enable-doppelganger-protection \
    --init-slashing-protection \
    --datadir /root/.lighthouse \
    --beacon-nodes $BEACON_NODE_ADDR \
    --graffiti="${graffitiString}" \
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
