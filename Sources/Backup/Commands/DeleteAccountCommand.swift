//
//  DeleteAccountCommand.swift
//  OsmAnd Maps
//
//  Created by Skalii on 15.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OADeleteAccountCommand)
@objcMembers
final class DeleteAccountCommand: Operation {
    
    private let email: String
    private let token: String
    
    init(with email: String, token: String) {
        self.email = email
        self.token = token
    }
    
    private func getListeners() -> [OAOnDeleteAccountListener] {
        OABackupHelper.sharedInstance().backupListeners.getDeleteAccountListeners()
    }
    
    private func getParams() -> [String: String] {
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        return ["deviceid": backupHelper.getDeviceId(),
                "accessToken": backupHelper.getAccessToken()]
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
        let operationLog: OAOperationLog = OAOperationLog(operationName: "accountDelete", debug: backupDebugLogs())
        operationLog.startOperation()
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        OANetworkUtilities.sendRequest(withUrl: OABackupHelper.account_DELETE_URL(),
                                       params: getParams(),
                                       body: getBody(),
                                       contentType: "application/json",
                                       post: true,
                                       async: false) { [weak self] data, response, _ in
            guard let self else { return }

            var status: Int32
            var message: String
            var backupError: OABackupError?
            guard let data, let httpResponse = response as? HTTPURLResponse else {
                return onProgressUpdate(STATUS_EMPTY_RESPONSE_ERROR,
                                        message: "Account deletion error: empty response",
                                        error: nil,
                                        operationLog: operationLog)
            }
            let result = String(data: data, encoding: .utf8) ?? ""
            if httpResponse.statusCode == 200 {
                    message = result
                    status = STATUS_SUCCESS
            } else {
                backupError = OABackupError(error: result)
                message = "Account deletion error: \(String(describing: backupError?.toString))\nEmail=\(self.email)\nDeviceId=\(String(describing: backupHelper.getDeviceId()))"
                status = STATUS_SERVER_ERROR
            }
            onProgressUpdate(status, message: message, error: backupError, operationLog: operationLog)
        }
    }

    private func onProgressUpdate(_ status: Int32, message: String, error: OABackupError?, operationLog: OAOperationLog) {
        for listener in getListeners() {
            listener.onDeleteAccount(Int(status), message: message, error: error)
        }
        operationLog.finishOperation("\(status) \(message)")
    }
}
