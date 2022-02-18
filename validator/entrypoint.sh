#!/bin/bash

########
# MAIN #
########


echo "${INFO} starting cronjob"
cron

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
    --http-address 0.0.0.0 \
    --http-port 5062 \
    $EXTRA_OPTS