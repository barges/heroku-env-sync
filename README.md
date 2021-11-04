# heroku-env-sync

Usage:
```
❯ ./heroku_vars_sync.rb --help
Usage: heroku_vars_sync.rb [options]
    -s, --source SOURCE_APP          Source heroku application name
    -t, --target TARGET_APP          Target heroku application name
    -o, --override KEY=VALUE         Override key, pass multiple -o KEY=VALUE to override multiple keys
    -h, --help                       Prints this help
These keys will be skipped automatically:
  - HEROKU_*
```
Example:

```
❯ ./heroku_vars_sync.rb -s source-heroku-app -t target-heroku-app -o PRIMARY_DOMAIN=target-heroku-app.com -o "REACT_SITE_URL='https://target-heroku-app.com'" -o HTTP_USER=user -o HTTP_PASSWORD=sickrat
