#!/bin/sh
if [[ "$1" == "" ]]; then
  echo usage: $0 DATA_CONTAINER_NAME
  echo
  echo To use without a data container, edit to change --volumes-from to -v with the appropriate path.
else
  docker run --rm --volumes-from $1 -v $(pwd):/input busybox cp /input/$1 /opt/xn_apps/ldap.yml
fi
