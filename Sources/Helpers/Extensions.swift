//
//  Extensions.swift
//  OsmAnd Maps
//
//  Created by Paul on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation


extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}
