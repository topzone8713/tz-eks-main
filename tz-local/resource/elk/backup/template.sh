#!/usr/bin/env bash

set -x

#export INDEX=$1

if [ "_INDEX" == "" ]; then
	echo "sudo bash backup.sh {index_name}!"
	exit -1
fi

export DATE=`date +%Y%m%d`

echo "=[snapshot]====================================================="

curl -XDELETE "https://es.tzcorp.com/_snapshot/_INDEX/_INDEX_${DATE}"

curl -XPUT "https://es.tzcorp.com/_snapshot/_INDEX/_INDEX_${DATE}" -d'
{
  "type": "fs",
  "settings": {
    "compress": true,
    "location": "/var/lib/es1/nodes"
  }
}'

curl -XGET "https://es.tzcorp.com/_snapshot/_INDEX/_INDEX_${DATE}"

#curl -XGET "https://es.tzcorp.com/_cat/indices"

echo "=[backup]====================================================="
curl -XPUT "https://es.tzcorp.com/_snapshot/_INDEX/_INDEX_${DATE}?wait_for_completion=true&pretty" -d'
{
   "indices": "_INDEX*",  
   "ignore_unavailable": true,
   "include_global_state": true
}'

echo "successfully done!"

exit 0

