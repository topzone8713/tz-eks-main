curl -XGET -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/_template/stats_t1*?pretty'

curl -XDELETE -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/_template/stats_t1?pretty'

# "template": "stats*", : stats로 시작되는 index가 생성될 때 자동 적용됨

curl -XPUT -H 'Content-Type: application/json' -u 'elastic:tzcorp!323' 'https://es.tzcorp.com/_template/stats_t1?pretty' -d'
{
  "index_patterns": ["stats-201*"],
  "settings": {
    "number_of_shards": 3
  },
  "aliases": {
    "stats_t1": {}
  },
  "mappings": {
	"stats": {
        "properties": {
          "@timestamp": {
            "type": "date"
          },
          "@version": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "action": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "country": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "date": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "geoip": {
            "properties": {
              "city_name": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "continent_code": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "coordinates": {
                "type": "geo_point"
              },
              "country_code2": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "country_code3": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "country_name": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "dma_code": {
                "type": "long"
              },
              "ip": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "latitude": {
                "type": "float"
              },
              "location": {
                "type": "float"
              },
              "longitude": {
                "type": "float"
              },
              "postal_code": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
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
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              },
              "timezone": {
                "type": "text",
                "fields": {
                  "keyword": {
                    "type": "keyword"
                  }
                }
              }
            }
          },
          "host": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "ip": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "path": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "type": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "username": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          }
	    }
	  }
  },
  "version": 100
}'


exit 0
