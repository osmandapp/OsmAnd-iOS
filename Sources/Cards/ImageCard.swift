//
//  ImageCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
class ImageCard: AbstractCard {
    
    private static let GALLERY_FULL_SIZE_WIDTH = "1280"

    var type: String
    var latitude: Double
    var longitude: Double
    var ca: Double
    var timestamp: String
    var key: String
    var title: String
    var userName: String
    var url: String
    var imageUrl: String
    var imageHiresUrl: String
    var externalLink: Bool
    var topIcon: String
    
    // Initializer
    init(data: [String: Any]) {
        self.type = data["type"] as? String ?? ""
        self.ca = data["ca"] as? Double ?? 0.0
        self.latitude = data["lat"] as? Double ?? 0.0
        self.longitude = data["lon"] as? Double ?? 0.0
        self.timestamp = data["timestamp"] as? String ?? ""
        self.key = data["key"] as? String ?? ""
        self.title = data["title"] as? String ?? ""
        self.userName = data["username"] as? String ?? ""
        self.url = data["url"] as? String ?? ""
        self.imageUrl = data["imageUrl"] as? String ?? ""
        self.imageHiresUrl = data["imageHiresUrl"] as? String ?? ""
        self.externalLink = data["externalLink"] as? Bool ?? false
        self.topIcon = ""
        super.init()
        self.topIcon = getIconName(data["topIcon"] as? String ?? "")
    }
    
    // Private Method to determine icon name
    private func getIconName(_ serverIconName: String) -> String {
        if serverIconName == "ic_logo_mapillary" {
            return "ic_custom_mapillary_color_logo.png"
        } else if type == "wikimedia-photo" {
            return "ic_custom_logo_wikimedia.png"
        } else if type == "wikidata-photo" {
            return "ic_custom_logo_wikidata.png"
        } else {
            return serverIconName
        }
    }
    
    // Get suitable URL (high res or regular)
    func getSuitableUrl() -> String {
        !imageHiresUrl.isEmpty ? imageHiresUrl : imageUrl
    }
    
    func getGalleryFullSizeUrl() -> String? {
        guard !imageHiresUrl.isEmpty else {
            return nil
        }
        return imageHiresUrl + "?width=" + Self.GALLERY_FULL_SIZE_WIDTH
    }

    override func onCardPressed(_ mapPanel: OAMapPanelViewController) {
        debugPrint("open gallery")
//        guard let viewController = OAWebViewController(urlAndTitle: urlWithCommonAttributions, title: title) else { return }
//        mapPanel.navigationController?.pushViewController(viewController, animated: true)
    }
    
    // Static method to get the cell Nib identifier
    override class func getCellNibId() -> String {
        ImageCardCell.reuseIdentifier
    }
}
