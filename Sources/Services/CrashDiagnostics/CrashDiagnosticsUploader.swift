//
//  CrashDiagnosticsUploader.swift
//  OsmAnd Maps
//

import Foundation

enum CrashDiagnosticsUploadError: LocalizedError {
    case endpointUnavailable
    case invalidEndpoint
    case reportTooLarge
    case rejected(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .endpointUnavailable:
            return "Crash report upload is unavailable in this build."
        case .invalidEndpoint:
            return "The crash report endpoint is invalid."
        case .reportTooLarge:
            return "The privacy-filtered crash report exceeds the two MiB transport limit."
        case let .rejected(statusCode):
            return "The crash report receiver rejected the report (HTTP \(statusCode))."
        case .invalidResponse:
            return "The crash report receiver returned an invalid response."
        }
    }
}

final class CrashDiagnosticsUploader {
    private let store: CrashDiagnosticsStore
    private let endpoint: URL?
    private let session: URLSession
    private let stateChanged: () -> Void
    private let callbackQueue = DispatchQueue(label: "net.osmand.crash-diagnostics.uploader")
    private var reportsInFlight = Set<String>()

    var canUpload: Bool {
        endpoint != nil
    }

    init(
        store: CrashDiagnosticsStore,
        endpoint: URL? = CrashDiagnosticsUploader.configuredEndpoint(),
        stateChanged: @escaping () -> Void = {}
    ) {
        self.store = store
        self.endpoint = endpoint
        self.stateChanged = stateChanged

        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
    }

    func uploadApprovedReport(
        reportID: String,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        callbackQueue.async {
            guard !self.reportsInFlight.contains(reportID) else { return }
            guard let endpoint = self.endpoint else {
                DispatchQueue.main.async {
                    completion?(.failure(CrashDiagnosticsUploadError.endpointUnavailable))
                }
                return
            }

            do {
                let uploadRequest = try self.store.verifiedUploadRequest(reportID: reportID)
                let body = try CrashDiagnosticsJSON.encoder().encode(uploadRequest)
                guard body.count <= 2 * 1_024 * 1_024 else {
                    self.store.markUploadRejected(reportID: reportID)
                    self.notifyStateChanged()
                    DispatchQueue.main.async {
                        completion?(.failure(CrashDiagnosticsUploadError.reportTooLarge))
                    }
                    return
                }
                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.httpBody = body
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(reportID, forHTTPHeaderField: "Idempotency-Key")
                request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

                self.reportsInFlight.insert(reportID)
                self.session.dataTask(with: request) { _, response, error in
                    self.callbackQueue.async {
                        self.reportsInFlight.remove(reportID)
                        if let error {
                            let retryAt = self.store.markUploadFailure(reportID: reportID)
                            self.notifyStateChanged()
                            self.scheduleRetry(reportID: reportID, retryAt: retryAt)
                            DispatchQueue.main.async { completion?(.failure(error)) }
                            return
                        }
                        guard let response = response as? HTTPURLResponse else {
                            let retryAt = self.store.markUploadFailure(reportID: reportID)
                            self.notifyStateChanged()
                            self.scheduleRetry(reportID: reportID, retryAt: retryAt)
                            DispatchQueue.main.async {
                                completion?(.failure(CrashDiagnosticsUploadError.invalidResponse))
                            }
                            return
                        }
                        if (200..<300).contains(response.statusCode) {
                            self.store.delete(reportID: reportID)
                            self.notifyStateChanged()
                            DispatchQueue.main.async { completion?(.success(())) }
                        } else {
                            if response.statusCode == 408 || response.statusCode == 429 || response.statusCode >= 500 {
                                let retryAt = self.store.markUploadFailure(reportID: reportID)
                                self.scheduleRetry(reportID: reportID, retryAt: retryAt)
                            } else {
                                self.store.markUploadRejected(reportID: reportID)
                            }
                            self.notifyStateChanged()
                            DispatchQueue.main.async {
                                completion?(.failure(
                                    CrashDiagnosticsUploadError.rejected(statusCode: response.statusCode)
                                ))
                            }
                        }
                    }
                }.resume()
            } catch {
                self.notifyStateChanged()
                DispatchQueue.main.async { completion?(.failure(error)) }
            }
        }
    }

    func retryApprovedReports() {
        for reportID in store.approvedReportsDue() {
            uploadApprovedReport(reportID: reportID)
        }
    }

    private func scheduleRetry(reportID: String, retryAt: Date?) {
        guard let retryAt else { return }
        let delay = max(retryAt.timeIntervalSinceNow, 0)
        callbackQueue.asyncAfter(deadline: .now() + delay) {
            self.uploadApprovedReport(reportID: reportID)
        }
    }

    private func notifyStateChanged() {
        DispatchQueue.main.async {
            self.stateChanged()
        }
    }

    private static func configuredEndpoint() -> URL? {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let override = environment["OSMAND_CRASH_ENDPOINT"], !override.isEmpty {
            guard let url = URL(string: override),
                  url.scheme == "http" || url.scheme == "https" else {
                return nil
            }
            return url
        }
#if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:8080/api/v1/crash-reports")
#else
        return nil
#endif
#else
        return nil
#endif
    }
}
