//
//  NoImagesCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class NoImagesCell: UICollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = localizedString("no_photos_available")
        }
    }
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.text = localizedString("no_photos_available_descr")
        }
    }
    @IBOutlet private weak var contentStackView: UIStackView!
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
    
    let topBottomPadding: Float = 40.0
    
    func showAddPhotosButton(_ show: Bool) {
        addPhotosButton.superview?.isHidden = !show
    }
    
    @IBAction private func onAddPhotosButtonPressed(_ sender: Any) {
        OAMapillaryPlugin.installOrOpenMapillary()
    }
}

extension NoImagesCell: CellHeightDelegate {
    func height() -> Float {
        let contentHeight = Float(contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
        
        return contentHeight + topBottomPadding
    }
}
