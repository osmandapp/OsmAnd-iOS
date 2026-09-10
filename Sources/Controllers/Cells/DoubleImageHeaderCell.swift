//
//  DoubleImageHeaderCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class DoubleImageHeaderCell: UITableViewCell {
    @IBOutlet private weak var leftBackgroundImageView: UIImageView!
    @IBOutlet private weak var rightBackgroundImageView: UIImageView!
    @IBOutlet private weak var secondBackgroundImageView: UIImageView!
    @IBOutlet private weak var firstBackgroundView: UIView!
    @IBOutlet private weak var secondBackgroundView: UIView!

    func configure(leftImage: UIImage,
                   rightImage: UIImage,
                   secondImage: UIImage,
                   isSingleView: Bool,
                   cornerRadius: CGFloat) {
        leftBackgroundImageView.image = leftImage
        rightBackgroundImageView.image = rightImage
        secondBackgroundImageView.image = secondImage

        rightBackgroundImageView.isHidden = !isSingleView
        secondBackgroundView.isHidden = isSingleView

        firstBackgroundView.layer.cornerRadius = cornerRadius
        firstBackgroundView.clipsToBounds = true
        secondBackgroundView.layer.cornerRadius = cornerRadius
        secondBackgroundView.clipsToBounds = true
    }
}
