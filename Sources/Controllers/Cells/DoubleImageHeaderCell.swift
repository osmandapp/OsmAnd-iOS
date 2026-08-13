//
//  DoubleImageHeaderCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class DoubleImageHeaderCell: UITableViewCell {
    @IBOutlet weak var leftBackgroundImageView: UIImageView!
    @IBOutlet weak var rightBackgroundImageView: UIImageView!
    @IBOutlet weak var secondBackgroundImageView: UIImageView!
    @IBOutlet private weak var firstBackgroundView: UIView!
    @IBOutlet private weak var secondBackgroundView: UIView!

    func configure(isSingleView: Bool, cornerRadius: CGFloat) {
        rightBackgroundImageView.isHidden = !isSingleView
        secondBackgroundView.isHidden = isSingleView

        firstBackgroundView.layer.cornerRadius = cornerRadius
        firstBackgroundView.clipsToBounds = true
        secondBackgroundView.layer.cornerRadius = cornerRadius
        secondBackgroundView.clipsToBounds = true
    }
}
