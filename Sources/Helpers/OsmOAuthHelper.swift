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
import Foundation
import AuthenticationServices


@objc class OsmOAuthHelper : OAuthHelper {
    
    override class var authURL: String { return "https://www.openstreetmap.org/oauth2/authorize" }
    override class var accessTokenURL: String { return "https://www.openstreetmap.org/oauth2/token" }
    override class var clientID: String { return "G4ceIS13gWAoZVyOY52i35FnXWXlYN3pUduMLZpUb8U" }
    override class var clientSecret: String { return "giAWxmRnrhaMz6AqwAKuEYdfnhmwUbmb9aGrzlTBAmM" }
    override class var redirectURI: String { return "example.com/oauth" }
    override class var urlScheme: String { return "osmand-oauth" }
    override class var scopes: [String] { return ["read_gpx", "write_gpx", "write_api", "write_notes", "read_prefs"] }
    
    override class var tokenSettingsKey: String { return "OsmOAuthTokenKey" }
    @objc static let notificationKey = "OsmOAuthTokenKey"
    
    override class func parseTokenJSON(data: Data) -> (ParsedTokenResponce) {
        do {
            struct AccessTokenModel: Codable {
                var access_token: String?
                var token_type: String?
                var scopesuccess: String?
                var created_at: Int?
            }
            
            let parsedJSON = try JSONDecoder().decode(AccessTokenModel.self, from: data)
            if let token = parsedJSON.access_token {
                return (token: token, expirationTimestamp: nil)
            }
            print("parseTokenJSON() Error:  \(String(decoding: data, as: UTF8.self))")
        } catch {
            print("parseTokenJSON() Error: \(error)")
        }
        return (token: nil, expirationTimestamp: nil)
    }
    
    override class func onComplete() async {
        await fetchUserData()
        sendNotifications()
    }
    
    static func fetchUserData() async {
        struct UserDataModel: Codable {
            var user: UserModel?
        }
        struct UserModel: Codable {
            var id: Int?
            var display_name: String?
            var img: ImageModel?
        }
        struct ImageModel: Codable {
            var href: String?
        }
        do {
            if let header = getAutorizationHeader() {
                guard let url = URL(string: "https://api.openstreetmap.org/api/0.6/user/details.json") else { return }
                var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
                request.httpMethod = "GET"
                request.allHTTPHeaderFields = ["Authorization": header]
                let (data, _) = try await URLSession.shared.data(for: request)
                let parsedJSON: UserDataModel = try JSONDecoder().decode(UserDataModel.self, from: data)
                OAAppSettings.sharedManager().osmUserName.set(parsedJSON.user!.display_name)
            }
        } catch {
            print("fetchUserData() Error: \(error)")
        }
    }
    
    @objc static func getAutorizationHeader() -> String? {
        if (isOAuthLogged()) {
            return "Bearer " + self.getToken()!
        } else if (isLegacyLogged()) {
            var content = getUserName() + ":" + getLegacyPassword()
            content = content.data(using: .utf8)!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            return "Basic " + content
        }
        return nil
    }
    
    @objc static func isLogged() -> Bool {
        return isLegacyLogged() || isOAuthLogged()
    }
    
    @objc static func isLegacyLogged() -> Bool {
        return OAAppSettings.sharedManager().osmUserName != nil &&
            OAAppSettings.sharedManager().osmUserPassword != nil &&
            OAAppSettings.sharedManager().osmUserName.get().length > 0 &&
            OAAppSettings.sharedManager().osmUserPassword.get().length > 0
    }
    
    @objc static func isOAuthLogged() -> Bool {
        return self.getToken() != nil && self.getToken()!.length > 0
    }
    
    @objc static func getUserName() -> String {
        return OAAppSettings.sharedManager().osmUserName.get()
    }
    
    @objc static func getLegacyPassword() -> String {
        return OAAppSettings.sharedManager().osmUserPassword.get()
    }
    
    @objc static func logOut() {
        OAAppSettings.sharedManager().osmUserName.resetToDefault()
        OAAppSettings.sharedManager().osmUserPassword.resetToDefault()
        OAAppSettings.sharedManager().osmUserDisplayName.resetToDefault()
        OAAppSettings.sharedManager().osmUserDisplayName.resetToDefault()
        setToken(token: nil)
        sendNotifications()
    }
    
    static func sendNotifications() {
        NotificationCenter.default.post(name: Notification.Name(notificationKey), object: nil)
    }
    
    
    @objc static func showAuthIntroScreen(hostVC: UIViewController) {
        if #available(iOS 16.4, *) {
            hostVC.present(OsmOAuthSwidtUIViewWrapper.get(), animated: true)
        } else {
            let targetVC = OAOsmLoginMainViewController()
            if let delegateHostVC = hostVC as? OAAccountSettingDelegate {
                targetVC.delegate = delegateHostVC
            }
            hostVC.present(targetVC, animated: true)
        }
    }
    
}
