//
//  WikiImage.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

let WIKIMEDIA_COMMONS_URL = "https://commons.wikimedia.org/wiki/"
let WIKIMEDIA_FILE = "File:"

@objcMembers
final class WikiImage: NSObject {
    let imageName: String
    let imageStubUrl: String
    let imageHiResUrl: String
    let wikiMediaTag: String
    
    var mediaId: Int = -1
    var metadata: Metadata?
    var onMetadataUpdated: (() -> Void)?
    
    init(wikiMediaTag: String, imageName: String, imageStubUrl: String, imageHiResUrl: String) {
        self.wikiMediaTag = wikiMediaTag
        self.imageName = imageName
        self.imageStubUrl = imageStubUrl
        self.imageHiResUrl = imageHiResUrl
        super.init()
    }
    
    func getUrlWithCommonAttributions() -> String {
        "\(WIKIMEDIA_COMMONS_URL)\(WIKIMEDIA_FILE)\(wikiMediaTag)"
    }
    
    func parseMetaData(with dic: [String: Any]) {
        self.metadata = Metadata()
        
        if let date = dic["date"] as? String, !date.isEmpty {
            metadata?.date = date
        }
        if let author = dic["author"] as? String, author.isEmpty {
            metadata?.author = author
        }
        if let license = dic["license"] as? String, license.isEmpty {
            metadata?.license = license
        }
        if let mediaId = dic["mediaId"] as? Int {
            self.mediaId = mediaId
        }
    }
    
    func updateMetaData(with dic: [String: Any]) {
        if metadata == nil {
            self.metadata = Metadata()
        }
        var isUpdated = false
        if let date = dic["date"] as? String, !isEmpty(date), isEmpty(metadata?.date) {
            metadata?.date = date
            isUpdated = true
        }
        
        if let license = dic["license"] as? String, !isEmpty(license), isEmpty(metadata?.license) {
            metadata?.license = license
            isUpdated = true
        }
        
        if let author = dic["author"] as? String, !isEmpty(author), isEmpty(metadata?.author) {
            metadata?.author = author
            isUpdated = true
        }
        
        if let description = dic["description"] as? String, !isEmpty(description), isEmpty(metadata?.description) {
            metadata?.description = description.replacingOccurrences(of: "\n", with: "")
            isUpdated = true
        }
        if isUpdated {
            DispatchQueue.main.async { [weak self] in
                self?.onMetadataUpdated?()
            }
        }
    }
    
    private func isEmpty(_ string: String?) -> Bool {
        string == nil || string?.isEmpty ?? true || string == "Unknown"
    }
}

final class WikiImageCard: ImageCard {
    private(set) var urlWithCommonAttributions: String
    
    var isMetaDataDownloaded = false
    var isMetaDataDownloading = false
    var wikiImage: WikiImage?
    
    var onMetadataUpdated: (() -> Void)? {
        didSet {
            wikiImage?.onMetadataUpdated = onMetadataUpdated
        }
    }
    
    var metadata: Metadata? {
        wikiImage?.metadata
    }
    
    override var hash: Int {
        wikiImage?.mediaId ?? 0
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return wikiImage?.mediaId == other.wikiImage?.mediaId
    }
    
    static func == (lhs: WikiImageCard, rhs: WikiImageCard) -> Bool {
        lhs.wikiImage?.mediaId == rhs.wikiImage?.mediaId
    }
    
    init(wikiImage: WikiImage, type: String) {
        self.urlWithCommonAttributions = wikiImage.getUrlWithCommonAttributions()
        super.init(data: [:])
        self.wikiImage = wikiImage
        self.type = type
        
        self.topIcon = "ic_custom_logo_wikimedia"
        self.imageUrl = wikiImage.imageStubUrl
        self.title = wikiImage.imageName
        self.url = self.imageUrl
        self.imageHiresUrl = wikiImage.imageHiResUrl
    }
    
    func openURL(_ mapPanel: OAMapPanelViewController) {
        guard let viewController = OAWebViewController(urlAndTitle: urlWithCommonAttributions, title: title) else { return }
        mapPanel.navigationController?.pushViewController(viewController, animated: true)
    }
}

struct Metadata {
    var date: String?
    var author: String?
    var license: String?
    var description: String?
    
    var formattedDate: String {
        WikiAlgorithms.formatWikiDate(date)
    }
    
    var isEmpty: Bool {
        [date, author, license, description].allSatisfy { $0 == nil }
    }
}
