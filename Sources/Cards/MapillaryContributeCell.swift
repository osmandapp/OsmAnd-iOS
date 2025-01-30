//
//  MapillaryContributeCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapillaryContributeCell: UICollectionViewCell {

    @IBOutlet private weak var contributeLabel: UILabel! {
        didSet {
            contributeLabel.text = localizedString("mapillary_action_descr")
        }
    }
    @IBOutlet private weak var addPhotosButton: UIButton! {
        didSet {
            addPhotosButton.setTitle(localizedString("shared_string_add_photos"), for: .normal)
            
            let image = addPhotosButton.imageView?.image?.withTintColor(.white)
            addPhotosButton.setImage(image, for: .normal)
            var configuration = addPhotosButton.configuration
            configuration?.imagePadding = 12
            addPhotosButton.configuration = configuration
        }
    }
    
    @IBAction private func onAddPhotosButtonPressed(_ sender: Any) {
        OAMapillaryPlugin.installOrOpenMapillary()
    }
}

extension MapillaryContributeCell: CellHeightDelegate {
    func height() -> Float {
        156
    }
}
