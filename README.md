# AllurePlugin.emceeplugin

Plugin for [Emcee](https://github.com/avito-tech/Emcee/wiki). This is an additional module of the framework that runs on a worker. 
Plugin converts .xcresult to allure format (using [xcresults](https://github.com/eroshenkoam/xcresults)) and sends it to allure server.
Plugin setup documentation is [here](https://github.com/avito-tech/Emcee/wiki/Plugins).

# Environment in test-arg-file.json

```json
"environment": {
	"XCRESULT_PATH": "path to .xcresult",
     	"allureRunId": "allure run id to download results of test run",
     	"allureToken": "token for auth in allure",
     	"allureHost": "host of your allure server"
}
```
