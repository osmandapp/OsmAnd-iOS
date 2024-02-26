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
        do {
            return String(data: try JSONSerialization.data(withJSONObject: ["email": email,
                                                                            "action": action,
                                                                            "lang": OAUtilities.currentLang()],
                                                           options: .withoutEscapingSlashes),
                          encoding: .utf8)
        } catch {
            return nil
        }
    }

    override func main() {
        let operationLog: OAOperationLog = OAOperationLog(operationName: "sendCode", debug: backupDebugLogs())
        operationLog.startOperation()
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        OANetworkUtilities.sendRequest(withUrl: OABackupHelper.send_CODE_URL(),
                                       params: getParams(),
                                       body: getBody(),
                                       contentType: "application/json",
                                       post: true,
                                       async: false) { [weak self] data, response, _ in
            guard let self else { return }
            guard let data, let httpResponse = response as? HTTPURLResponse else {
                return onProgressUpdate(STATUS_EMPTY_RESPONSE_ERROR,
                                        message: "Send code error: empty response",
                                        error: nil,
                                        operationLog: operationLog)
            }
            let result = String(data: data, encoding: .utf8) ?? ""
            var status: Int32
            var message: String
            var backupError: OABackupError?
            if httpResponse.statusCode != 200 {
                backupError = OABackupError(error: result)
                message = "Send code error: \(String(describing: backupError?.toString()))\nEmail=\(email)\nDeviceId=\(String(describing: backupHelper.getDeviceId()))"
                status = STATUS_SERVER_ERROR
            } else if !result.isEmpty {
                do {
                    if let resultJson = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                       let resultStatus = resultJson["status"] as? String, resultStatus == "ok" {
                        message = "Code have been sent successfully. Please check for email with activation code."
                        status = STATUS_SUCCESS
                    } else {
                        message = "Send code error: unknown"
                        status = STATUS_SERVER_ERROR
                    }
                } catch {
                    message = "Send code error: json parsing"
                    status = STATUS_PARSE_JSON_ERROR
                }
            } else {
                message = "Send code error: empty response"
                status = STATUS_EMPTY_RESPONSE_ERROR
            }
            onProgressUpdate(status, message: message, error: backupError, operationLog: operationLog)
        }
    }

    private func onProgressUpdate(_ status: Int32, message: String, error: OABackupError?, operationLog: OAOperationLog) {
        for listener in getListeners() {
            listener.onSendCode(Int(status), message: message, error: error)
        }
        operationLog.finishOperation("\n\(status) \(message)")
    }
}
