//
//  OATwoIconsButtonTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class OATwoIconsButtonTableViewCell: OAButtonTableViewCell {
    
    @IBOutlet weak var secondLeftIconView: UIImageView!
    @IBOutlet private weak var secondLeftIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var secondLeftIconHeightConstraint: NSLayoutConstraint!
    
    func secondLeftIconVisibility(show: Bool) {
        secondLeftIconView.isHidden = !show
        updateMargins()
    }
    
    func shouldUpdateMarginsForVisibleSecondLeftIcon() -> Bool {
        !secondLeftIconView.isHidden
    }
    
    func setSecondLeftIconSize(to size: CGFloat) {
        guard secondLeftIconWidthConstraint.constant != size || secondLeftIconHeightConstraint.constant != size else { return }
        secondLeftIconWidthConstraint.constant = size
        secondLeftIconHeightConstraint.constant = size
    }
}
