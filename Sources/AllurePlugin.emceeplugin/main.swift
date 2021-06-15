import Foundation
import EventBus
import Plugin
import Logging
import DateProvider
import FileSystem

let uuid = UUID()

func sendAllureReport(xcresultPath: String, runId: String, token: String, host: String) {
    let resultPath = FileManager.default.temporaryDirectory.path
    xcresultConvert(path: xcresultPath, resultPath: resultPath)
    let _ = RequestSender().sendRequest(token: token,
                                        fileURL: URL(fileURLWithPath: resultPath + "/result_\(uuid).zip"),
                                        requestUrl: URL(string: "https://\(host)/api/rs/launch/\(runId)/upload")!)
    deleteResult(resultPath: resultPath)
}

func xcresultConvert(path: String, resultPath: String) {
    print("creating result_\(uuid).zip")
    shell("mkdir -p \(resultPath)/result_\(uuid)")
    shell("xcresults export \(path) \(resultPath)/result_\(uuid)")
    shell("cd \(resultPath) \n zip -r result_\(uuid).zip \(resultPath)/result_\(uuid)")
}

func deleteResult(resultPath: String) {
    print("deleting result_\(uuid).zip")
    shell("cd \(resultPath) \n rm -rf result_\(uuid) \n rm result_\(uuid).zip")
}

func shell(_ command: String){
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.environment = ["PATH": "/usr/bin/:/bin:/usr/local/bin/"]
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    print(String(data: data, encoding: .utf8)!)
}

private func createToken(_ authData: Dictionary<String, Any>?) -> String {
    let type = authData?["token_type"] as? String ?? ""
    let token = authData?["access_token"] as? String ?? ""
    return "\(type) \(token)"
}

class RequestSender: NSObject {
    fileprivate func sendRequest(token: String,
                                 fileURL: URL,
                                 requestUrl: URL) -> Dictionary<String, Any>? {
        var request = URLRequest(url: requestUrl,
                                 cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.addValue(token, forHTTPHeaderField: "authorization")
        request.prepareSendXcresultBody(fileURL: fileURL)
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
    
    mutating func prepareElement(name: String, filename: String, contentType: String, filePath: URL) {
        let lineBreak = "\r\n"
        
        self.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\(lineBreak)")
        self.append("Content-Type: application/\(contentType)\(lineBreak + lineBreak)")
        do {
            let info = try Data(contentsOf: filePath)
            self.append(info)
        } catch {}
        self.append(lineBreak)
    }
}

private extension URLRequest {
    mutating func prepareSendXcresultBody(fileURL: URL) {
        let boundary = "--------------------------062242191841608437752799"
        self.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        
        let lineBreak = "\r\n"
        body.append("--" + boundary + lineBreak)
        body.prepareElement(name: "archive", filename: "result_\(uuid).zip", contentType: "zip", filePath: fileURL)
        body.append("--\(boundary)--")
        body.append(lineBreak)
        self.httpBody = body
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
            sendAllureReport(xcresultPath: path, runId: allureRunId, token: allureToken, host: allureHost)
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
