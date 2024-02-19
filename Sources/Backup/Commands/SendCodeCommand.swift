//
//  SendCodeCommand.swift
//  OsmAnd Maps
//
//  Created by Skalii on 16.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(OASendCodeCommand)
@objcMembers
final class SendCodeCommand: Operation {

    private let email: String
    private let action: String

    init(with email: String, action: String) {
        self.email = email
        self.action = action
    }

    private func getListeners() -> [OAOnSendCodeListener] {
        OABackupHelper.sharedInstance().backupListeners.getSendCodeListeners()
    }

    private func getParams() -> [String: String] {
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        return ["deviceid": backupHelper.getDeviceId(),
                "accessToken": backupHelper.getAccessToken()]
    }

    private func getBody() -> String? {
        var body: String?
        do {
            body = String(data: try JSONSerialization.data(withJSONObject: ["email": email,
                                                                            "action": action/*,
                                                                           "lang": OAUtilities.currentLang()*/],
                                                           options: .prettyPrinted),
                          encoding: .utf8)
        } catch {
            body = nil
        }
        return body
    }

    override func main() {
        let operationLog: OAOperationLog = OAOperationLog(operationName: "sendCode", debug: backupDebugLogs())
        operationLog.startOperation()
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        OANetworkUtilities.sendRequest(withUrl: OABackupHelper.send_CODE_URL() ?? "",
                                       params: getParams(),
                                       body: getBody(),
                                       post: true,
                                       async: false) { data, response, _ in
            var status: Int32
            var message: String
            var backupError: OABackupError?
            let result = data != nil ? String(data: data!, encoding: .utf8) ?? "" : ""
            if let urlResponse = response as? HTTPURLResponse {
                if urlResponse.statusCode == 200 {
                    message = result
                    status = STATUS_SUCCESS
                } else {
                    backupError = OABackupError(error: result)
                    message = "Send code error: \(String(describing: backupError?.toString()))\nEmail=\(self.email)\nDeviceId=\(String(describing: backupHelper.getDeviceId()))"
                    status = STATUS_SERVER_ERROR
                }
            } else if result.length > 0, let data {
                do {
                    if let resultJson = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        if let resultStatus = resultJson["status"] as? String, resultStatus == "ok" {
                            message = "Code have been sent successfully. Please check for email with activation code."
                            status = STATUS_SUCCESS
                        } else {
                            message = "Send code error: unknown"
                            status = STATUS_SERVER_ERROR
                        }
                    } else {
                        message = "Send code error: json parsing"
                        status = STATUS_PARSE_JSON_ERROR
                    }
                } catch {
                    message = "Send code error: json parsing"
                    status = STATUS_PARSE_JSON_ERROR
                }
            } else {
                message = "Send code error: empty response"
                status = STATUS_EMPTY_RESPONSE_ERROR
            }
            self.onProgressUpdate(status: status, message: message, error: backupError)
            operationLog.finishOperation("\n\(status) \(message)")
        }
    }

    private func onProgressUpdate(status: Int32, message: String, error: OABackupError?) {
        for listener in self.getListeners() {
            listener.onSendCode(Int(status), message: message, error: error)
        }
    }
}
