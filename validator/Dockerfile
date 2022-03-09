ARG UPSTREAM_VERSION

###########
# BUILDER #
###########
FROM golang:1.16.15-alpine3.15 as builder
WORKDIR /app 
RUN apk update && apk add git && git clone https://github.com/dappnode/eth2-pubkeys-autocheck.git
WORKDIR /app/eth2-pubkeys-autocheck/build
RUN go build -o auto-check-remote-keys main.go

##############
# LIGHTHOUSE #
##############
FROM sigp/lighthouse:${UPSTREAM_VERSION}

RUN apt-get update && apt-get install nginx curl jq --yes

COPY --from=builder /app/build/auto-check-remote-keys /usr/local/bin/auto-check-remote-keys
COPY entrypoint.sh /usr/local/bin

ENTRYPOINT [ "entrypoint.sh" ]