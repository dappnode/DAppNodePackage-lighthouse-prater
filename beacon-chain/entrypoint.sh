#!/bin/bash

# Concatenate EXTRA_OPTS string
[[ -n "$CHECKPOINT_SYNC_URL" ]] && EXTRA_OPTS="${EXTRA_OPTS} --checkpoint-sync-url=${CHECKPOINT_SYNC_URL}"

exec lighthouse \
    --debug-level $DEBUG_LEVEL \
    --network prater \
    beacon_node \
    --datadir /root/.lighthouse \
    --eth1 --eth1-endpoints $HTTP_WEB3PROVIDER \
    --http \
    --http-allow-origin "*" \
    --http-address 0.0.0.0 \
    --http-port $BEACON_API_PORT \
    --port 9000 \
    --metrics \
    --metrics-address 0.0.0.0 \
    --metrics-port 8008 \
    --metrics-allow-origin "*" \
    $EXTRA_OPTS
