curl -XGET -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/_template/nginx_t1*?pretty'

curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/_template/nginx_t1?pretty'

# "template": "nginx*", : nginx로 시작되는 index가 생성될 때 자동 적용됨

curl -XPUT -H 'Content-Type: application/json' -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/_template/nginx_t1?pretty' -d'
{
  "index_patterns": ["nginx-201*"],
  "settings": {
    "number_of_shards": 3
  },
  "aliases": {
    "nginx_t1": {}
  },
  "mappings" : {
    "nginx": {
        "properties": {
          "@timestamp": {
            "type": "date"
          },
          "@version": {
            "type": "text"
          },
          "access-time": {
            "type": "date"
          },
          "geoip": {
            "properties": {
              "area_code": {
                "type": "long"
              },
              "city_name": {
                "type": "text"
              },
              "continent_code": {
                "type": "text"
              },
              "coordinates": {
                "type": "geo_point"
              },
              "country_code2": {
                "type": "text"
              },
              "country_code3": {
                "type": "text"
              },
              "country_name": {
                "type": "text"
              },
              "dma_code": {
                "type": "long"
              },
              "ip": {
                "type": "text"
              },
              "latitude": {
                "type": "double"
              },
              "location": {
                "type": "geo_point"
              },
              "longitude": {
                "type": "double"
              },
              "postal_code": {
                "type": "text"
              },
              "real_region_name": {
                "type": "text"
              },
              "region_code": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "region_name": {
                "type": "text"
              },
              "timezone": {
                "type": "text"
              }
            }
          },
          "user_agent": {
            "properties": {
              "build": {
                "type": "text"
              },
              "device": {
                "type": "text"
              },
              "major": {
                "type": "text"
              },
              "minor": {
                "type": "text"
              },
              "name": {
                "type": "text"
              },
              "os": {
                "type": "text"
              },
              "os_major": {
                "type": "text"
              },
              "os_minor": {
                "type": "text"
              },
              "os_name": {
                "type": "text"
              },
              "patch": {
                "type": "text"
              }
            }
          }
        }
    }
  }
},
  "version": 100
}'

exit 0
