exit 0

GET nginx*/_search
{
    "query": {
        "regexp": {
            "request": "**session**"
        }
    }
}

POST nginx*/_delete_by_query
{
    "query": {
        "regexp": {
            "request": "**session**"
        }
    }
}


GET nginx*/_search
{
  "query": {
    "match": {
      "request": {
        "query": "GET /transfers?size=30 HTTP/1.1",
        "type": "phrase"
      }
    }
  }
}

GET nginx*/_search
{
    "query": {
        "regexp": {
          "agent": {
            "value": "uptimerobot",
            "flags": "COMPLEMENT|INTERVAL"
          }
        }
    }
}

POST nginx*/_delete_by_query
{
    "query": {
        "regexp": {
          "agent": {
            "value": "uptimerobot",
            "flags": "COMPLEMENT|INTERVAL"
          }
        }
    }
}

POST nginx*/_delete_by_query
{
  "query": {
    "match": {
      "agent": {
        "query": "Jorgee",
        "type": "phrase"
      }
    }
  }
}

POST nginx*/_delete_by_query
{
    "query": {
        "regexp": {
            "request": ".*.txt"
        }
    }
}

GET nginx*/_search
{
    "query": {
        "regexp": {
            "request": ".*.php"
        }
    }
}

POST nginx*/_delete_by_query
{
    "query": {
        "regexp": {
            "request": ".*.php"
        }
    }
}

GET nginx*/_search
{
    "query": {
        "regexp": {
            "request": ".*.php"
        }
    }
}


GET nginx*/_search
{
  "query": {
      "query_string": {
          "query": "*phpmyadmin*",
          "fields": ["request"]
      }
  }
}

POST nginx*/_delete_by_query
{
  "query": {
      "query_string": {
          "query": "*phpmyadmin*",
          "fields": ["request"]
      }
  }
}

GET nginx*/_search
{
  "query": {
      "query_string": {
          "query": "*NetcraftSurveyAgent*",
          "fields": ["agent"]
      }
  }
}


