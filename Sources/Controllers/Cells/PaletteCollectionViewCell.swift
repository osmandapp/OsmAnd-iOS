//
//  PaletteCollectionViewCell.swift
//  OsmAnd Maps
//
//  Created by SKalii on 06.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

class PaletteCollectionViewCell: UICollectionViewCell {

    @IBOutlet var selectionView: UIView!
    @IBOutlet var backgroundImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionView.layer.cornerRadius = 9
        backgroundImageView.layer.cornerRadius = 3
    }
}
