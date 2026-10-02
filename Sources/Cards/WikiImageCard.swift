//
//  WikiImage.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

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
    
    convenience init(_ image: OsmAndShared.WikiImage) {
        self.init(wikiMediaTag: image.wikiMediaTag,
                  imageName: image.imageName,
                  imageStubUrl: image.imageStubUrl,
                  imageHiResUrl: image.imageHiResUrl)
        mediaId = Int(image.getMediaId())
        metadata = Metadata(date: Self.nonEmpty(image.metadata.date),
                            author: Self.nonEmpty(image.metadata.author),
                            license: Self.nonEmpty(image.metadata.license),
                            description: Self.localizedDescription(image.metadata.descriptions))
    }

    private static func nonEmpty(_ value: String?) -> String? {
        value?.isEmpty == false ? value : nil
    }

    private static func localizedDescription(_ descriptions: [String: String]) -> String? {
        var languages = Locale.preferredLanguageCodes
        let mapLang: String? = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        if let mapLang, !mapLang.isEmpty {
            languages.insert(mapLang, at: 0)
        }
        let description = languages.lazy.compactMap { descriptions[$0] }.first { !$0.isEmpty }
            ?? descriptions.values.first { !$0.isEmpty }
        return description?.replacingOccurrences(of: "\n", with: "")
    }

    func getUrlWithCommonAttributions() -> String {
        "\(WIKIMEDIA_COMMONS_URL)\(WIKIMEDIA_FILE)\(wikiMediaTag)"
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
