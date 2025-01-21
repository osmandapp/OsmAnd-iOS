//
//  NoImagesCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class NoImagesCard: AbstractCard {

    private var collectionCell: NoImagesCell?
    
    override func build(in cell: UICollectionViewCell) {
        if let oaCell = cell as? NoImagesCell {
            collectionCell = oaCell
        }
        super.build(in: cell)
    }
    
    override func update() {
        guard let collectionCell = collectionCell else { return }
        
        collectionCell.backgroundColor = .groupBg
        collectionCell.noImagesLabel.text = localizedString("mapil_no_images")
        collectionCell.imageView.image = UIImage.templateImageNamed("ic_custom_trouble.png")
        collectionCell.imageView.tintColor = .iconColorDefault
        
        OAUtilities.image(with: .buttonBgColorPrimary)
        
        collectionCell.addPhotosButton.setBackgroundImage(
            OAUtilities.image(with: .buttonBgColorPrimary),
            for: .normal
        )
        
        collectionCell.addPhotosButton.setImage(
            UIImage.templateImageNamed("ic_custom_add.png"),
            for: .normal
        )
        
        collectionCell.addPhotosButton.imageView?.tintColor = .buttonTextColorPrimary
        collectionCell.addPhotosButton.setTitle(localizedString("shared_string_add_photos"), for: .normal)
        
        collectionCell.addPhotosButton.addTarget(self, action: #selector(addPhotosButtonPressed(_:)), for: .touchUpInside)
    }
    
    @objc func addPhotosButtonPressed(_ sender: Any) {
        OAMapillaryPlugin.installOrOpenMapillary()
    }
    
    override class func getCellNibId() -> String {
        NoImagesCell.reuseIdentifier
    }
}
