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
}
