//
//  DownloadMetadataProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 06.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class DownloadMetadataProvider {
    let osmandParseUrl = "https://osmand.net/search/parse-images-list-info?"
    
    var cards: [AbstractCard] = [] {
        didSet {
            downloadAdditionalMetadataIfNeeded()
        }
    }
    
    private func downloadAdditionalMetadataIfNeeded() {
        var cardsToDownload = [WikiImageCard]()
        
        for card in cards {
            guard let obj = card as? WikiImageCard, let metadata = obj.metadata else {
                continue
            }
            
            let isMetadataMissing = isEmpty(metadata.date) || isEmpty(metadata.author) || isEmpty(metadata.license)
            
            if !obj.isMetaDataDownloaded && !obj.isMetaDataDownloading && isMetadataMissing {
                cardsToDownload.append(obj)
            }
        }
        
        guard !cardsToDownload.isEmpty else { return }
        
        let wikiImageInfoArray = getData(array: cardsToDownload)
        
        guard let json = convertToJson(wikiImageInfoArray) else {
            debugPrint("Error converting to JSON")
            return
        }
        
        sendRequest(urlString: buildUrlString(), json: json)
    }
    
    private func buildUrlString() -> String {
        var urlString = osmandParseUrl
        let settings = OAAppSettings.sharedManager()!
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
    
    private func sendRequest(urlString: String, json: String) {
        OANetworkUtilities.sendRequest(withUrl: urlString,
                                       params: nil,
                                       body: json,
                                       contentType: "application/json",
                                       post: true,
                                       async: false) { [weak self] data, response, _ in
            guard let self else { return }
            guard let data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                debugPrint("Error: No data or invalid response")
                return
            }
            
            handleResponseData(data)
        }
    }
    
    private func handleResponseData(_ data: Data) {
        do {
            if let metadataMap = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: String]] {
                updateWikiMetadata(metadataMap: metadataMap)
            } else {
                debugPrint("Erorr metadataMap")
            }
        } catch {
            debugPrint("Error parsing response: \(error)")
        }
    }
    
    private func updateWikiMetadata(metadataMap: [String: [String: String]]) {
        let wikiImageCars = cards.compactMap({ $0 as? WikiImageCard })
        guard !wikiImageCars.isEmpty else { return }
        wikiImageCars.forEach { $0.isMetaDataDownloading = true }
        
        for (key, value) in metadataMap {
            // NOTE: server bag. There can be multiple cards with the same wikiMediaTag.
            let wikiImageCardResult = wikiImageCars.filter { $0.wikiImage?.wikiMediaTag == key }
            guard !wikiImageCardResult.isEmpty else { continue }
            
            for item in wikiImageCardResult {
                item.wikiImage?.updateMetaData(with: value)
                item.isMetaDataDownloaded = true
            }
        }
    }
    
    private func isEmpty(_ string: String?) -> Bool {
        string == nil || string?.isEmpty ?? true || string == "Unknown"
    }
    
    private func getData(array: [WikiImageCard]) -> [WikiImageInfo] {
        var items: [WikiImageInfo] = []
        for card in array {
            guard let title = card.wikiImage?.wikiMediaTag, !title.isEmpty else {
                continue
            }
            
            let pageId = card.wikiImage?.mediaId ?? -1
            // NOTE: server bar. !items.contains(where: { $0.pageId == pageId }) 
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
