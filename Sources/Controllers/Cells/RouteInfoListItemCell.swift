//
//  RouteInfoListItemCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 27/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class RouteInfoDestinationSector: NSObject {
    @objc enum RouteInfoSector: Int {
        case straight, left, right
    }
    
    var sector: RouteInfoSector = .straight
    
    private var distance: Double = 0
    
    private var isMoreThanMinDistance: Bool {
        distance > 5
    }
    
    // MARK: - Init
    
    init(sector: RouteInfoDestinationSector.RouteInfoSector, distance: Double) {
        self.sector = sector
        self.distance = distance
    }
    
    // MARK: - Public func
    
    func getImage() -> UIImage {
        switch sector {
        case .straight:
            UIImage.icCustomRoadSideFront
        case .left:
            UIImage.icCustomRoadSideLeft
        case .right:
            UIImage.icCustomRoadSideRight
        }
    }
    
    func getTitle() -> String {
        isMoreThanMinDistance
        ? String(OAOsmAndFormatter.getFormattedDistance(Float(distance), with: OsmAndFormatterParams.useLowerBounds))
        : localizedString("arrived_at_destination")
    }
    
    func getDescriptionRoute() -> String {
        switch sector {
        case .straight:
            return localizedResult(string: "route_your_destination_is_on_ahead")
        case .left:
            return localizedResult(string: "route_your_destination_is_on_left")
        case .right:
            return localizedResult(string: "route_your_destination_is_on_right")
        }
        
        func localizedResult(string: String) -> String {
            isMoreThanMinDistance
            ? localizedString("arrived_at_destination") + ", " + localizedString(string).lowercased()
            : localizedString(string)
        }
    }
}

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
    
    let bottomImageViewInnerHeight: CGFloat = 30
    let leftSeparatorInset: CGFloat = 76
    
    var leftTurnIconDrawable: OATurnDrawable?
    
    func setLeftImageView(image: UIImage?) {
        leftImageView.image = image
        leftImageView.tintColor = .textColorPrimary
    }
    
    func setLeftTurnIconDrawable(drawable: OATurnDrawable) {
        leftTurnIconDrawable = drawable
    }
    
    func setTopLeftLabel(text: String?) {
        topLeftLabel.text = text
    }
    
    func setTopLeftLabel(font: UIFont) {
        topLeftLabel.font = font
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
            bottomImageBorderView.layer.borderColor = UIColor.iconColorDefault.cgColor
            bottomImageBorderViewWidthConstraint.constant = (image.size.width / (image.size.height / bottomImageViewInnerHeight)) + 16
        } else {
            bottomImageStackView.isHidden = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        separatorInset = UIEdgeInsets(top: 0, left: leftSeparatorInset + OAUtilities.getLeftMargin(), bottom: 0, right: 0)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            refreshLeftIcon()
            bottomImageBorderView.layer.borderColor = UIColor.iconColorDefault.cgColor
        }
    }
    
    private func refreshLeftIcon() {
        guard let leftTurnIconDrawable else { return }
        leftTurnIconDrawable.setNeedsDisplay()
        let recoloredImage = leftTurnIconDrawable.toUIImage()
        setLeftImageView(image: recoloredImage)
    }
}
