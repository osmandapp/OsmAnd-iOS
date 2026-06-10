//
//  MapDrawParams.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class MapDrawParams: NSObject {
    let density: Float
    let widthPixels: Int
    let heightPixels: Int

    init(density: Float, widthPixels: Int, heightPixels: Int) {
        self.density = density
        self.widthPixels = widthPixels
        self.heightPixels = heightPixels
    }

    static func importTrackPreviewParams(size: CGSize) -> MapDrawParams {
        MapDrawParams(density: Float(UIScreen.main.scale),
                      widthPixels: max(1, Int(size.width)),
                      heightPixels: max(1, Int(size.height)))
    }
}
