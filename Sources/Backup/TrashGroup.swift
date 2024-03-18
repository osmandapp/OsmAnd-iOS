//
//  TrashGroup.swift
//  OsmAnd Maps
//
//  Created by Skalii on 29.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATrashGroup)
@objcMembers
final class TrashGroup: NSObject {

    let name: String
    private var items = [TrashItem]()

    init(name: String) {
        self.name = name
    }

    func getItems() -> [TrashItem] {
        items
    }

    func addItem(item: TrashItem) {
        items.append(item)
    }
}
