//
//  SharedLibExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 26.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension Array {
    func toKotlinArray<Item: AnyObject>() -> KotlinArray<Item> {
        return KotlinArray(size: Int32(self.count)) { (i: KotlinInt) in
            guard let item = self[i.intValue] as? Item else {
                 fatalError("Element at index \(i) cannot be cast to \(Item.self)")
             }
             return item
        }
    }
}
