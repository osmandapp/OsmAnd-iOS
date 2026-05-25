//
//  Constellation.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

final class Constellation: SkyObject {
    let lines: [(Int, Int)]

    var linePairs: [(String, String)] {
        lines.map { (String($0.0), String($0.1)) }
    }

    var rightAscension: Double {
        get { ra }
        set { ra = newValue }
    }

    var declination: Double {
        get { dec }
        set { dec = newValue }
    }

    init(name: String,
         wid: String,
         lines: [(Int, Int)],
         localizedName: String? = nil) {
        self.lines = lines
        super.init(id: "const_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
                   hip: -1,
                   catalogs: [],
                   wid: wid,
                   type: .CONSTELLATION,
                   body: nil,
                   name: name,
                   ra: 0,
                   dec: 0,
                   magnitude: 2,
                   color: .white,
                   localizedName: localizedName,
                   lineObjectIds: lines.flatMap { [String($0.0), String($0.1)] })
    }

    convenience init(id: String,
                     name: String,
                     centerWId: String?,
                     lineObjectIds: [String],
                     rightAscension: Double,
                     declination: Double) {
        var pairs: [(Int, Int)] = []
        var index = 0
        while index + 1 < lineObjectIds.count {
            if let first = Int(lineObjectIds[index]), let second = Int(lineObjectIds[index + 1]) {
                pairs.append((first, second))
            }
            index += 2
        }
        self.init(name: name, wid: centerWId ?? "", lines: pairs)
        self.ra = rightAscension
        self.dec = declination
    }
}
