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
                   localizedName: localizedName)
    }
}
