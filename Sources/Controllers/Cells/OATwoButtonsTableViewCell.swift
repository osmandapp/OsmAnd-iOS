//
//  TwoButtonsTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 02/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

class OATwoButtonsTableViewCell: OASimpleTableViewCell {
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    func buttonsVisibility(show: Bool) {
        leftButton.isHidden = !show
        rightButton.isHidden = !show
        updateMargins()
    }
    
    func checkSubviewsToUpdateMargins() -> Bool {
        return !leftButton.isHidden && !rightButton.isHidden
    }
    
}
