//
//  FavoriteFolderProvider.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 31.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

// Builds and caches the folder tree out of the flat group list: every path segment becomes a folder, and one without its own group is virtual. Lives inside FavouritesHelper on Android.
final class FavoriteFolderProvider {
    private struct FavoriteFolderSnapshot {
        let root: FavoriteFolder
        let folders: [String: FavoriteFolder]
    }

    static let shared = FavoriteFolderProvider()

    private var favoriteFolderSnapshot: FavoriteFolderSnapshot?
    private var favoritesStorageObserver: NSObjectProtocol?

    init() {
        favoritesStorageObserver = NotificationCenter.default.addObserver(forName: Notification.Name("FavoritesStorageChangedNotification"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateFavoriteFolderCache()
        }
    }

    func favoriteFolderRoot() -> FavoriteFolder {
        ensureFavoriteFolderSnapshot().root
    }

    func favoriteFolder(_ fullPath: String) -> FavoriteFolder? {
        ensureFavoriteFolderSnapshot().folders[fullPath]
    }

    func favoriteRootFolders() -> [FavoriteFolder] {
        ensureFavoriteFolderSnapshot().root.subFolders
    }

    func flattenedFavoriteFolders(includeRoot: Bool) -> [FavoriteFolder] {
        var result: [FavoriteFolder] = []
        let root = ensureFavoriteFolderSnapshot().root
        if includeRoot {
            result.append(root)
        }

        for subFolder in root.subFolders {
            collectFlattenedFavoriteFolders(subFolder, result: &result)
        }

        return result
    }

    func favoriteGroupsInSubtree(_ fullPath: String) -> [OAFavoriteFolderBridgeItem] {
        favoriteFoldersInSubtree(fullPath).compactMap { $0.group }
    }

    private func invalidateFavoriteFolderCache() {
        favoriteFolderSnapshot = nil
    }

    private func ensureFavoriteFolderSnapshot() -> FavoriteFolderSnapshot {
        if let favoriteFolderSnapshot {
            return favoriteFolderSnapshot
        }

        let snapshot = buildFavoriteFolderSnapshot()
        favoriteFolderSnapshot = snapshot
        return snapshot
    }

    private func buildFavoriteFolderSnapshot() -> FavoriteFolderSnapshot {
        let root = FavoriteFolder(fullPath: "", parent: nil)
        var folders = [root.fullPath: root]
        for group in OAFavoritesHelperBridge.shared().favoriteFolders() {
            addFavoriteGroupToSnapshot(root, folders: &folders, group: group)
        }

        root.sortSubFolders { $0.localizedCaseInsensitiveCompare($1) }
        root.updateSubtreeStats()
        return FavoriteFolderSnapshot(root: root, folders: folders)
    }

    private func addFavoriteGroupToSnapshot(_ root: FavoriteFolder, folders: inout [String: FavoriteFolder], group: OAFavoriteFolderBridgeItem) {
        let fullPath = group.groupName
        if fullPath.isEmpty {
            root.group = group
            return
        }

        var parent = root
        var currentPath = ""
        for segment in FavoriteFolderPath.split(fullPath) {
            currentPath = currentPath.isEmpty ? segment : currentPath + FavoriteFolderPath.delimiter + segment
            if let folder = folders[currentPath] {
                parent = folder
            } else {
                let folder = FavoriteFolder(fullPath: currentPath, parent: parent)
                folders[currentPath] = folder
                parent.addSubFolder(folder)
                parent = folder
            }
        }

        parent.group = group
    }

    private func collectFlattenedFavoriteFolders(_ folder: FavoriteFolder, result: inout [FavoriteFolder]) {
        result.append(folder)
        for subFolder in folder.subFolders {
            collectFlattenedFavoriteFolders(subFolder, result: &result)
        }
    }

    private func favoriteFoldersInSubtree(_ fullPath: String) -> [FavoriteFolder] {
        var result: [FavoriteFolder] = []
        if let folder = favoriteFolder(fullPath) {
            collectFlattenedFavoriteFolders(folder, result: &result)
        }

        return result
    }

    deinit {
        if let favoritesStorageObserver {
            NotificationCenter.default.removeObserver(favoritesStorageObserver)
        }
    }
}
