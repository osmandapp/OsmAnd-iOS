//
//  String+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii on 08.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
