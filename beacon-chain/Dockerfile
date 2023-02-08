ARG UPSTREAM_VERSION
FROM sigp/lighthouse:${UPSTREAM_VERSION}-modern

COPY entrypoint.sh entrypoint.sh
COPY jwtsecret.hex /jwtsecret

RUN apt-get update && apt-get install curl --yes && \
    chmod +x /entrypoint.sh

EXPOSE $BEACON_API_PORT

ENTRYPOINT ["/entrypoint.sh"]