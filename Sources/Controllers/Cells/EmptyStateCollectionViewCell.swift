//
//  EmptyStateCollectionViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class EmptyStateCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var button: UIButton!
    @IBOutlet private weak var cellImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    func configure(image: UIImage, title: String, description: String) {
        cellImageView.image = image
        cellImageView.tintColor = .iconColorDefault
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
