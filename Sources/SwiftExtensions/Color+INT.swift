//
//  Color+INT.swift
//  OsmAnd Maps
//
//  Created by Paul on 18.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension UIColor {
    convenience init(rgb: Int) {
        let red = CGFloat((rgb >> 16) & 0xFF)
        let green = CGFloat((rgb >> 8) & 0xFF)
        let blue = CGFloat(rgb & 0xFF)
        
        let normalizedRed = red / 255.0
        let normalizedGreen = green / 255.0
        let normalizedBlue = blue / 255.0
        
        self.init(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: 1.0)
    }
    
    convenience init(rgb: Int32) {
        let red = CGFloat((rgb >> 16) & 0xFF)
        let green = CGFloat((rgb >> 8) & 0xFF)
        let blue = CGFloat(rgb & 0xFF)
        
        let normalizedRed = red / 255.0
        let normalizedGreen = green / 255.0
        let normalizedBlue = blue / 255.0
        
        self.init(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: 1.0)
    }
    
    convenience init(argb: Int) {
        let alpha = CGFloat((argb >> 24) & 0xFF)
        let red = CGFloat((argb >> 16) & 0xFF)
        let green = CGFloat((argb >> 8) & 0xFF)
        let blue = CGFloat(argb & 0xFF)
        
        let normalizedAlpha = alpha / 255.0
        let normalizedRed = red / 255.0
        let normalizedGreen = green / 255.0
        let normalizedBlue = blue / 255.0
        
        self.init(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: normalizedAlpha)
    }
    
    convenience init(rgba: Int) {
        let red = CGFloat((rgba >> 24) & 0xFF)
        let green = CGFloat((rgba >> 16) & 0xFF)
        let blue = CGFloat((rgba >> 8) & 0xFF)
        let alpha = CGFloat(rgba & 0xFF)
        
        let normalizedRed = red / 255.0
        let normalizedGreen = green / 255.0
        let normalizedBlue = blue / 255.0
        let normalizedAlpha = alpha / 255.0
        
        self.init(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: normalizedAlpha)
    }
}
