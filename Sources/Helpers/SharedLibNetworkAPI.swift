//
//  NetworkAPIImpl.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 06.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

final class SharedLibNetworkAPI: NSObject, NetworkAPI {

    private static let requestTimeout: TimeInterval = 30

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        return URLSession(configuration: config)
    }()

    func hasProxy() -> Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [AnyHashable: Any] else {
            return false
        }

        return settings[kCFNetworkProxiesHTTPProxy as String] != nil
    }

    func setProxy(host: String?, port: Int32) {
        // proxy is configured externally
    }

    func sendGetRequest(url: String,
                        auth: String?,
                        useGzip: Bool,
                        userAgent: String) -> NetworkAPINetworkResponse {
        precondition(!Thread.isMainThread, "sendGetRequest must not be called on main thread")

        guard let urlObj = URL(string: url) else {
            return .init(response: nil, error: "Malformed URL")
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        if let auth {
            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        }

        if useGzip {
            request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var result: NetworkAPINetworkResponse?

        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let error {
                result = .init(response: nil, error: error.localizedDescription)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                result = .init(response: nil, error: "Unexpected response type")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                result = .init(response: nil, error: "Unexpected status code \(httpResponse.statusCode)")
                return
            }

            let body = data.map { String(decoding: $0, as: UTF8.self) }
            result = .init(response: body, error: nil)
        }

        task.resume()

        if semaphore.wait(timeout: .now() + Self.requestTimeout) == .timedOut {
            task.cancel()
            return .init(response: nil, error: "Request timed out")
        }

        return result ?? .init(response: nil, error: "Unknown error")
    }
}
