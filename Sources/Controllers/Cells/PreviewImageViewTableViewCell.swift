//
//  PreviewImageViewTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class PreviewImageViewTableViewCell: UITableViewCell {
    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var previewImageContainerView: UIView!
    
    func configure(image: UIImage, cornerRadius: CGFloat = 24) {
        previewImageView.image = image
        previewImageContainerView.backgroundColor = .mapButtonBgColorDefault
        previewImageContainerView.layer.cornerRadius = cornerRadius
        setupImageContainerShadow()
    }
    
    func rotateImage(_ angle: CGFloat) {
        previewImageView.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    private func setupImageContainerShadow() {
        previewImageContainerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.35).cgColor
        previewImageContainerView.layer.shadowOpacity = 1
        previewImageContainerView.layer.shadowRadius = 12
        previewImageContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
