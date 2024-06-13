//
//  OsmOAuthHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

// From documentation:
// "The access tokens currently do not expire automatically."

import SwiftUI
import AuthenticationServices

@objc(OAOsmOAuthHelper)
@objcMembers
class OsmOAuthHelper : BaseOAuthHelper {
    
    override class var authURL: String { return "https://www.openstreetmap.org/oauth2/authorize" }
    override class var accessTokenURL: String { return "https://www.openstreetmap.org/oauth2/token" }
    override class var clientID: String { return "G4ceIS13gWAoZVyOY52i35FnXWXlYN3pUduMLZpUb8U" }
    override class var clientSecret: String { return "giAWxmRnrhaMz6AqwAKuEYdfnhmwUbmb9aGrzlTBAmM" }
    override class var redirectURI: String { return "example.com/oauth" }
    override class var urlScheme: String { return "osmand-oauth" }
    override class var scopes: [String] { return ["write_gpx", "write_api", "write_notes", "read_prefs"] }
    
    override class var token: String? {
        get { return OAAppSettings.sharedManager().osmUserAccessToken.get(OAApplicationMode.default()) }
        set { OAAppSettings.sharedManager().osmUserAccessToken.set(newValue, mode: OAApplicationMode.default()) }
        
    }
    
    static let notificationKey = "OsmOAuthTokenKey"
    
    override class func parseTokenJSON(data: Data) -> (ParsedTokenResponce) {
        do {
            let parsedJSON = try JSONDecoder().decode(OsmAccessTokenModel.self, from: data)
            return (token: parsedJSON.access_token, expirationTimestamp: nil)
        } catch {
            print("parseTokenJSON() Error: \(error)  \n  data: \(String(decoding: data, as: UTF8.self))")
        }
        return (token: nil, expirationTimestamp: nil)
    }
    
    override class func onComplete() async {
        await fetchUserData()
        sendNotifications()
    }
    
    static func fetchUserData() async {
        do {
            if let header = getAutorizationHeader() {
                guard let url = URL(string: "https://api.openstreetmap.org/api/0.6/user/details.json") else { return }
                var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
                request.httpMethod = "GET"
                request.allHTTPHeaderFields = ["Authorization": header]
                let (data, _) = try await URLSession.shared.data(for: request)
                let parsedJSON = try JSONDecoder().decode(OsmUserDataModel.self, from: data)
                OAAppSettings.sharedManager().osmUserDisplayName.set(parsedJSON.user.display_name)
            }
        } catch {
            print("fetchUserData() Error: \(error)")
        }
    }
    
    static func getAutorizationHeader() -> String? {
        if (isOAuthAuthorised()) {
            return "Bearer " + token!
        } else if (isLegacyAuthorised()) {
            var content = getUserName() + ":" + getLegacyPassword()
            content = content.data(using: .utf8)!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            return "Basic " + content
        }
        return nil
    }
    
    static func isAuthorised() -> Bool {
        return isLegacyAuthorised() || isOAuthAuthorised()
    }
    
    static func isLegacyAuthorised() -> Bool {
        return OAAppSettings.sharedManager().osmUserName != nil &&
            OAAppSettings.sharedManager().osmUserPassword != nil &&
            OAAppSettings.sharedManager().osmUserName.get().length > 0 &&
            OAAppSettings.sharedManager().osmUserPassword.get().length > 0
    }
    
    static func isOAuthAuthorised() -> Bool {
        return token != nil && token!.length > 0
    }
    
    static func getUserName() -> String {
        return OAAppSettings.sharedManager().osmUserName.get()
    }

    static func getUserDisplayName() -> String {
        return OAAppSettings.sharedManager().osmUserDisplayName.get()
    }

    static func getLegacyPassword() -> String {
        return OAAppSettings.sharedManager().osmUserPassword.get()
    }
    
    static func logOut() {
        OAAppSettings.sharedManager().osmUserName.resetToDefault()
        OAAppSettings.sharedManager().osmUserPassword.resetToDefault()
        OAAppSettings.sharedManager().osmUserDisplayName.resetToDefault()
        OAAppSettings.sharedManager().osmUserDisplayName.resetToDefault()
        token = ""
        sendNotifications()
    }
    
    static func sendNotifications() {
        NotificationCenter.default.post(name: Notification.Name(notificationKey), object: nil)
    }

    static func showAuthIntroScreen(hostVC: UIViewController) {
        if #available(iOS 16.4, *) {
            hostVC.present(OsmOAuthSwiftUIViewWrapper.get(), animated: true)
        } else {
            let targetVC = OAOsmLoginMainViewController()
            if let delegateHostVC = hostVC as? OAAccountSettingDelegate {
                targetVC.delegate = delegateHostVC
            }
            hostVC.present(targetVC, animated: true)
        }
    }
}
