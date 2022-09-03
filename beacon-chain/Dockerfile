ARG UPSTREAM_VERSION
FROM sigp/lighthouse:${UPSTREAM_VERSION}-modern

RUN apt-get update && apt-get install curl --yes
COPY entrypoint.sh entrypoint.sh
COPY jwtsecret.hex /jwtsecret

EXPOSE $BEACON_API_PORT

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]