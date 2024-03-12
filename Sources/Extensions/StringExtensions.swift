//
//  OAStringExtensions.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 12/03/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

/// Several extensions to String for character manipulation.
extension String {
    
    var length: Int {
        return self.count
    }
    
    subscript (i: Int) -> Character {
        let start = index(self.startIndex, offsetBy: i)
        return self[start]
    }
    
    func substring(from: Int) -> String {
        return self[min(from, length) ..< length]
    }
    
    func substring(to: Int) -> String {
        return self[0 ..< max(0, to)]
    }
    
    func substring(from: Int, to: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: from)
        let end = self.index(self.startIndex, offsetBy: to)
        let range = start..<end
        return String(self[range])
    }
    
    func containsCaseInsensitive(text: String) -> Bool {
        self.range(of: text, options: .caseInsensitive) != nil
    }
    
    subscript (r: Swift.Range<Int>) -> String {
        let lower = max(0, min(length, r.lowerBound))
        let upper = min(length, max(0, r.upperBound))
        let range = Swift.Range(uncheckedBounds: (lower: lower, upper: upper))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
    /// Returns index of the first instance of the string, or -1 if not found.
    func find(_ needle: String) -> Int {
        let range = self.range(of: needle)
        if range != nil {
            return self.distance(from: self.startIndex, to: range!.lowerBound)
        }
        return -1
    }
    
    /// Returns index of the last instance of the string, or -1 if not found.
    func rfind(_ needle: String) -> Int {
        let range = self.range(of: needle, options: String.CompareOptions.backwards)
        if range != nil {
            return self.distance(from: self.startIndex, to: range!.lowerBound)
        }
        return -1
    }
    
    func appendingPathComponent(_ str: String) -> String {
        (self as NSString).appendingPathComponent(str)
    }
    
    func appendingPathExtension(_ str: String) -> String {
        (self as NSString).appendingPathExtension(str) ?? self
    }
    
    func lastPathComponent() -> String {
        (self as NSString).lastPathComponent
    }
    
    func deletingPathExtension() -> String {
        (self as NSString).deletingPathExtension
    }
    
    func deletingLastPathComponent() -> String {
        (self as NSString).deletingLastPathComponent
    }
    
}
