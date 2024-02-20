//
//  CheckCodeCommand.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(OACheckCodeCommand)
@objcMembers
final class CheckCodeCommand: Operation {

    private let email: String
    private let token: String

    init(with email: String, token: String) {
        self.email = email
        self.token = token
    }

    private func getListeners() -> [OAOnCheckCodeListener] {
        OABackupHelper.sharedInstance().backupListeners.getCheckCodeListeners()
    }

    private func getBody() -> String? {
        var body: String?
        do {
            body = String(data: try JSONSerialization.data(withJSONObject: ["username": email, "password": "", "token": token],
                                                           options: .withoutEscapingSlashes),
                          encoding: .utf8)
        } catch {
            body = nil
        }
        return body
    }

    override func main() {
        let operationLog: OAOperationLog = OAOperationLog(operationName: "checkCode", debug: backupDebugLogs())
        operationLog.startOperation()
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        OANetworkUtilities.sendRequest(withUrl: OABackupHelper.check_CODE_URL() ?? "",
                                       params: nil,
                                       body: getBody(),
                                       contentType: "application/json",
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
            } else {
                message = "Check code error: empty response"
                status = STATUS_EMPTY_RESPONSE_ERROR
            }
            self.onProgressUpdate(status: status, message: message, error: backupError)
            operationLog.finishOperation("\n\(status) \(message)")
        }
    }

    private func onProgressUpdate(status: Int32, message: String, error: OABackupError?) {
        for listener in self.getListeners() {
            listener.onCheckCode(token, status: Int(status), message: message, error: error)
        }
    }
}
