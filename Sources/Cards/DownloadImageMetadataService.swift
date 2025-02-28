//
//  DownloadImageMetadataService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 06.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// MARK: - Notification Names
extension Notification.Name {
    static let didDownloadMetadata = Notification.Name("didDownloadMetadata")
}

// MARK: - Custom Error Types
enum DownloadImageMetadataServiceError: Error {
    case networkError
    case invalidResponse
    case jsonSerializationError
    case metadataMissing
    case unknownError
    case invalidURL
}

final class DownloadImageMetadataService {
    
    static let shared = DownloadImageMetadataService()
    
    var cards: [WikiImageCard] = []
    
    private let osmandParseUrl = "https://osmand.net/search/parse-images-list-info?"
    
    func downloadMetadataForAllCards() async {
        do {
            try await downloadAdditionalMetadataIfNeeded(cards: cards)
        } catch {
            debugPrint("Error downloading metadata for all cards: \(error)")
        }
    }
    
    func downloadMetadata(for selectedCards: [WikiImageCard]) async {
        do {
            try await downloadAdditionalMetadataIfNeeded(cards: selectedCards)
        } catch {
            debugPrint("Error downloading metadata for selected cards: \(error)")
        }
    }
    
    func isEmpty(_ string: String?) -> Bool {
        string == nil || string?.isEmpty ?? true || string == "Unknown"
    }
    
    private init() {}
    
    private func downloadAdditionalMetadataIfNeeded(cards: [WikiImageCard]) async throws {
        guard !cards.isEmpty else { return }
        
        var cardsToDownload = [WikiImageCard]()
        
        for card in cards {
            guard let metadata = card.metadata else {
                continue
            }
            let isMetadataMissing = [metadata.date, metadata.author, metadata.license].contains { isEmpty($0) }
            
            if isMetadataMissing && !card.isMetaDataDownloaded && !card.isMetaDataDownloading {
                card.isMetaDataDownloading = true
                cardsToDownload.append(card)
            }
        }
        
        guard !cardsToDownload.isEmpty else { return }
        
        let wikiImageInfoArray = getData(array: cardsToDownload)
        
        guard let json = convertToJson(wikiImageInfoArray) else {
            throw DownloadImageMetadataServiceError.jsonSerializationError
        }
        
        try await sendRequest(urlString: buildUrlString(), json: json, wikiImageCards: cardsToDownload)
    }
    
    private func buildUrlString() -> String {
        var urlString = osmandParseUrl
        // swiftlint:disable all
        let settings = OAAppSettings.sharedManager()!
        // swiftlint:enable all
        let languageCode = OsmAndApp.swiftInstance().getLanguageCode().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        urlString += "&lang=" + languageCode
        
        appendQueryParameter(to: &urlString, key: "deviceId", value: settings.backupDeviceId.get())
        appendQueryParameter(to: &urlString, key: "accessToken", value: settings.backupAccessToken.get())
        
        return urlString
    }
    
    private func appendQueryParameter(to urlString: inout String, key: String, value: String?) {
        guard let value, !value.isEmpty else { return }
        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
        urlString += "&\(key)=" + encodedValue
    }
    
    private func sendRequest(urlString: String, json: String, wikiImageCards: [WikiImageCard]) async throws {
        guard let url = URL(string: urlString) else {
            debugPrint("Invalid URL: \(urlString)")
            throw DownloadImageMetadataServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(json.utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                debugPrint("Invalid response: \(response)")
                throw DownloadImageMetadataServiceError.invalidResponse
            }
            try await handleResponseData(data, wikiImageCards: wikiImageCards)
        } catch {
            debugPrint("Network error occurred while sending POST request: \(error)")
            throw DownloadImageMetadataServiceError.networkError
        }
    }
    
    private func handleResponseData(_ data: Data, wikiImageCards: [WikiImageCard]) async throws {
        do {
            guard let metadataMap = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] else {
                throw DownloadImageMetadataServiceError.jsonSerializationError
            }
            try await updateWikiMetadata(metadataMap: metadataMap, wikiImageCards: wikiImageCards)
        } catch {
            debugPrint("Error handling response data: \(error)")
            throw DownloadImageMetadataServiceError.jsonSerializationError
        }
    }
    
    private func updateWikiMetadata(metadataMap: [String: [String: String]],
                                    wikiImageCards: [WikiImageCard]) async throws {
        guard !wikiImageCards.isEmpty else { return }
       
        for (key, value) in metadataMap {
            let wikiImageCardResult = wikiImageCards.filter { $0.wikiImage?.wikiMediaTag == key }
            guard !wikiImageCardResult.isEmpty else { continue }
            
            for item in wikiImageCardResult {
                item.wikiImage?.updateMetaData(with: value)
                item.isMetaDataDownloading = false
                item.isMetaDataDownloaded = true
            }
        }
        
        wikiImageCards.forEach { $0.isMetaDataDownloading = false }
        
        Task { @MainActor in
            NotificationCenter.default.post(name: .didDownloadMetadata, object: self, userInfo: ["cards": wikiImageCards])
        }
    }
    
    private func getData(array: [WikiImageCard]) -> [WikiImageInfo] {
        var items: [WikiImageInfo] = []
        for card in array {
            guard let title = card.wikiImage?.wikiMediaTag, !title.isEmpty else {
                continue
            }
            
            let pageId = card.wikiImage?.mediaId ?? -1
            if pageId != -1, !items.contains(where: { $0.pageId == pageId }) {
                items.append(WikiImageInfo(title: title, pageId: pageId))
            }
        }
        
        return items
    }
    
    private func convertToJson(_ array: [WikiImageInfo]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(array)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            debugPrint("Error encoding to JSON: \(error)")
        }
        return nil
    }
}
