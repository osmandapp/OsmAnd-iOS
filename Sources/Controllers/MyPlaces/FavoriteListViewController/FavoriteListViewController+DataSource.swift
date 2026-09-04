//
//  FavoriteListViewController+DataSource.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

extension FavoriteListViewController {
    func favoriteSortMode(entryId: String? = nil) -> FavoriteSortMode {
        let sortModes = settings.getFavoriteSortModes()
        guard let sortModeValue = sortModes[entryId ?? currentSortEntryId] else { return FavoriteSortModeHelper.defaultSortMode() }
        return FavoriteSortMode(rawValue: sortModeValue) ?? FavoriteSortModeHelper.defaultSortMode()
    }

    func searchFavoriteSortMode() -> FavoriteSortMode {
        let sortModeValue = settings.searchFavoriteSortMode.get()
        return FavoriteSortMode(rawValue: sortModeValue) ?? FavoriteSortModeHelper.defaultSortMode()
    }
    
    func clearFavoriteSortModes(forGroupNames groupNames: [String]) {
        var sortModes = settings.getFavoriteSortModes()
        let keysToRemove = sortModes.keys.filter { key in
            groupNames.contains { groupName in
                isFavoriteSortModeKey(key, insideOrEqualTo: groupName)
            }
        }

        guard !keysToRemove.isEmpty else { return }
        keysToRemove.forEach { sortModes.removeValue(forKey: $0) }
        settings.saveFavoriteSortModes(sortModes)
    }

    func renameFavoriteSortModeKeys(from oldGroupName: String, to newGroupName: String) {
        guard !oldGroupName.isEmpty, oldGroupName != newGroupName else { return }
        var sortModes = settings.getFavoriteSortModes()
        let keysToRename = sortModes.keys.filter { isFavoriteSortModeKey($0, insideOrEqualTo: oldGroupName) }
        guard !keysToRename.isEmpty else { return }
        for key in keysToRename {
            if let value = sortModes.removeValue(forKey: key) {
                sortModes[newGroupName + String(key.dropFirst(oldGroupName.count))] = value
            }
        }

        settings.saveFavoriteSortModes(sortModes)
    }

    func updateFavoriteSortModeKeysAfterMove(_ favoriteItems: [Any], toGroupName targetGroupName: String) {
        let folderPaths = favoriteItems.compactMap { $0 as? String }.filter { !$0.isEmpty }
        let topLevelFolderPaths = folderPaths.filter { path in
            !folderPaths.contains { $0 != path && FavoriteFolderPath.isDescendantOrSelf(path, ancestorPath: $0) }
        }
        for oldGroupName in topLevelFolderPaths {
            let folderName = FavoriteFolderPath.lastSegment(oldGroupName)
            let newGroupName = targetGroupName.isEmpty ? folderName : "\(targetGroupName)/\(folderName)"
            renameFavoriteSortModeKeys(from: oldGroupName, to: newGroupName)
        }
    }
    
    func makeSortMenu(includesDistanceSortModes: Bool) -> UIMenu {
        let modes: [FavoriteSortMode] = includesDistanceSortModes ? FavoriteSortMode.allCases : [.lastModified, .nameAZ, .nameZA, .newestDateFirst, .oldestDateFirst]
        let groups: [[FavoriteSortMode]] = [[.lastModified], [.nearestToCurrentLocation, .nearestToMapCenter], [.nameAZ, .nameZA], [.newestDateFirst, .oldestDateFirst]]
        let sections = groups.compactMap { group -> UIMenu? in
            let actions = group.filter { modes.contains($0) }.map { makeSortAction(for: $0) }
            return actions.isEmpty ? nil : UIMenu(options: .displayInline, children: actions)
        }

        return UIMenu(title: "", children: sections)
    }
    
