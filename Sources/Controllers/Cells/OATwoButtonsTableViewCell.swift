//
//  TwoButtonsTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 02/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class OATwoButtonsTableViewCell: OASimpleTableViewCell {
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    func buttonsVisibility(show: Bool) {
        leftButton.isHidden = !show
        rightButton.isHidden = !show
        updateMargins()
    }
    
    func setLeftButtonVisible(_ visible: Bool) {
        leftButton.isHidden = !visible
        updateMargins()
    }
    
    func setRightButtonVisible(_ visible: Bool) {
        rightButton.isHidden = !visible
        updateMargins()
    }
    
    func shouldUpdateMarginsForVisibleButtons() -> Bool {
        !leftButton.isHidden && !rightButton.isHidden
    }
}
