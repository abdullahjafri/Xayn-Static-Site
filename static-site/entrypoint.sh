#!/bin/sh
envsubst '$STAGE $SECRET' < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html
exec "$@"
