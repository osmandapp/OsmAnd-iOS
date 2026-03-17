//
//  Pair.swift
//  OsmAnd Maps
//
//  Created by Skalii on 20.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

struct Pair<T : Comparable, U : Comparable> : Hashable where T : Hashable, U : Hashable {
    let first: T
    let second: U

    init(_ first: T, _ second: U) {
        self.first = first
        self.second = second
    }
}

@objcMembers
final class NullablePair: NSObject {
    let first: Any?
    let second: Any?

    init(_ first: Any?, _ second: Any?) {
        self.first = first
        self.second = second
    }
}
