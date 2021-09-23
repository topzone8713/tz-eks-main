curl -XGET elk.tzcorp.com:9200/nginx/_mapping?pretty

curl -XPUT 'elk.tzcorp.com:9200/nginx/_mapping/nginx?pretty' -d'
{
  "properties": {
    "geoip.city_name": { 
      "type":     "text",
      "fielddata": true
    }
  }
}'

curl -XPOST 'elk.tzcorp.com:9200/nginx/_search?pretty' -d '
{
  "_source": false,
  "query": {
    "range": {
      "@timestamp": {
        "from": 1496620800000,
        "to": 1497139200000
      }
    }
  },
  "aggs": {
    "group_by_state": {
      "terms": {
        "field": "geoip.city_name"
      }
    }
  }
}
'

curl -XPOST 'elk.tzcorp.com:9200/stats/_search?pretty' -d '
{
  "_source": false,
  "query": {
    "range": {
      "@timestamp": {
        "from": 1496620800000,
        "to": 1497339200000
      }
    }
  },
  "aggs": {
    "group_by_action": {
      "terms": {
        "field": "action"
      }
    }
  }
}
'

# 특정 기간 중 나라별 호출수
curl -XPOST 'elk.tzcorp.com:9200/stats/_search?pretty' -d '
{
  "_source": false,
  "query": {
    "range": {
      "@timestamp": {
        "from": 1496620800000,
        "to": 1497339200000
      }
    }
  },
  "aggs": {
    "group_by_country_name": {
      "terms": {
        "field": "geoip.country_name"
      }
    }
  }
}
'

# 특정 기간 중 국가별 액션별 호출 수
curl -XPOST 'elk.tzcorp.com:9200/stats/_search?pretty' -d '
{
  "_source": false,
  "query": {
    "range": {
      "@timestamp": {
        "from": 1496620800000,
        "to": 1497339200000
      }
    }
  },
  "aggs": {
    "group_by_country_name": {
      "terms": {
        "field": "geoip.country_name"
      },
      "aggs": {
        "group_by_action": {
          "terms": {
            "field": "action"
          }         
        }
      }
    }
  }
}
'

# 특정 기간 중 action=/user/home 인 국가별 호출 수
curl -XPOST 'elk.tzcorp.com:9200/stats/_search?pretty' -d '
{
  "_source": false,
  "query": {
	"bool" : {
      "must" : {
	    "range": {
	      "@timestamp": {
	        "from": 1496620800000,
	        "to": 1497339200000
	       }
	    }
      },
      "filter": {
        "term" : { "action" : "/user/home" }
      }
    }	
  },
  "aggs": {
    "group_by_country_name": {
      "terms": {
        "field": "geoip.country_name"
      }
    }
  }
}
'

# 특정 기간 중 action=/user/home 인 국가별 / 5분별 호출 건수
curl -XPOST 'elk.tzcorp.com:9200/stats/_search?pretty' -d '
{
  "_source": false,
  "query": {
	"bool" : {
      "must" : {
	    "range": {
	      "@timestamp": {
	        "from": 1496620800000,
	        "to": 1497339200000
	       }
	    }
      },
      "filter": {
        "term" : { "action" : "/user/home" }
      }
    }	
  },
  "aggs": {
    "activity_timeline": {
        "date_histogram": {
            "field": "@timestamp",
            "interval": "5m",
            "min_doc_count": 1,
            "extended_bounds": {
                "min": 1496620800000,
                "max": 1497339200000
            },
        	"format": "yyyy-MM-dd HH:mm:ss"
        },
        "aggs": {
            "country_name": {
                "terms": {
                    "field": "geoip.country_name"
                }
            }
        }
    },
    "severity_count": {
      "terms": {
        "field": "geoip.country_name"
      }
    }    
  }
}
'

# ES-지역별 월별 가입자 수 통계
"interval": "5m" -> "interval": "month"
"term" : { "action" : "/user/home" } -> 

