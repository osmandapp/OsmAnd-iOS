//
//  PreviewImageViewTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class PreviewImageViewTableViewCell: UITableViewCell {
    @IBOutlet private weak var previewImageButton: OAHudButton!
    @IBOutlet private weak var sizeConstraint: NSLayoutConstraint!
    
    func configure(appearanceParams: ButtonAppearanceParams?, buttonState: MapButtonState) {
        previewImageButton.buttonState = buttonState
        previewImageButton.setCustomAppearanceParams(appearanceParams)
        sizeConstraint.constant = previewImageButton.frame.width
        setupImageContainerShadow()
    }
    
    func rotateImage(_ angle: CGFloat) {
        previewImageButton.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    private func setupImageContainerShadow() {
        previewImageButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.35).cgColor
        previewImageButton.layer.shadowOpacity = 1
        previewImageButton.layer.shadowRadius = 12
        previewImageButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
