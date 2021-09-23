#!/usr/bin/env bash

#1. Need to make template
#2. Run migration.sh
#3. Migrate kibana settings

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_domain=$(prop 'project' 'domain')
eks_project=$(prop 'project' 'project')

new_instance="https://es.${eks_domain}"

es_indexes=$(curl -s "http://172.31.22.192:9200/_cat/indices" | awk '{ print $3 }')
#es_indexes=$(curl -s "http://172.31.22.192:9200/_cat/indices" | awk '{ print $3 }' | grep -e 2018.09)
#es_indexes=$(curl -s "http://172.31.22.192:9200/_cat/indices" | awk '{ print $3 }' | grep -e nginx -e stats -e useraction -e erroraction)

for index in $es_indexes; do
	echo "==================${index}"

a_query='
{
  "source": {
    "remote": {
      "host": "http://172.31.22.192:9200",
      "username": "elastic",
      "password": "tzcorp!323",
      "socket_timeout": "1m",
      "connect_timeout": "10s"
    },
    "index": "NEW_INDEX"
  },
  "dest": {
    "index": "NEW_INDEX"
  }
}
'
a_query=`echo "${a_query}" | sed "s/\n/ /g" | sed "s/NEW_INDEX/${index}/g"`

curl -XPOST -H 'Content-Type: application/json' -u 'elastic:tzcorp!323' ${new_instance}'/_reindex?pretty' -d "${a_query}"
  
done




