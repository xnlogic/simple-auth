#!/bin/sh
set -e

if [ -z "$1" ]; then
  command="server"
else
  command="$1"
fi


update_deps() {
  echo Retrieving dependencies.
  ruby -S bundle install
}

if [ "$command" = 'server' ]; then
  rake db:migrate
  exec puma -b tcp://0.0.0.0:80 -e $RAILS_ENV
elif [ "$command" = 'console' ]; then
  exec rails console
elif [ "$command" = 'deps' ]; then
  update_deps
  exec echo Done.
fi

exec "$@"