    func makeDataSource() -> DataSource {
        let sortHeaderCellRegistration = sortHeaderCellRegistration
        let backupBannerCellRegistration = backupBannerCellRegistration
        let folderCellRegistration = folderCellRegistration
        let favoriteCellRegistration = favoriteCellRegistration
        let headerCellRegistration = headerCellRegistration
        let statsFooterCellRegistration = statsFooterCellRegistration
        let emptyStateCellRegistration = emptyStateCellRegistration
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .sortHeader(let sortHeader):
                return collectionView.dequeueConfiguredReusableCell(using: sortHeaderCellRegistration, for: indexPath, item: sortHeader)
            case .backupBanner:
                return collectionView.dequeueConfiguredReusableCell(using: backupBannerCellRegistration, for: indexPath, item: item)
            case .header(let section):
                return collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: section)
            case .folder(let folder):
                return collectionView.dequeueConfiguredReusableCell(using: folderCellRegistration, for: indexPath, item: folder)
            case .favorite(let favorite):
                return collectionView.dequeueConfiguredReusableCell(using: favoriteCellRegistration, for: indexPath, item: favorite)
            case .statsFooter(let stats):
                return collectionView.dequeueConfiguredReusableCell(using: statsFooterCellRegistration, for: indexPath, item: stats)
            case .emptyState:
                return collectionView.dequeueConfiguredReusableCell(using: emptyStateCellRegistration, for: indexPath, item: ())
            }
        }
        dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] item in
            guard let self else { return }
            if case .header(let section) = item {
                self.collapsedRootSections.remove(section)
                self.saveCollapsedSections()
            }

            guard self.collectionView.isEditing else { return }
            self.collectionView.indexPathsForVisibleItems.forEach { self.updateVisibleSelectionState(at: $0) }
        }
        dataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] item in
            guard let self, case .header(let section) = item else { return }
            self.collapsedRootSections.insert(section)
            self.saveCollapsedSections()
        }
        return dataSource
    }

    func applySnapshot(animatingDifferences: Bool = false) {
        if isContextMenuVisible {
            shouldReloadCollectionView = true
            return
        }

        switch screenMode {
        case .root:
            applyRootSnapshot(animatingDifferences: false)
        case .folder(let fullPath, _):
            applyFolderSnapshot(fullPath: fullPath, animatingDifferences: false)
        }
    }
    
    func closeFreeBackupBanner() {
        UserDefaults.standard.set(true, forKey: Self.wasClosedFreeBackupFavoritesBannerKey)
        applySnapshot(animatingDifferences: true)
    }
    
    func hasSearchResults() -> Bool {
        layoutSections.contains(.content)
    }

    func shouldHideSearchToolbar() -> Bool {
        !collectionView.isEditing && (!isSearchActive || !hasSearchResults())
    }
    
    func clearSearchControllerText() {
        if isRootFolder {
            navigationController?.navigationBar.topItem?.searchController?.searchBar.text = ""
        } else {
            subfolderSearchController.searchBar.text = ""
        }
    }

    func favoritePointRows(_ items: [OAFavoritePointBridgeItem], sortMode: FavoriteSortMode? = nil) -> [FavoritePointRow] {
        let sortMode = sortMode ?? currentSortMode
        if sortMode.isMapCenterDistanceOriented {
            let mapViewController = OARootViewController.instance().mapPanel.mapViewController
            let mapAzimuth = Double(mapViewController.azimuth())
            items.forEach { $0.updateDistanceAndDirection(fromMapCenter: mapViewController.getMapLocation().coordinate, mapAzimuth: mapAzimuth) }
        } else if sortMode.isCurrentLocationDistanceOriented {
            items.forEach { $0.updateDistanceAndDirection() }
        }

        return items.map { FavoritePointRow(item: $0) }
    }

    private func setFavoriteSortMode(_ sortMode: FavoriteSortMode) {
        guard currentSortMode != sortMode else { return }

        if isSearchResultsMode {
            settings.searchFavoriteSortMode.set(sortMode.rawValue)
        } else {
            var sortModes = settings.getFavoriteSortModes()
            sortModes[currentSortEntryId] = sortMode.rawValue
            settings.saveFavoriteSortModes(sortModes)
        }

        cachedSearchFavoriteItems = nil
        applySnapshot(animatingDifferences: false)
    }
    
    private func isFavoriteSortModeKey(_ key: String, insideOrEqualTo groupName: String) -> Bool {
        key == groupName || (!groupName.isEmpty && key.hasPrefix(groupName + FavoriteFolderPath.delimiter))
    }
    
    private func makeSortAction(for sortMode: FavoriteSortMode) -> UIAction {
        UIAction(title: sortMode.title, image: sortMode.image, state: currentSortMode == sortMode ? .on : .off) { [weak self] _ in
            self?.setFavoriteSortMode(sortMode)
        }
    }
    
    private func updateLayoutSections(_ sections: [FavoriteListSection]) {
        guard layoutSections != sections else { return }
        layoutSections = sections
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func applyRootSnapshot(animatingDifferences: Bool) {
        let rootFolder = FavoriteFolderProvider.shared.favoriteFolderRoot()
        if isSearchResultsMode {
            applySearchSnapshot(parentFullPath: nil, animatingDifferences: animatingDifferences)
            return
        }

        var rootFolders = rootFolder.subFolders
        if rootFolder.group != nil {
            rootFolders.insert(rootFolder, at: 0)
        }

        let folders = rootFolders.map { FavoriteFolderRow(folder: $0) }
        if folders.isEmpty {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }

        var snapshot = Snapshot()
        let foldersBySection = favoriteFoldersBySection(folders: folders).mapValues { FavoriteSortModeHelper.sortFoldersWithMode($0, mode: currentSortMode) }
        let folderSections = rootSections(foldersBySection: foldersBySection)
        let isPaymentBannerVisible = isAvailablePaymentBanner
        let stats = folderStats(folder: rootFolder)
        var sections: [FavoriteListSection] = [.sortHeader]
        if isPaymentBannerVisible {
            sections.append(.backupBanner)
        }

        sections.append(contentsOf: folderSections.map { FavoriteListSection.folderSection($0) })
        if stats != nil {
            sections.append(.statsFooter)
        }

        updateLayoutSections(sections)
        snapshot.appendSections(sections)
        snapshot.appendItems([.sortHeader(currentSortHeader)], toSection: .sortHeader)
        if isPaymentBannerVisible {
            snapshot.appendItems([.backupBanner], toSection: .backupBanner)
        }

        if let stats {
            snapshot.appendItems([.statsFooter(stats)], toSection: .statsFooter)
        }

        applyDataSourceSnapshot(snapshot, animatingDifferences: animatingDifferences)
        for section in folderSections {
            let headerItem = FavoriteListItem.header(section)
            let folderItems = (foldersBySection[section] ?? []).map(FavoriteListItem.folder)
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<FavoriteListItem>()
            sectionSnapshot.append([headerItem])
            sectionSnapshot.append(folderItems, to: headerItem)
            if !collapsedRootSections.contains(section) {
                sectionSnapshot.expand([headerItem])
            }
            dataSource.apply(sectionSnapshot, to: .folderSection(section), animatingDifferences: animatingDifferences)
        }
    }

    private func applyFolderSnapshot(fullPath: String, animatingDifferences: Bool) {
        guard let folder = FavoriteFolderProvider.shared.favoriteFolder(fullPath) else {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }

        if isSearchResultsMode {
            applySearchSnapshot(parentFullPath: fullPath, animatingDifferences: animatingDifferences)
            return
        }

        let subFolders = FavoriteSortModeHelper.sortFoldersWithMode((folder.isRoot ? [] : folder.subFolders).map { FavoriteFolderRow(folder: $0) }.filter { matchesSearch($0.title) }, mode: currentSortMode)
        let favorites = FavoriteSortModeHelper.sortFavoritePointsWithMode(favoritePointRows(folder.exactPoints(), sortMode: currentSortMode).filter { matchesSearch($0.title) || matchesSearch($0.bridgeItem.address) }, mode: currentSortMode)
        if favorites.isEmpty && subFolders.isEmpty {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }
        var snapshot = Snapshot()
        let stats = folderStats(folder: folder, exactRoot: folder.isRoot)
        let sections: [FavoriteListSection] = stats == nil ? [.sortHeader, .content] : [.sortHeader, .content, .statsFooter]
        updateLayoutSections(sections)
        snapshot.appendSections(sections)
        snapshot.appendItems([.sortHeader(currentSortHeader)], toSection: .sortHeader)
        snapshot.appendItems(subFolders.map(FavoriteListItem.folder), toSection: .content)
        snapshot.appendItems(favorites.map(FavoriteListItem.favorite), toSection: .content)
        if let stats {
            snapshot.appendItems([.statsFooter(stats)], toSection: .statsFooter)
        }

        applyDataSourceSnapshot(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func applySearchSnapshot(parentFullPath: String?, animatingDifferences: Bool) {
        let favorites = FavoriteSortModeHelper.sortFavoritePointsWithMode(searchFavoritePointRows(parentFullPath: parentFullPath), mode: currentSortMode)
        if favorites.isEmpty {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }

        var snapshot = Snapshot()
        let sections: [FavoriteListSection] = [.sortHeader, .content]
        updateLayoutSections(sections)
        snapshot.appendSections(sections)
        snapshot.appendItems([.sortHeader(currentSortHeader)], toSection: .sortHeader)
        let favoriteItems = favorites.map(FavoriteListItem.favorite)
        snapshot.appendItems(favoriteItems, toSection: .content)
        applyDataSourceSnapshot(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func applyEmptyStateSnapshot(animatingDifferences: Bool) {
        var snapshot = Snapshot()
        let sections: [FavoriteListSection] = [.emptyState]
        updateLayoutSections(sections)
        snapshot.appendSections(sections)
        snapshot.appendItems([.emptyState])
        applyDataSourceSnapshot(snapshot, animatingDifferences: animatingDifferences)
    }

    private func applyDataSourceSnapshot(_ newSnapshot: Snapshot, animatingDifferences: Bool) {
        var snapshot = dataSource.snapshot()
        guard !snapshot.sectionIdentifiers.isEmpty else {
            dataSource.apply(newSnapshot, animatingDifferences: animatingDifferences)
            return
        }

        let currentSections = snapshot.sectionIdentifiers
        let currentItems = snapshot.itemIdentifiers
        if hasDuplicatePatchIdentifiers(in: snapshot) || hasDuplicatePatchIdentifiers(in: newSnapshot) {
            dataSource.apply(newSnapshot, animatingDifferences: animatingDifferences)
            return
        }

        patchSections(in: &snapshot, with: newSnapshot)
        patchItems(in: &snapshot, with: newSnapshot)
        guard snapshot.sectionIdentifiers != currentSections || snapshot.itemIdentifiers != currentItems else {
            return
        }

        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func hasDuplicatePatchIdentifiers(in snapshot: Snapshot) -> Bool {
        for section in snapshot.sectionIdentifiers where !section.isFolder {
            var identifiers = Set<FavoriteListItemPatchIdentifier>()
            for item in snapshot.itemIdentifiers(inSection: section) where !identifiers.insert(item.patchIdentifier).inserted {
                return true
            }
        }

        return false
    }

    private func patchSections(in snapshot: inout Snapshot, with newSnapshot: Snapshot) {
        let newSections = newSnapshot.sectionIdentifiers
        let newSectionSet = Set(newSections)
        let sectionsToDelete = snapshot.sectionIdentifiers.filter { !newSectionSet.contains($0) }
        if !sectionsToDelete.isEmpty {
            snapshot.deleteSections(sectionsToDelete)
        }

        for section in newSections where !snapshot.sectionIdentifiers.contains(section) {
            insertSection(section, in: &snapshot, matching: newSections)
        }
    }

    private func patchItems(in snapshot: inout Snapshot, with newSnapshot: Snapshot) {
        let sections = newSnapshot.sectionIdentifiers.filter { snapshot.sectionIdentifiers.contains($0) && !$0.isFolder }
        if isSearchResultsMode || isCancellingSearch {
            let currentItems = sections.flatMap { snapshot.itemIdentifiers(inSection: $0) }
            if !currentItems.isEmpty {
                snapshot.deleteItems(currentItems)
            }
            sections.forEach { snapshot.appendItems(newSnapshot.itemIdentifiers(inSection: $0), toSection: $0) }
            return
        }

        sections.forEach { patchItems(in: $0, snapshot: &snapshot, with: newSnapshot) }
    }

    private func patchItems(in section: FavoriteListSection, snapshot: inout Snapshot, with newSnapshot: Snapshot) {
        let targetItems = newSnapshot.itemIdentifiers(inSection: section)
        if snapshot.itemIdentifiers(inSection: section).isEmpty {
            snapshot.appendItems(targetItems, toSection: section)
            return
        }

        let targetIdentifiers = Set(targetItems.map(\.patchIdentifier))
        var itemsByIdentifier = Dictionary(uniqueKeysWithValues: snapshot.itemIdentifiers(inSection: section).map { ($0.patchIdentifier, $0) })
        let itemsToDelete = snapshot.itemIdentifiers(inSection: section).filter { !targetIdentifiers.contains($0.patchIdentifier) }
        if !itemsToDelete.isEmpty {
            snapshot.deleteItems(itemsToDelete)
            itemsToDelete.forEach { itemsByIdentifier[$0.patchIdentifier] = nil }
        }

        var previousItem: FavoriteListItem?
        for targetItem in targetItems {
            if let currentItem = itemsByIdentifier[targetItem.patchIdentifier] {
                if currentItem != targetItem {
                    updateItem(currentItem, with: targetItem, after: previousItem, in: section, snapshot: &snapshot)
                    itemsByIdentifier[targetItem.patchIdentifier] = targetItem
                    previousItem = targetItem
                } else {
                    previousItem = currentItem
                }
            } else {
                insertItem(targetItem, after: previousItem, in: section, snapshot: &snapshot)
                itemsByIdentifier[targetItem.patchIdentifier] = targetItem
                previousItem = targetItem
            }
        }
    }

    private func insertSection(_ section: FavoriteListSection, in snapshot: inout Snapshot, matching targetSections: [FavoriteListSection]) {
        guard let targetIndex = targetSections.firstIndex(of: section) else { return }
        if let nextSection = targetSections.dropFirst(targetIndex + 1).first(where: { snapshot.sectionIdentifiers.contains($0) }) {
            snapshot.insertSections([section], beforeSection: nextSection)
        } else if let previousSection = targetSections.prefix(targetIndex).reversed().first(where: { snapshot.sectionIdentifiers.contains($0) }) {
            snapshot.insertSections([section], afterSection: previousSection)
        } else {
            snapshot.appendSections([section])
        }
    }

    private func insertItem(_ item: FavoriteListItem, after previousItem: FavoriteListItem?, in section: FavoriteListSection, snapshot: inout Snapshot) {
        if let previousItem {
            snapshot.insertItems([item], afterItem: previousItem)
        } else if let firstItem = snapshot.itemIdentifiers(inSection: section).first {
            snapshot.insertItems([item], beforeItem: firstItem)
        } else {
            snapshot.appendItems([item], toSection: section)
        }
    }

    private func updateItem(_ item: FavoriteListItem, with newItem: FavoriteListItem, after previousItem: FavoriteListItem?, in section: FavoriteListSection, snapshot: inout Snapshot) {
        snapshot.deleteItems([item])
        insertItem(newItem, after: previousItem, in: section, snapshot: &snapshot)
    }

    private func favoriteFoldersBySection(folders allFolders: [FavoriteFolderRow]) -> [FavoriteFolderSection: [FavoriteFolderRow]] {
        let folders = allFolders.filter { matchesSearch($0.title) }
        return [.pinned: folders.filter { $0.isPinned }, .visible: folders.filter { $0.isVisible && !$0.isPinned }, .hidden: folders.filter { !$0.isVisible && !$0.isPinned }]
    }

    private func rootSections(foldersBySection: [FavoriteFolderSection: [FavoriteFolderRow]]) -> [FavoriteFolderSection] {
        var sections: [FavoriteFolderSection] = []
        if !(foldersBySection[.pinned] ?? []).isEmpty {
            sections.append(.pinned)
        }

        if !isSearchResultsMode || !(foldersBySection[.visible] ?? []).isEmpty {
            sections.append(.visible)
        }

        if !(foldersBySection[.hidden] ?? []).isEmpty {
            sections.append(.hidden)
        }

        return sections
    }

    private func folderStats(folder: FavoriteFolder, exactRoot: Bool = false) -> FavoriteFolderStats? {
        guard !isSearchResultsMode else { return nil }
        if exactRoot {
            let pointsCount = folder.exactPointsCount
            guard pointsCount > 0 else { return nil }
            return FavoriteFolderStats(foldersCount: 0, pointsCount: pointsCount, fileSize: folder.group?.fileSize ?? 0)
        }

        let pointsCount = folder.subtreePointsCount
        let foldersCount = folder.subtreeFoldersCount
        guard folder.group != nil || foldersCount > 0 || pointsCount > 0 else { return nil }
        return FavoriteFolderStats(foldersCount: foldersCount, pointsCount: pointsCount, fileSize: folder.subtreeFileSize)
    }
    
    private func matchesSearch(_ text: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return text?.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale.current) != nil
    }

    private func searchFavoritePointRows(parentFullPath: String?) -> [FavoritePointRow] {
        let favoriteRows: [FavoritePointRow]
        if let cachedSearchFavoriteItems {
            favoriteRows = favoritePointRows(cachedSearchFavoriteItems)
        } else {
            if let parentFullPath {
                favoriteRows = favoritePointRows(inFolder: parentFullPath)
            } else {
                let groups = FavoriteFolderProvider.shared.flattenedFavoriteFolders(includeRoot: true).compactMap { $0.group }
                let points = groups.flatMap { OAFavoritesHelperBridge.shared().favoritePoints(forGroupName: $0.groupName) }
                favoriteRows = favoritePointRows(points)
            }
            cachedSearchFavoriteItems = favoriteRows.map { $0.bridgeItem }
        }
        return favoriteRows.filter { matchesSearch($0.title) || matchesSearch($0.bridgeItem.address) }
    }

    private func saveCollapsedSections() {
        OAFavoritesHelperBridge.shared().updateCollapsedSections(collapsedRootSections.map(\.rawValue))
    }
}
