//
//  ImageCardCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class ImageCardCell: UICollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var usernameLabelShadow: UIView!
    @IBOutlet private weak var logoView: UIImageView!
    @IBOutlet private weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var urlTextView: UILabel!
    
    private var item: ImageCard!
    
    func configure(item: ImageCard, showLogo: Bool) {
        self.item = item
        logoView.isHidden = !showLogo
        
        if showLogo {
            if !item.topIcon.isEmpty {
                logoView.image = UIImage(named: item.topIcon)
            } else {
                logoView.image = nil
            }
        }

        downloadImage()
    }
    
    func downloadImage() {
        guard let item else { return }
        
        if item.imageUrl.isEmpty { return }
        
        guard let imgURL = URL(string:  item.imageUrl) else { return }
        let session = URLSession(configuration: .default)
        
        session.dataTask(with: imgURL) { [weak self] data, response, error in
            guard let self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data {
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }.resume()
    }
}
