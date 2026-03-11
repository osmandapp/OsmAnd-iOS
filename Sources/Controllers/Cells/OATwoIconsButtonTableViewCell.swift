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
    
    func secondLeftIconVisibility(show: Bool) {
        secondLeftIconView.isHidden = !show
        updateMargins()
    }
    
    func shouldUpdateMarginsForVisibleSecondLeftIcon() -> Bool {
        !secondLeftIconView.isHidden
    }
    
    func setSecondLeftIconSize(_ size: CGFloat) {
        for constraint in secondLeftIconView.constraints {
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                constraint.constant = size
            }
        }
    }
}
