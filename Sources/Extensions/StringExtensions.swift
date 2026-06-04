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
        self.count
    }
    
    subscript (i: Int) -> Character {
        let start = index(self.startIndex, offsetBy: i)
        return self[start]
    }
    
    func substring(from: Int) -> String {
        self[min(from, length) ..< length]
    }
    
    func substring(to: Int) -> String {
        self[0 ..< max(0, to)]
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

extension String {
    
    var isStartingWithRTLChar: Bool {
        guard let firstScalar = first?.unicodeScalars.first else {
            return false
        }

        let direction = NSLocale.characterDirection(
            forLanguage: String(firstScalar)
        )

        return direction == .rightToLeft
    }
}

extension NSString {

    /// Extracts valid URLs from the string.
    ///
    /// Commas, semicolons, spaces, and newlines are treated as separators.
    /// URLs without a scheme are normalized by prepending `https://`.
    ///
    /// - Returns: An array of normalized URL strings. Invalid URLs are ignored.
    ///
    /// Examples:
    /// ```swift
    /// "google.com, apple.com; https://osmand.net".extractValidURLs()
    /// // ["https://google.com", "https://apple.com", "https://osmand.net"]
    /// ```
    ///
    /// - Returns: An array of normalized URL strings. Invalid URLs are ignored.
    @objc func extractValidURLs() -> [String] {
        guard length > 0 else { return [] }

        let trimmedInput = trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInput.containsURLSeparator,
           let url = Self.normalizedURLString(from: trimmedInput) {
            return [url]
        }

        let normalized = replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ";", with: " ")

        return normalized
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { part in
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmed.isEmpty else { return nil }

                return Self.normalizedURLString(from: trimmed)
            }
    }

    private static func normalizedURLString(from value: String) -> String? {
        guard !value.isEmpty else { return nil }

        if value.range(of: "^[A-Za-z][A-Za-z0-9+.-]*:", options: .regularExpression) != nil {
            guard URL(string: value) != nil else { return nil }
            return value
        }

        let urlString = "https://\(value)"
        guard let components = URLComponents(string: urlString),
              let host = components.host,
              !host.isEmpty else {
            return nil
        }

        return urlString
    }
}

private extension String {
    var containsURLSeparator: Bool {
        rangeOfCharacter(from: CharacterSet(charactersIn: ",;").union(.whitespacesAndNewlines)) != nil
    }
}
