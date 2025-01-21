//
//  MapillaryContributeCell.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapillaryContributeCell: UICollectionViewCell {

    @IBOutlet weak var contributeLabel: UILabel!
    @IBOutlet weak var addPhotosButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addPhotosButton.layer.masksToBounds = true
        addPhotosButton.layer.cornerRadius = 9.0
    }
}
