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

    var image: UIImage?
    
    private var collectionCell: ImageCardCell?
    private var downloaded = false
    private var downloading = false
    
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
    
    // Download Image method
    func downloadImage() {
        if imageUrl.isEmpty { return }
        
        if downloading || downloaded { return }
        
        downloading = true
        guard let imgURL = URL(string: imageUrl) else { return }
        let session = URLSession(configuration: .default)
        
        session.dataTask(with: imgURL) { [weak self] data, response, error in
            guard let self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                self.image = UIImage(data: data)
            }
            
            DispatchQueue.main.async {
                self.delegate?.requestCardReload(self)
            }
            
            self.downloaded = true
            self.downloading = false
        }.resume()
    }
    
    // Get suitable URL (high res or regular)
    func getSuitableUrl() -> String {
        !imageHiresUrl.isEmpty ? imageHiresUrl : imageUrl
    }
    
    // Build UI Cell
    override func build(in cell: UICollectionViewCell) {
        if let oaCell = cell as? ImageCardCell {
            collectionCell = oaCell
        }
        super.build(in: cell)
    }
    
    // Update Card View
    override func update() {
        guard let cell = collectionCell else { return }
        
        cell.loadingIndicatorView.isHidden = true
        
        if let image = self.image {
            cell.imageView.isHidden = false
            cell.imageView.image = image
            cell.urlTextView.isHidden = true
            cell.loadingIndicatorView.isHidden = true
            cell.loadingIndicatorView.stopAnimating()
        } else {
            cell.imageView.image = nil
            if !downloaded {
                cell.loadingIndicatorView.startAnimating()
                cell.loadingIndicatorView.isHidden = false
                downloadImage()
            } else {
                cell.imageView.isHidden = true
                cell.urlTextView.isHidden = false
                cell.urlTextView.text = imageUrl
                cell.loadingIndicatorView.isHidden = true
                cell.loadingIndicatorView.stopAnimating()
            }
        }
        
        cell.usernameLabel.text = userName
        
        if !topIcon.isEmpty {
            cell.logoView.image = UIImage(named: topIcon)
        } else {
            cell.logoView.image = nil
        }
    }
    
    // Static method to get the cell Nib identifier
    override class func getCellNibId() -> String {
        ImageCardCell.reuseIdentifier
    }
}
