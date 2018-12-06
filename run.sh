#!/bin/sh
set -e

if [ ! -z "${REDIS_PASSWORD}" ]; then
  echo "  password: \"\${REDIS_PASSWORD}\"" >> /etc/filebeat/filebeat.yml
fi

/usr/local/bin/filebeat -e -c /etc/filebeat/filebeat.yml