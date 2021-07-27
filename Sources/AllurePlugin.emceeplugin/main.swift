import Foundation
import EventBus
import Plugin
import Logging
import DateProvider
import FileSystem

let uuid = UUID()

func sendAllureReport(xcresultPath: String,
                      runId: String,
                      token: String,
                      host: String,
                      mobileToolsUrl: String,
                      xcresultParserPath: String,
                      xcresultParserBuildPath: String,
                      repoName: String,
                      durationServiceUrl: String) {
    let resultPath = FileManager.default.temporaryDirectory.path
    xcresultConvert(path: xcresultPath, resultPath: resultPath)
    shell("allurectl auth login -e '\(host)' -t '\(token)'")
    shell("cd \(resultPath) \n allurectl upload result_\(uuid) --launch-id \(runId)")
    sendResult(resultPath: resultPath,
               mobileToolsUrl: mobileToolsUrl,
               xcresultParserPath: xcresultParserPath,
               xcresultParserBuildPath: xcresultParserBuildPath,
               xcresultPath: xcresultPath,
               repoName: repoName,
               durationServiceUrl: durationServiceUrl)
    deleteResult(resultPath: resultPath)
}

func xcresultConvert(path: String, resultPath: String) {
    print("creating result_\(uuid).zip in \(resultPath)")
    shell("mkdir -p \(resultPath)/result_\(uuid)")
    shell("xcresults export \(path) \(resultPath)/result_\(uuid)")
}

func deleteResult(resultPath: String) {
    print("deleting result_\(uuid).zip")
    shell("cd \(resultPath) \n rm -rf result_\(uuid)")
}

func sendResult(resultPath: String,
                mobileToolsUrl: String,
                xcresultParserPath: String,
                xcresultParserBuildPath: String,
                xcresultPath: String,
                repoName: String,
                durationServiceUrl: String) {
    print("send result to duration service")
    shell("cd \(resultPath) \n mkdir \(uuid) \n cd \(uuid) \n rm -rf mobileautomation \n git clone \(mobileToolsUrl)")
    shell("cd \(resultPath)/\(uuid)/\(xcresultParserPath) \n pwd \n swift build")
    
    let json = shell("\(resultPath)/\(uuid)/\(xcresultParserPath)/\(xcresultParserBuildPath) resultinfo \(xcresultPath) \(repoName)")
    _ = RequestSender().sendTestDuration(url: URL(string: durationServiceUrl)!,
                                         data: json)
    print("result sended")
}

@discardableResult
func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.environment = ["PATH": "/usr/bin/:/bin:/usr/local/bin/"]
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let outputData = String(data: data, encoding: .utf8)!
    print(outputData)
    return outputData
}

private func createToken(_ authData: Dictionary<String, Any>?) -> String {
    let type = authData?["token_type"] as? String ?? ""
    let token = authData?["access_token"] as? String ?? ""
    return "\(type) \(token)"
}

class RequestSender: NSObject {
    
    fileprivate func sendTestDuration(url: URL,
                                      data: String) -> Dictionary<String, Any>? {
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append(data)
        request.httpBody = body
        print(request)
        return sendRequest(request: request)
    }
    
    private func sendRequest(request: URLRequest) -> Dictionary<String, Any>? {
        let dispatchGroup = DispatchGroup()
        let session = URLSession.shared
        var result: Dictionary<String, Any>?
        dispatchGroup.enter()
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    result = json as? Dictionary<String, Any> ?? nil
                } catch {
                    print(error)
                }
            }
            dispatchGroup.leave()
        }.resume()
        dispatchGroup.wait()
        return result
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


class Stream: DefaultBusListener {
    override func runnerEvent(_ event: RunnerEvent) {
        switch event {
        case .didRun( _ , let testContext):
            let path = testContext.environment["EMCEE_XCRESULT_PATH"] ?? ""
            let allureRunId = testContext.environment["allureRunId"] ?? ""
            let allureToken = testContext.environment["allureToken"] ?? ""
            let allureHost = testContext.environment["allureHost"] ?? ""
            let mobileToolsUrl = testContext.environment["mobileToolsUrl"] ?? ""
            let xcresultParserPath = testContext.environment["xcresultParserPath"] ?? ""
            let xcresultParserBuildPath = testContext.environment["xcresultParserBuildPath"] ?? ""
            let repoName = testContext.environment["repoName"] ?? ""
            let durationServiceUrl = testContext.environment["durationServiceUrl"] ?? ""
            sendAllureReport(xcresultPath: path,
                             runId: allureRunId,
                             token: allureToken,
                             host: allureHost,
                             mobileToolsUrl: mobileToolsUrl,
                             xcresultParserPath: xcresultParserPath,
                             xcresultParserBuildPath: xcresultParserBuildPath,
                             repoName: repoName,
                             durationServiceUrl: durationServiceUrl)
            break
        default:
            print("other action: \(event)")
        }
    }
}

let eventBus = EventBus()
eventBus.add(stream: Stream())
do {
    let plugin = try Plugin(eventBus: eventBus)
    let logger = plugin.logger
    logger.info("Started plugin")
    plugin.streamPluginEvents()
    plugin.join()
} catch {
    print("Can't initialize plugin")
}
