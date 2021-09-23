https://iju707.gitbooks.io/elasticsearch/content/indices-rollover-index.html

# [case 1: manual assign] ###################################################
curl -XPUT 'https://es.tzcorp.com/nginx?pretty' -d'
{
  "aliases": {
    "nginx-write": {}
  }
}'

# Add > 5 documents to nginx
curl -XPOST 'https://es.tzcorp.com/nginx-write/_rollover/nginx-000002?pretty' -d'
{
  "conditions": {
    "max_age":   "7d",
    "max_docs":  5
  }
}'

# [case 2: date assign] ###################################################
# PUT /<nginx-{now/d}-1> with URI encoding:
curl -XPUT 'https://es.tzcorp.com/%3Cnginx-%7Bnow%2Fd%7D-1%3E?pretty' -d'
{
  "aliases": {
    "nginx-write": {}
  }
}'
curl -XPOST 'https://es.tzcorp.com/nginx-write/_rollover?pretty' -d'
{
  "conditions": {
    "max_docs":   "1"
  }
}'

curl -XPUT -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/%3Cstats-%7Bnow%2Fd%7D-1%3E?pretty' -d'
{
  "aliases": {
    "stats-write": {}
  }
}'
curl -XPOST -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/stats-write/_rollover?pretty' -d'
{
  "conditions": {
    "max_docs":   "1"
  }
}'
