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
    var placeholderImage: UIImage?
    
    // swiftlint:disable all
    private var item: ImageCard!
    // swiftlint:enable all
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
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
            placeholder: ImageCardPlaceholder(placeholderImage: placeholderImage),
            options: [
                .processor(DownsamplingImageProcessor(size: .init(width: height, height: height))),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ])
    }
}

final class ImageCardPlaceholder: Placeholder {
    private var placeholderImageView: UIImageView?
    private var width: CGFloat
    private var height: CGFloat
    private var placeholderImage: UIImage?
    
    init(width: CGFloat = 40.0, height: CGFloat = 30.0, placeholderImage: UIImage?) {
        self.width = width
        self.height = height
        self.placeholderImage = placeholderImage
    }

    func add(to imageView: KFCrossPlatformImageView) {
        placeholderImageView?.removeFromSuperview()
        let imageViewPlaceholder = UIImageView()
        imageViewPlaceholder.image = placeholderImage ?? .icCustomLink
        imageViewPlaceholder.contentMode = .scaleAspectFill
        imageViewPlaceholder.tintColor = .iconColorDefault
        imageViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(imageViewPlaceholder)
        NSLayoutConstraint.activate([
            imageViewPlaceholder.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            imageViewPlaceholder.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            imageViewPlaceholder.heightAnchor.constraint(equalToConstant: height),
            imageViewPlaceholder.widthAnchor.constraint(equalToConstant: width)
        ])
        placeholderImageView = imageViewPlaceholder
    }
    
    func remove(from imageView: KFCrossPlatformImageView) {
        placeholderImageView?.removeFromSuperview()
    }
}
