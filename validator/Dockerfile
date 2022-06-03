ARG UPSTREAM_VERSION
FROM sigp/lighthouse:$UPSTREAM_VERSION

RUN apt-get update && apt-get install curl jq --yes
# Copy token
COPY security/api-token.txt /root/.lighthouse/validators/
COPY security/.secp-sk /root/.lighthouse/validators/

COPY entrypoint.sh /usr/local/bin

ENTRYPOINT [ "entrypoint.sh" ]