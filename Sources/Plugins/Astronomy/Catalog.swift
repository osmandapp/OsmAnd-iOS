//
//  Catalog.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

final class Catalog: NSObject {
    let wid: String
    let name: String
    let catalogId: String

    var catalogWid: String { wid }
    var catalogName: String { name }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(wid)
        hasher.combine(name)
        hasher.combine(catalogId)
        return hasher.finalize()
    }

    init(wid: String, name: String, catalogId: String) {
        self.wid = wid
        self.name = name
        self.catalogId = catalogId
        super.init()
    }

    convenience init(catalogWid: String, catalogName: String, catalogId: String) {
        self.init(wid: catalogWid, name: catalogName, catalogId: catalogId)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Catalog else {
            return false
        }
        return wid == other.wid && name == other.name && catalogId == other.catalogId
    }
}
