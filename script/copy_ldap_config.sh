#!/bin/sh
docker run --rm --volumes-from lightmesh_data_1 -v $(pwd):/input busybox cp /input/$1 /opt/xn_apps/ldap.yml
