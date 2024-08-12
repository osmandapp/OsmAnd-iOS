//
//  String+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii on 08.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension String {

    func trimWhitespaces() -> String {
        trimmingCharacters(in: .whitespaces)
    }

    func removePrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    func removeSufix(_ sufix: String) -> String {
        guard hasSuffix(sufix) else { return self }
        return String(dropLast(sufix.count))
    }
}
