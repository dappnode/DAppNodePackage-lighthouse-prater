#! /bin/bash

set -e

sed -i 's/DEFAULT_VALIDATOR_PUBLIC_KEY/'"${DEFAULT_VALIDATOR_PUBLIC_KEY}"'/' /root/.lighthouse/validators/validator_definitions.yml

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