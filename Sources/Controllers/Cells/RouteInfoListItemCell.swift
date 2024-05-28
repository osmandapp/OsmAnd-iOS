//
//  RouteInfoListItemCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 27/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OARouteInfoListItemCell)
@objcMembers
final class RouteInfoListItemCell: UITableViewCell {
    
    @IBOutlet private weak var leftImageView: UIImageView!
    @IBOutlet private weak var topLeftLabel: UILabel!
    @IBOutlet private weak var topRightLabel: UILabel!
    @IBOutlet private weak var bottomLabel: UILabel!
    @IBOutlet private weak var bottomImageView: UIImageView!
    @IBOutlet private weak var bottomImageBorderView: UIView!
    @IBOutlet private weak var bottomImageBorderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomImageStackView: UIStackView!
    
    let bottomImageViewDefaultWidth: CGFloat = 30
    let bottomImageViewInnerHeight: CGFloat = 22
    
    var leftTurnIconDrawable: OATurnDrawable?
    
    override class func getIdentifier() -> String {
        "RouteInfoListItemCell"
    }
    
    func setLeftImageView(image: UIImage?) {
        leftImageView.image = image
    }
    
    func setleftTurnIconDrawable(drawable: OATurnDrawable) {
        leftTurnIconDrawable = drawable
    }
    
    func setTopLeftLabel(text: String?) {
        topLeftLabel.text = text
    }
    
    func setTopRightLabel(text: String?) {
        topRightLabel.text = text
    }
    
    func setBottomLabel(text: String?) {
        bottomLabel.text = text
    }
    
    func setBottomLanesImage(image: UIImage?) {
        if let image {
            bottomImageStackView.isHidden = false
            bottomImageView.image = image
            
            bottomImageBorderView.layer.cornerRadius = 5
            bottomImageBorderView.layer.borderWidth = 2
            bottomImageBorderView.layer.borderColor = UIColor.iconColorDefault.cgColor
            
            bottomImageBorderViewWidthConstraint.constant = image.size.width / (image.size.height / bottomImageViewInnerHeight)
            bottomImageBorderViewWidthConstraint.constant += 16
        } else {
            bottomImageStackView.isHidden = true
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.refreshLeftIcon()
        }
    }
    
    private func refreshLeftIcon() {
        if let leftTurnIconDrawable {
            leftTurnIconDrawable.clr = (traitCollection.userInterfaceStyle == .dark) ? .white : .black
            leftTurnIconDrawable.setNeedsDisplay()
            let recoloredImage = leftTurnIconDrawable.toUIImage()
            setLeftImageView(image: recoloredImage)
        }
    }
}
