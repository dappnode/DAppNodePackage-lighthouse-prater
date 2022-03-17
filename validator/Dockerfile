ARG UPSTREAM_VERSION
FROM sigp/lighthouse:${UPSTREAM_VERSION}

RUN apt-get update && apt-get install curl jq cron supervisor --yes

# Setup cronjob
COPY get-keys-cron /etc/cron.d/
COPY get-keys.sh /usr/local/bin/get-keys.sh
# Apply cron job
RUN crontab /etc/cron.d/get-keys-cron

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY entrypoint.sh /usr/local/bin

ENTRYPOINT [ "entrypoint.sh" ]