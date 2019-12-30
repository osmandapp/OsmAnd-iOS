//
//  UIColor+RGB.swift
//  OsmAnd Maps
//
//  Created by Paul on 9/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

import UIKit

public extension UIColor {
    convenience init<T>(rgbValue: T, alpha: CGFloat = 1) where T: BinaryInteger {
        guard rgbValue > 0 else {
            self.init(red: 0, green: 0, blue: 0, alpha: alpha)
            return
        }
        
        guard rgbValue < 0xFFFFFF else {
            self.init(red: 1, green: 1, blue: 1, alpha: alpha)
            return
        }
        
        let r: CGFloat = CGFloat(CGFloat((rgbValue & 0xFF0000) >> 16) / 255)
        let g: CGFloat = CGFloat(CGFloat((rgbValue & 0x00FF00) >> 8) / 255)
        let b: CGFloat = CGFloat(CGFloat(rgbValue & 0x0000FF) / 255)
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    convenience init<T>(argbValue: T) where T: BinaryInteger {
        guard argbValue > 0 else {
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }
        
        guard argbValue < 0xFFFFFFFF else {
            self.init(red: 1, green: 1, blue: 1, alpha: 1)
            return
        }
        
        let r: CGFloat = CGFloat(CGFloat((argbValue & 0x00FF0000) >> 16) / 255)
        let g: CGFloat = CGFloat(CGFloat((argbValue & 0x0000FF00) >> 8) / 255)
        let b: CGFloat = CGFloat(CGFloat(argbValue & 0x000000FF) / 255)
        let alpha: CGFloat = CGFloat(CGFloat((argbValue & 0xFF000000) >> 24) / 255.0)
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
