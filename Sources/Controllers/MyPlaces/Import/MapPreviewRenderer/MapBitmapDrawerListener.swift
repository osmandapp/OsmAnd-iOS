//
//  MapBitmapDrawerListener.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

protocol MapBitmapDrawerListener: AnyObject {
    func onBitmapDrawing()
    func onBitmapDrawn(_ success: Bool)
    func onBitmapDrawn(image: UIImage)
}

extension MapBitmapDrawerListener {
    func onBitmapDrawing() {}
    func onBitmapDrawn(_ success: Bool) {}
}
