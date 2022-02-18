ARG UPSTREAM_VERSION

FROM rust:1.58 as cronjob

WORKDIR /usr/src/app
COPY ./cronjob ./
RUN cargo build --release

FROM sigp/lighthouse:${UPSTREAM_VERSION}

RUN apt-get update && apt-get install nginx curl jq cron --yes

# Setup cronjob
COPY get-keys-cron /etc/cron.d/
COPY --from=cronjob /usr/src/app/target/release /usr/src/app/
# Apply cron job
RUN crontab /etc/cron.d/get-keys-cron

COPY entrypoint.sh /usr/local/bin

ENTRYPOINT [ "entrypoint.sh" ]