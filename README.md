# AllurePlugin.emceeplugin

Plugin for [Emcee](https://github.com/avito-tech/Emcee/wiki). This is an additional module of the framework that runs on a worker. 
Plugin converts .xcresult to allure format (using [xcresults](https://github.com/eroshenkoam/xcresults)) and sends it to allure server.
Plugin setup documentation is [here](https://github.com/avito-tech/Emcee/wiki/Plugins).

# Environment in test-arg-file.json

```json
"environment": {
    "allureRunId": "allure run id to download results of test run",
    "allureToken": "token for auth in allure",
    "allureHost": "host of your allure server",
    "mobileToolsUrl": "url of git repository with additional projects",
    "xcresultParserPath": "path to the parser that prepares json for sending to the service for calculating the duration of tests",
    "xcresultParserBuildPath": "path to the parser binary file",
    "repoName": "unique name of the project repository",
    "durationServiceUrl": "url of service for calculating the duration of tests"
}
```
