//
//  MapillaryContributeCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class MapillaryContributeCard: AbstractCard {

    private var collectionCell: MapillaryContributeCell?

    override func build(in cell: UICollectionViewCell) {
        super.build(in: cell)

        if let contributeCell = cell as? MapillaryContributeCell {
            collectionCell = contributeCell
        }
    }

    override func update() {
        super.update()
        
        guard let collectionCell else { return }

        collectionCell.contributeLabel.text = localizedString("mapil_contribute")
        collectionCell.addPhotosButton.setImage(UIImage.templateImageNamed("ic_custom_mapillary_symbol.png"), for: .normal)
        collectionCell.addPhotosButton.setBackgroundImage(OAUtilities.image(with: UIColor(rgb: 0xCC458)), for: .normal)
        collectionCell.addPhotosButton.imageView?.tintColor = .white
        collectionCell.addPhotosButton.setTitle(localizedString("shared_string_add_photos"), for: .normal)
        collectionCell.addPhotosButton.addTarget(self, action: #selector(addPhotosButtonPressed), for: .touchUpInside)
    }

    @objc private func addPhotosButtonPressed() {
        OAMapillaryPlugin.installOrOpenMapillary()
    }

    static override func getCellNibId() -> String {
        MapillaryContributeCell.reuseIdentifier
    }
}
