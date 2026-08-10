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
    
    private let descriptionLineHeightOffset: CGFloat = 2.0
    
    func configure(image: UIImage, title: String, description: String) {
        cellImageView.image = image
        cellImageView.tintColor = .iconColorDefault
        titleLabel.text = title
        descriptionLabel.attributedText = attributedDescription(description)
    }

    private func attributedDescription(_ description: String) -> NSAttributedString {
        let lineHeight = descriptionLabel.font.lineHeight + descriptionLineHeightOffset
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = descriptionLabel.textAlignment
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return NSAttributedString(string: description, attributes: [.paragraphStyle: paragraphStyle])
    }
}
