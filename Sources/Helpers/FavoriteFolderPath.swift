//
//  FavoriteFolderPath.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 31.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

final class FavoriteFolderPath {
    static let delimiter = "/"
    private static let delimiterCharacter: Character = "/"

    static func split(_ fullPath: String?) -> [String] {
        guard let fullPath, !fullPath.isEmpty else { return [] }
        var segments: [String] = []
        var start = fullPath.startIndex
        while let delimiterIndex = fullPath[start...].firstIndex(of: delimiterCharacter) {
            addSegment(&segments, segment: String(fullPath[start..<delimiterIndex]))
            start = fullPath.index(after: delimiterIndex)
        }

        addSegment(&segments, segment: String(fullPath[start...]))
        return segments
    }

    static func join(_ segments: [String]) -> String {
        segments.filter { !$0.isEmpty }.joined(separator: delimiter)
    }

    static func parentPath(_ fullPath: String?) -> String {
        guard let fullPath, !fullPath.isEmpty else { return "" }
        let end = trimTrailingDelimiters(fullPath)
        guard end > fullPath.startIndex, let delimiterIndex = fullPath[..<end].lastIndex(of: delimiterCharacter) else { return "" }
        let parentPath = String(fullPath[..<delimiterIndex])
        return isNormalizedPath(parentPath) ? parentPath : join(split(parentPath))
    }

    static func lastSegment(_ fullPath: String?) -> String {
        guard let fullPath, !fullPath.isEmpty else { return "" }
        let end = trimTrailingDelimiters(fullPath)
        guard end > fullPath.startIndex else { return "" }
        let start = fullPath[..<end].lastIndex(of: delimiterCharacter).map { fullPath.index(after: $0) } ?? fullPath.startIndex
        return String(fullPath[start..<end])
    }

    static func isDescendantOrSelf(_ path: String?, ancestorPath: String?) -> Bool {
        let normalizedPath = path ?? ""
        let normalizedAncestor = ancestorPath ?? ""
        return normalizedAncestor.isEmpty || normalizedPath == normalizedAncestor || normalizedPath.hasPrefix(normalizedAncestor + delimiter)
    }

    static func replacePathPrefix(_ path: String, oldPrefix: String, newPrefix: String) -> String {
        guard isDescendantOrSelf(path, ancestorPath: oldPrefix) else { return path }
        guard path != oldPrefix else { return newPrefix }
        let suffix = oldPrefix.isEmpty ? path : String(path.dropFirst(oldPrefix.count + delimiter.count))
        return newPrefix.isEmpty ? suffix : newPrefix + delimiter + suffix
    }

    static func isValidFullPath(_ fullPath: String?) -> Bool {
        guard let fullPath else { return false }
        guard !fullPath.isEmpty else { return true }
        var start = fullPath.startIndex
        while let delimiterIndex = fullPath[start...].firstIndex(of: delimiterCharacter) {
            if !isValidSegment(String(fullPath[start..<delimiterIndex])) {
                return false
            }
            start = fullPath.index(after: delimiterIndex)
        }

        return isValidSegment(String(fullPath[start...]))
    }

    static func isValidSegment(_ segment: String?) -> Bool {
        guard let segment, !segment.isEmpty else { return false }
        return !segment.contains(delimiter) && !segment.contains(SUBFOLDER_PLACEHOLDER)
    }

    static func requireValidFullPath(_ fullPath: String) {
        precondition(isValidFullPath(fullPath), "Invalid favorite folder path: \(fullPath)")
    }

    private static func addSegment(_ segments: inout [String], segment: String) {
        if !segment.isEmpty {
            segments.append(segment)
        }
    }

    private static func trimTrailingDelimiters(_ fullPath: String) -> String.Index {
        var end = fullPath.endIndex
        while end > fullPath.startIndex {
            let previousIndex = fullPath.index(before: end)
            if fullPath[previousIndex] != delimiterCharacter {
                break
            }
            end = previousIndex
        }

        return end
    }

    private static func isNormalizedPath(_ fullPath: String) -> Bool {
        fullPath.isEmpty || (!fullPath.hasPrefix(delimiter) && !fullPath.hasSuffix(delimiter) && !fullPath.contains(delimiter + delimiter))
    }
}
