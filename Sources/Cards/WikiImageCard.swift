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
}

final class WikiImageCard: ImageCard {
    private(set) var urlWithCommonAttributions: String

    init(wikiImage: WikiImage, type: String) {
        self.urlWithCommonAttributions = wikiImage.getUrlWithCommonAttributions()
        super.init(data: [:])
        
        self.type = type
       
        self.topIcon = "ic_custom_logo_wikimedia"
        self.imageUrl = wikiImage.imageStubUrl
        self.title = wikiImage.imageName
        self.url = self.imageUrl
    }

    func opneURL(_ mapPanel: OAMapPanelViewController) {
        guard let viewController = OAWebViewController(urlAndTitle: urlWithCommonAttributions, title: title) else { return }
        mapPanel.navigationController?.pushViewController(viewController, animated: true)
    }
}
