//
//  FavoriteFolder.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 31.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

final class FavoriteFolder {
    private static let personalCategory = "personal"

    private let fullPath: String
    private let name: String

    private var subFolders: [FavoriteFolder] = []
    private var group: OAFavoriteFolderBridgeItem?
    private var subtreePointsCount = 0
    private var subtreeFileSize: Int64 = 0
    private var subtreeFoldersCount = 0
    private var subtreeLastModified: Int64 = 0

    private weak var parent: FavoriteFolder?

    init(fullPath: String, parent: FavoriteFolder?) {
        self.fullPath = fullPath
        self.name = FavoriteFolderPath.lastSegment(fullPath)
        self.parent = parent
    }

    func getFullPath() -> String {
        fullPath
    }

    func getName() -> String {
        name
    }

    func getParent() -> FavoriteFolder? {
        parent
    }

    func getGroup() -> OAFavoriteFolderBridgeItem? {
        group
    }

    func setGroup(_ group: OAFavoriteFolderBridgeItem?) {
        self.group = group
    }

    func isVirtual() -> Bool {
        group == nil
    }

    func isRoot() -> Bool {
        parent == nil
    }

    func getSubFolders() -> [FavoriteFolder] {
        subFolders
    }

    func addSubFolder(_ subFolder: FavoriteFolder) {
        subFolders.append(subFolder)
    }

    func sortSubFolders(using collator: (String, String) -> ComparisonResult) {
        subFolders.sort { lhs, rhs in
            if lhs.fullPath == Self.personalCategory {
                return true
            } else if rhs.fullPath == Self.personalCategory {
                return false
            }
            return collator(lhs.name, rhs.name) == .orderedAscending
        }

        for subFolder in subFolders {
            subFolder.sortSubFolders(using: collator)
        }
    }

    func updateSubtreeStats() {
        var pointsCount = getExactPointsCount()
        var fileSize = group?.fileSize ?? 0
        var foldersCount = subFolders.count
        var lastModified = group?.lastModifiedDate.map { Int64(($0.timeIntervalSince1970 * 1000.0).rounded()) } ?? 0
        for subFolder in subFolders {
            subFolder.updateSubtreeStats()
            pointsCount += subFolder.subtreePointsCount
            fileSize += subFolder.subtreeFileSize
            foldersCount += subFolder.subtreeFoldersCount
            lastModified = max(lastModified, subFolder.subtreeLastModified)
        }

        subtreePointsCount = pointsCount
        subtreeFileSize = fileSize
        subtreeFoldersCount = foldersCount
        subtreeLastModified = lastModified
    }

    func getExactPoints() -> [OAFavoritePointBridgeItem] {
        guard let group else { return [] }
        return OAFavoritesHelperBridge.shared().favoritePoints(forGroupName: group.groupName)
    }

    func getExactPointsCount() -> Int {
        Int(group?.pointsCount ?? 0)
    }

    func getSubtreePointsCount() -> Int {
        subtreePointsCount
    }

    func getSubtreeFileSize() -> Int64 {
        subtreeFileSize
    }

    func getSubtreeFoldersCount() -> Int {
        subtreeFoldersCount
    }

    func getSubtreeLastModified() -> Int64 {
        subtreeLastModified
    }
}

extension FavoriteFolder: Hashable {
    static func == (lhs: FavoriteFolder, rhs: FavoriteFolder) -> Bool {
        lhs === rhs || lhs.fullPath == rhs.fullPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fullPath)
    }
}
