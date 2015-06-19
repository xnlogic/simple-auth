#!/bin/sh
set -e

if [ -z "$1" ]; then
  command="server"
else
  command="$1"
fi

if [ "$command" = 'server' ]; then
  exec puma -b tcp://0.0.0.0:80 -e production
elif [ "$command" = 'console' ]; then
  exec rails console
fi

exec "$@"
