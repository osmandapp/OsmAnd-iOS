//
//  ImageCardCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

final class ImageCardCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var usernameLabelShadow: UIView!
    @IBOutlet private weak var logoView: UIImageView!
    @IBOutlet private weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var urlTextView: UILabel!
    
    var isBigPhoto = false
    
    private var item: ImageCard!
    
    func configure(item: ImageCard, showLogo: Bool) {
        self.item = item
        logoView.isHidden = !showLogo
        isBigPhoto = showLogo
        
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
        guard !item.imageUrl.isEmpty,
              let url = URL(string: item.imageUrl) else { return }
        
        let height = isBigPhoto ? 156 : 72
        
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [
                .processor(DownsamplingImageProcessor(size: .init(width: height, height: height))),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ])
    }
}
