ARG UPSTREAM_VERSION
FROM sigp/lighthouse:${UPSTREAM_VERSION}-modern

# Copy token
COPY security/api-token.txt /root/.lighthouse/validators/
COPY security/.secp-sk /root/.lighthouse/validators/

COPY entrypoint.sh /usr/local/bin

RUN apt-get update && apt-get install curl jq --yes && \
    chmod +x /entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]