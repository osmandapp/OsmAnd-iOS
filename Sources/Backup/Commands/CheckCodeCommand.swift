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
        do {
            return String(data: try JSONSerialization.data(withJSONObject: ["username": email,
                                                                            "password": "",
                                                                            "token": token],
                                                           options: .withoutEscapingSlashes),
                          encoding: .utf8)
        } catch {
            return nil
        }
    }

    override func main() {
        let operationLog: OAOperationLog = OAOperationLog(operationName: "checkCode", debug: backupDebugLogs())
        operationLog.startOperation()
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        OANetworkUtilities.sendRequest(withUrl: OABackupHelper.check_CODE_URL(),
                                       params: nil,
                                       body: getBody(),
                                       contentType: "application/json",
                                       post: true,
                                       async: false) { [weak self] data, response, _ in
            guard let self else { return }
            guard let data, let httpResponse = response as? HTTPURLResponse else {
                return onProgressUpdate(STATUS_EMPTY_RESPONSE_ERROR,
                                        message: "Check code error: empty response",
                                        error: nil,
                                        operationLog: operationLog)
            }
            let result = String(data: data, encoding: .utf8) ?? ""
            var status: Int32
            var message: String
            var backupError: OABackupError?
            if httpResponse.statusCode == 200 {
                    message = result
                    status = STATUS_SUCCESS
            } else {
                backupError = OABackupError(error: result)
                message = "Send code error: \(String(describing: backupError?.toString()))\nEmail=\(email)\nDeviceId=\(String(describing: backupHelper.getDeviceId()))"
                status = STATUS_SERVER_ERROR
            }
            onProgressUpdate(status, message: message, error: backupError, operationLog: operationLog)
        }
    }

    private func onProgressUpdate(_ status: Int32, message: String, error: OABackupError?, operationLog: OAOperationLog) {
        for listener in getListeners() {
            listener.onCheckCode(token, status: Int(status), message: message, error: error)
        }
        operationLog.finishOperation("\n\(status) \(message)")
    }
}
