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
class OsmOAuthHelper: BaseOAuthHelper {
    
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
    static var delegate: OAAccountSettingDelegate?
    
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
        if let delegate {
            delegate.onAccountInformationUpdated()
        }
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
        if isOAuthAuthorised() {
            return "Bearer " + token!
        }
        return nil
    }
    
    static func isAuthorised() -> Bool {
        return isOAuthAuthorised()
    }
    
    static func isOAuthAuthorised() -> Bool {
        return token != nil && token!.length > 0
    }

    static func getUserDisplayName() -> String {
        return OAAppSettings.sharedManager().osmUserDisplayName.get()
    }
    
    static func logOut() {
        token = ""
        OAAppSettings.sharedManager().osmUserDisplayName.resetToDefault()
        sendNotifications()
    }
    
    static func sendNotifications() {
        NotificationCenter.default.post(name: Notification.Name(notificationKey), object: nil)
    }

    static func showAuthIntroScreen(hostVC: UIViewController) {
        if #available(iOS 16.4, *) {
            hostVC.present(OsmOAuthSwiftUIViewWrapper.get(), animated: true)
        }
        // No auth by login & password for older ios version.
    }
    
    // MARK: - Legacy methods
    
    // We're using for OAuth ios standard library "WebAuthenticationSession".
    // But it available only since ios 16.4 .
    // For previous ios versions we sended user to screen with auth by login & password.
    // But since 2024 OSM removed auth by login & password from their site at all.
    // So now we have to unlogin all user earlier authed by login & password, because that will work no more.
    // And show them screen with login by OAuth.
    // For users with ios older that 16.4 we can only show message to update ios version to have app with OAuth.
    
    static func isOAuthAllowed() -> Bool {
        if #available(iOS 16.4, *) {
            return true
        }
        return false
    }
    
    static func logOutIfNeeded() {
        if !isOAuthAllowed() {
            logOut()
        }
    }
}
