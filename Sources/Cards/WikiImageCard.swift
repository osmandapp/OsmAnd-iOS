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
        if let author = dic["author"] as? String, !author.isEmpty {
            metadata?.author = author
        }
        if let license = dic["license"] as? String, !license.isEmpty {
            metadata?.license = license
        }
        if let mediaId = dic["mediaId"] as? Int {
            self.mediaId = mediaId
        }
        
        applyDescription(from: dic)
    }
    
    func applyDescription(from dic: [String: Any]) {
        guard
            let jsonString = dic["description"] as? String,
            let data = jsonString.data(using: .utf8),
            let descriptions = try? JSONSerialization.jsonObject(with: data) as? [String: String],
            !descriptions.isEmpty
        else {
            return
        }

        let mapLang = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        var description: String?

        // Try direct mapLang
        if let value = descriptions[mapLang], !value.isEmpty {
            description = value
        } else {
            // Try user preferred languages
            for lang in Locale.preferredLanguageCodes {
                if let value = descriptions[lang], !value.isEmpty {
                    description = value
                    break
                }
            }
            
            // first non-empty value
            if description == nil {
                description = descriptions.values.first(where: { !$0.isEmpty })
            }
        }

        if let description {
            metadata?.description = description.replacingOccurrences(of: "\n", with: "")
        }
    }
    
    private func isEmpty(_ string: String?) -> Bool {
        string == nil || string?.isEmpty ?? true || string == "Unknown"
    }
}

final class WikiImageCard: ImageCard {
    private(set) var urlWithCommonAttributions: String

    var wikiImage: WikiImage?
    
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
