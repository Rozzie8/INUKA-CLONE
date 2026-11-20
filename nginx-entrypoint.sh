#!/bin/sh
set -eu
: "${BACKEND_HOSTPORT:=backend:8000}"
export BACKEND_HOSTPORT
envsubst '${BACKEND_HOSTPORT} ${PORT}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
rm /etc/nginx/conf.d/default.conf.template
exec /docker-entrypoint.sh "$@"
