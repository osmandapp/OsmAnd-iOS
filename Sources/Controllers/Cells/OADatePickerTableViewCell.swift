//
//  OADatePickerTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 27.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class OADatePickerTableViewCell: OASimpleTableViewCell {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    func getDate() -> Date {
        datePicker.date
    }
}
