//
//  UIScreen+Extension.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 31.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension UIScreen {
    // NOTE: Apple does not provide an API to obtain an accurate ppi value. The property returns ppi with a margin of error. For an exact ppi value, you need to refer to the device's specifications.
    @objc
    var ppi: CGFloat {
        let widthPixels = bounds.size.width * nativeScale
        let heightPixels = bounds.size.height * nativeScale
        let diagonalInches = sqrt(pow(widthPixels / nativeScale, 2) + pow(heightPixels / nativeScale, 2)) / 160.0
        let ppi = sqrt(pow(widthPixels, 2) + pow(heightPixels, 2)) / diagonalInches
        return ppi
    }
}
