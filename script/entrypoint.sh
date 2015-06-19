#!/bin/sh
set -e

if [ -z "$1" ]; then
  command="server"
else
  command="$1"
fi

if [ "$command" = 'server' ]; then
  rake db:migrate
  exec puma -b tcp://0.0.0.0:80 -e $RAILS_ENV
elif [ "$command" = 'console' ]; then
  exec rails console
fi

exec "$@"
