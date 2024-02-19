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
        var body :String?
        do {
            body = String(data: try JSONSerialization.data(withJSONObject: ["username": email,
                                                                            "password": "",
                                                                            "token": token],
                                                           options: .prettyPrinted),
                          encoding: .utf8)
        } catch {
            body = nil
        }
        return body
    }

    override func main() {
        let operationLog: OAOperationLog = OAOperationLog(operationName: "accountDelete", debug: backupDebugLogs())
        operationLog.startOperation()
        let backupHelper: OABackupHelper = OABackupHelper.sharedInstance()
        OANetworkUtilities.sendRequest(withUrl: OABackupHelper.account_DELETE_URL(),
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
                    message = "Account deletion error: \(String(describing: backupError?.toString))\nEmail=\(self.email)\nDeviceId=\(String(describing: backupHelper.getDeviceId()))"
                    status = STATUS_SERVER_ERROR
                }
            } else {
                message = "Account deletion error: empty response"
                status = STATUS_EMPTY_RESPONSE_ERROR
            }
            self.onProgressUpdate(status: status, message: message, error: backupError)
            operationLog.finishOperation("\(status) \(message)")
        }
    }

    private func onProgressUpdate(status: Int32, message: String, error: OABackupError?) {
        for listener in self.getListeners() {
            listener.onDeleteAccount(Int(status), message: message, error: error)
        }
    }
}
