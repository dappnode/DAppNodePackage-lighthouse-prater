ARG UPSTREAM_VERSION
FROM sigp/lighthouse:${UPSTREAM_VERSION}

RUN apt-get update && apt-get install nginx curl jq --yes

# Copy scripts
COPY get_new_keys.sh /usr/local/bin/get_new_keys.sh
COPY entrypoint.sh /usr/local/bin

ENTRYPOINT [ "entrypoint.sh" ]