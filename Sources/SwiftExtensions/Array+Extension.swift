//
//  Array+Extension.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
