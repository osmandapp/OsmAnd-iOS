//
//  RouteInfoListItemCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 27/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

final class RouteInfoListItemCell: UITableViewCell {
    
    @IBOutlet private weak var leftImageView: UIImageView!
    @IBOutlet private weak var topLeftLabel: UILabel!
    @IBOutlet private weak var topRightLabel: UILabel!
    @IBOutlet private weak var bottomLabel: UILabel!
    @IBOutlet private weak var bottomImageView: UIImageView!
    @IBOutlet private weak var bottomImageBorderView: UIView!
    @IBOutlet private weak var bottomImageBorderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomImageStackView: UIStackView!
    
    let bottomImageViewDefaultSize: CGFloat = 30
    
    override class func getIdentifier() -> String! {
        "RouteInfoListItemCell"
    }
    
    @objc func setLeftImageView(image: UIImage?) {
        leftImageView.image = image
    }
    
    @objc func setTopLeftLabel(text: String?) {
        topLeftLabel.text = text
    }
    
    @objc func setTopRightLabel(text: String?) {
        topRightLabel.text = text
    }
    
    @objc func setBottomLabel(text: String?) {
        bottomLabel.text = text
    }
    
    @objc func setBottomLanesImage(image: UIImage?) {
        if let image {
            bottomImageStackView.isHidden = false
            bottomImageView.image = image
            
            bottomImageBorderView.layer.cornerRadius = 5
            bottomImageBorderView.layer.borderWidth = 2
            bottomImageBorderView.layer.borderColor = UIColor.iconColorDefault.cgColor
            
            bottomImageBorderViewWidthConstraint.constant = image.size.width / (image.size.height / bottomImageViewDefaultSize)
            if bottomImageBorderViewWidthConstraint.constant < bottomImageViewDefaultSize {
                bottomImageBorderViewWidthConstraint.constant = bottomImageViewDefaultSize
            }
        } else {
            bottomImageStackView.isHidden = true
        }
    }
}
