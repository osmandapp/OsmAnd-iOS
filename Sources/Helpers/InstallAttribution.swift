//
//  InstallAttribution.swift
//  OsmAnd
//
//  Created by OsmAnd on 14/10/2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import AdServices

@objcMembers
final class InstallAttribution: NSObject {
    private static let attributionKey = "install_attribution"
    private static let checkedKey = "install_attribution_checked"
    private static let reportedKey = "install_attribution_reported"
    private static let attributionURL = URL(string: "https://api-adservices.apple.com/api/v1/")!
    private static let maxAttempts = 3
    private static let retryDelay: TimeInterval = 5
    private static let lock = NSLock()

    private static var isReading = false
    private static var reportInFlight = false
    private static var pendingCompletions: [() -> Void] = []

    private static var isAllowed: Bool {
        OAAppSettings.sharedManager().sendAnonymousAppUsageData.get()
    }

    private static var storedParams: [String: String] {
        guard isAllowed else { return [:] }
        return UserDefaults.standard.dictionary(forKey: attributionKey) as? [String: String] ?? [:]
    }

    static func checkAndReport() {
        readOnce { reportIfNeeded() }
    }

    // The completion runs on the main queue after a definitive result or a retryable failure.
    private static func readOnce(completion: @escaping () -> Void) {
        guard isAllowed else {
            DispatchQueue.main.async(execute: completion)
            return
        }

        lock.lock()
        if UserDefaults.standard.bool(forKey: checkedKey) {
            lock.unlock()
            DispatchQueue.main.async(execute: completion)
            return
        }
        pendingCompletions.append(completion)
        if isReading {
            lock.unlock()
            return
        }
        isReading = true
        lock.unlock()

        DispatchQueue.global(qos: .utility).async {
            guard isAllowed else {
                finish()
                return
            }
            do {
                let token = try AAAttribution.attributionToken()
                guard !token.isEmpty else {
                    finish()
                    return
                }
                requestAttribution(token: token, attempt: 1)
            } catch {
                // A network or internal error may be temporary. Retry on the next foreground entry.
                finish()
            }
        }
    }

    private static func requestAttribution(token: String, attempt: Int) {
        guard isAllowed else {
            finish()
            return
        }

        var request = URLRequest(url: attributionURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = token.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode
            if error != nil {
                finish()
                return
            }
            if status == 200, let data,
               let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
               let attributed = json["attribution"] as? Bool {
                if !attributed {
                    if isAllowed {
                        UserDefaults.standard.removeObject(forKey: attributionKey)
                        UserDefaults.standard.set(true, forKey: checkedKey)
                    }
                } else if let params = campaignParams(from: json), isAllowed {
                    UserDefaults.standard.set(params, forKey: attributionKey)
                    UserDefaults.standard.set(true, forKey: checkedKey)
                }
                // A malformed response remains retryable on the next foreground entry.
                finish()
            } else if status == 400 {
                finish()
            } else if status == 404 || status == 500, attempt < maxAttempts {
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + retryDelay) {
                    requestAttribution(token: token, attempt: attempt + 1)
                }
            } else {
                // Exhausted retries and unexpected responses can be retried on a later launch.
                finish()
            }
        }.resume()
    }

    private static func campaignParams(from json: [String: Any]) -> [String: String]? {
        guard let campaignID = identifier(json["campaignId"]),
              let conversionType = json["conversionType"] as? String,
              !conversionType.isEmpty else { return nil }
        var params = ["utm_source": "apple_ads", "utm_campaign": campaignID, "conversion_type": conversionType]
        if let adGroupID = identifier(json["adGroupId"]) {
            params["utm_content"] = adGroupID
        }
        if let keywordID = identifier(json["keywordId"]) {
            params["utm_term"] = keywordID
        }
        if json["claimType"] as? String == "Click" {
            params["ad_click"] = "1"
        }
        return params
    }

    private static func identifier(_ value: Any?) -> String? {
        if let value = value as? NSNumber { return value.stringValue }
        if let value = value as? String, !value.isEmpty { return value }
        return nil
    }

    private static func finish() {
        lock.lock()
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        isReading = false
        lock.unlock()
        DispatchQueue.main.async {
            completions.forEach { $0() }
        }
    }

    private static func reportIfNeeded() {
        let params = storedParams
        guard isAllowed else {
            return
        }
        guard !params.isEmpty else {
            return
        }
        guard !UserDefaults.standard.bool(forKey: reportedKey) else {
            return
        }
        guard let app = OsmAndApp.swiftInstance(),
              var components = URLComponents(string: "https://osmand.net/api/motd") else {
            return
        }

        var queryItems = [
            URLQueryItem(name: "os", value: "ios"),
            URLQueryItem(name: "version", value: OAAppVersion.getVersion()),
            URLQueryItem(name: "nd", value: String(app.getAppInstalledDays())),
            URLQueryItem(name: "ns", value: String(app.getAppExecCount())),
            URLQueryItem(name: "lang", value: app.getLanguageCode())
        ]
        if let aid = app.getUserIosId(), !aid.isEmpty {
            queryItems.append(URLQueryItem(name: "aid", value: aid))
        }
        queryItems += params.keys.sorted().map { URLQueryItem(name: $0, value: params[$0]) }
        components.queryItems = queryItems
        guard let url = components.url else {
            return
        }

        lock.lock()
        if reportInFlight {
            lock.unlock()
            return
        }
        reportInFlight = true
        lock.unlock()

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.setValue("OsmAndiOS", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error == nil && (200..<300).contains(status) {
                // The request may finish after the user disables anonymous usage data.
                UserDefaults.standard.set(true, forKey: reportedKey)
            }
            lock.lock()
            reportInFlight = false
            lock.unlock()
        }.resume()
    }

    static func addParams(_ params: NSMutableDictionary) {
        for (key, value) in storedParams {
            params[key] = value
        }
    }
}
