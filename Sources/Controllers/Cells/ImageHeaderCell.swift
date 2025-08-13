//
//  ImageHeaderCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 08.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class ImageHeaderCell: UITableViewCell {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var topSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leftSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightSpaceConstraint: NSLayoutConstraint!
    
    func configure(verticalSpace: CGFloat, horizontalSpace: CGFloat) {
        topSpaceConstraint.constant = verticalSpace
        bottomSpaceConstraint.constant = verticalSpace
        rightSpaceConstraint.constant = horizontalSpace
        leftSpaceConstraint.constant = horizontalSpace
    }
}
