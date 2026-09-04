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

    let fullPath: String
    let name: String
    var group: OAFavoriteFolderBridgeItem?

    private(set) var subFolders: [FavoriteFolder] = []
    private(set) var subtreePointsCount = 0
    private(set) var subtreeFileSize: Int64 = 0
    private(set) var subtreeFoldersCount = 0
    private(set) var subtreeLastModified: Int64 = 0
    private(set) weak var parent: FavoriteFolder?
    
    var isVirtual: Bool {
        group == nil
    }
    var isRoot: Bool {
        parent == nil
    }
    var exactPointsCount: Int {
        Int(group?.pointsCount ?? 0)
    }

    init(fullPath: String, parent: FavoriteFolder?) {
        self.fullPath = fullPath
        self.name = FavoriteFolderPath.lastSegment(fullPath)
        self.parent = parent
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
        var pointsCount = exactPointsCount
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

    func exactPoints() -> [OAFavoritePointBridgeItem] {
        guard let group else { return [] }
        return OAFavoritesHelperBridge.shared().favoritePoints(forGroupName: group.groupName)
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
