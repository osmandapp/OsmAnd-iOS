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
        guard let sortModeTitle = sortModes[entryId ?? currentSortEntryId] else { return FavoriteSortModeHelper.defaultSortMode() }
        return FavoriteSortMode.byTitle(sortModeTitle)
    }

    func searchFavoriteSortMode() -> FavoriteSortMode {
        let sortModeTitle = settings.searchFavoriteSortMode.get()
        return FavoriteSortMode.byTitle(sortModeTitle)
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

    func renameFavoriteSortModeKeys(from oldGroupName: String, to newGroupName: String, existingGroupNames: Set<String>? = nil) {
        guard !oldGroupName.isEmpty, oldGroupName != newGroupName else { return }
        let groupNames = existingGroupNames ?? Set(OAFavoritesBridgeHelper.favoriteFolders().map { $0.groupName })
        guard !groupNames.contains(oldGroupName), groupNames.contains(newGroupName) else { return }
        var sortModes = settings.getFavoriteSortModes()
        let keysToRename = sortModes.keys.filter { isFavoriteSortModeKey($0, insideOrEqualTo: oldGroupName) }
        guard !keysToRename.isEmpty else { return }
        keysToRename.forEach { key in
            if let value = sortModes.removeValue(forKey: key) {
                sortModes[newGroupName + String(key.dropFirst(oldGroupName.count))] = value
            }
        }

        settings.saveFavoriteSortModes(sortModes)
    }

    func updateFavoriteSortModeKeysAfterMove(_ favoriteItems: [Any], toGroupName targetGroupName: String) {
        let groupNames = Set(OAFavoritesBridgeHelper.favoriteFolders().map { $0.groupName })
        favoriteItems.compactMap { $0 as? OAFavoriteFolderBridgeItem }.forEach { folder in
            let oldGroupName = folder.groupName
            let folderName = oldGroupName.split(separator: "/").last.map(String.init) ?? oldGroupName
            let newGroupName = targetGroupName.isEmpty ? folderName : "\(targetGroupName)/\(folderName)"
            renameFavoriteSortModeKeys(from: oldGroupName, to: newGroupName, existingGroupNames: groupNames)
        }
    }

    func createFavoriteMoveTargetGroupIfNeeded(_ groupName: String, favoriteItems: [Any]) {
        let folders = favoriteItems.compactMap { $0 as? OAFavoriteFolderBridgeItem }
        guard !folders.isEmpty, !folders.contains(where: { isFavoriteSortModeKey(groupName, insideOrEqualTo: $0.groupName) }) else { return }
        var existingGroupNames = Set(OAFavoritesBridgeHelper.favoriteFolders().map { $0.groupName })
        var parentGroupName = ""
        for folderName in groupName.split(separator: "/").map(String.init) {
            let newGroupName = parentGroupName.isEmpty ? folderName : "\(parentGroupName)/\(folderName)"
            if !existingGroupNames.contains(newGroupName), OAFavoritesBridgeHelper.addFavoriteGroup(folderName, parentGroupName: parentGroupName.isEmpty ? nil : parentGroupName, iconName: nil, color: nil, backgroundIconName: nil) {
                existingGroupNames.insert(newGroupName)
            }
            parentGroupName = newGroupName
        }
    }
    
    func makeSortMenu(includesDistanceSortModes: Bool) -> UIMenu {
        let modes: [FavoriteSortMode] = includesDistanceSortModes ? FavoriteSortMode.allCases : [.lastModified, .nameAZ, .nameZA, .newestDateFirst, .oldestDateFirst]
        let groups: [[FavoriteSortMode]] = [[.lastModified], [.nameAZ, .nameZA], [.newestDateFirst, .oldestDateFirst], [.nearest, .farthest]]
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
        dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] _ in
            guard let self, self.collectionView.isEditing else { return }
            self.collectionView.indexPathsForVisibleItems.forEach { self.updateVisibleSelectionState(at: $0) }
        }
        return dataSource
    }

    func applySnapshot(animatingDifferences: Bool = false) {
        switch screenMode {
        case .root:
            applyRootSnapshot(animatingDifferences: animatingDifferences)
        case .folder(let folder, _):
            applyFolderSnapshot(folder: folder, animatingDifferences: animatingDifferences)
        }
    }
    
    func closeFreeBackupBanner() {
        UserDefaults.standard.set(true, forKey: Self.wasClosedFreeBackupFavoritesBannerKey)
        applySnapshot(animatingDifferences: true)
    }
    
    func favoriteFolders() -> [FavoriteFolderRow] {
        OAFavoritesBridgeHelper.favoriteFolders().map { FavoriteFolderRow(item: $0) }
    }
    
    func isNestedFolder(_ groupName: String, in parentGroupName: String) -> Bool {
        guard !parentGroupName.isEmpty else { return false }
        return groupName.hasPrefix(parentGroupName + "/")
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
    
    private func setFavoriteSortMode(_ sortMode: FavoriteSortMode) {
        if isSearchResultsMode {
            settings.searchFavoriteSortMode.set(sortMode.title)
        } else {
            var sortModes = settings.getFavoriteSortModes()
            sortModes[currentSortEntryId] = sortMode.title
            settings.saveFavoriteSortModes(sortModes)
        }

        applySnapshot(animatingDifferences: false)
    }
    
    private func isFavoriteSortModeKey(_ key: String, insideOrEqualTo groupName: String) -> Bool {
        key == groupName || (!groupName.isEmpty && key.hasPrefix(groupName + "/"))
    }
    
    private func makeSortAction(for sortMode: FavoriteSortMode) -> UIAction {
        UIAction(title: sortMode.title, image: sortMode.image, state: currentSortMode == sortMode ? .on : .off) { [weak self] _ in
            self?.setFavoriteSortMode(sortMode)
        }
    }
    
    private func applyRootSnapshot(animatingDifferences: Bool) {
        let allFolders = favoriteFolders()
        if isSearchResultsMode {
            applySearchSnapshot(allFolders: allFolders, parentGroupName: nil, animatingDifferences: animatingDifferences)
            return
        }

        if allFolders.isEmpty {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }

        var snapshot = Snapshot()
        let foldersBySection = favoriteFoldersBySection(folders: allFolders).mapValues { FavoriteSortModeHelper.sortFoldersWithMode($0, mode: currentSortMode) }
        let folderSections = rootSections(foldersBySection: foldersBySection)
        let isPaymentBannerVisible = isAvailablePaymentBanner
        let stats = folderStats(allFolders: allFolders, currentGroupName: nil)
        var sections: [FavoriteListSection] = [.sortHeader]
        if isPaymentBannerVisible {
            sections.append(.backupBanner)
        }

        sections.append(contentsOf: folderSections.map { FavoriteListSection.folderSection($0) })
        if stats != nil {
            sections.append(.statsFooter)
        }

        layoutSections = sections
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections(sections)
        snapshot.appendItems([.sortHeader(currentSortHeader)], toSection: .sortHeader)
        if isPaymentBannerVisible {
            snapshot.appendItems([.backupBanner], toSection: .backupBanner)
        }

        if let stats {
            snapshot.appendItems([.statsFooter(stats)], toSection: .statsFooter)
        }

        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        folderSections.forEach { section in
            let headerItem = FavoriteListItem.header(section)
            let folderItems = (foldersBySection[section] ?? []).map(FavoriteListItem.folder)
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<FavoriteListItem>()
            sectionSnapshot.append([headerItem])
            sectionSnapshot.append(folderItems, to: headerItem)
            sectionSnapshot.expand([headerItem])
            dataSource.apply(sectionSnapshot, to: .folderSection(section), animatingDifferences: animatingDifferences)
        }
    }

    private func applyFolderSnapshot(folder: FavoriteFolderRow, animatingDifferences: Bool) {
        let allFolders = favoriteFolders()
        if isSearchResultsMode {
            applySearchSnapshot(allFolders: allFolders, parentGroupName: folder.bridgeItem.groupName, animatingDifferences: animatingDifferences)
            return
        }

        let folders = FavoriteSortModeHelper.sortFoldersWithMode(directFavoriteFolders(allFolders, parentGroupName: folder.bridgeItem.groupName).filter { matchesSearch($0.title) }, mode: currentSortMode)
        let favorites = FavoriteSortModeHelper.sortFavoritePointsWithMode(OAFavoritesBridgeHelper.favoritePoints(forGroupName: folder.bridgeItem.groupName).map { FavoritePointRow(item: $0) }.filter { matchesSearch($0.title) || matchesSearch($0.bridgeItem.address) }, mode: currentSortMode)
        if favorites.isEmpty && folders.isEmpty {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }
        var snapshot = Snapshot()
        let stats = folderStats(allFolders: allFolders, currentGroupName: folder.bridgeItem.groupName)
        layoutSections = stats == nil ? [.sortHeader, .content] : [.sortHeader, .content, .statsFooter]
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections(layoutSections)
        snapshot.appendItems([.sortHeader(currentSortHeader)], toSection: .sortHeader)
        snapshot.appendItems(folders.map(FavoriteListItem.folder), toSection: .content)
        snapshot.appendItems(favorites.map(FavoriteListItem.favorite), toSection: .content)
        if let stats {
            snapshot.appendItems([.statsFooter(stats)], toSection: .statsFooter)
        }

        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func applySearchSnapshot(allFolders: [FavoriteFolderRow], parentGroupName: String?, animatingDifferences: Bool) {
        let favorites = FavoriteSortModeHelper.sortFavoritePointsWithMode(searchFavoritePointRows(allFolders: allFolders, parentGroupName: parentGroupName), mode: currentSortMode)
        if favorites.isEmpty {
            applyEmptyStateSnapshot(animatingDifferences: animatingDifferences)
            return
        }

        var snapshot = Snapshot()
        layoutSections = [.sortHeader, .content]
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections(layoutSections)
        snapshot.appendItems([.sortHeader(currentSortHeader)], toSection: .sortHeader)
        snapshot.appendItems(favorites.map(FavoriteListItem.favorite), toSection: .content)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func applyEmptyStateSnapshot(animatingDifferences: Bool) {
        var snapshot = Snapshot()
        layoutSections = [.emptyState]
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections(layoutSections)
        snapshot.appendItems([.emptyState])
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func favoriteFoldersBySection(folders allFolders: [FavoriteFolderRow]) -> [FavoriteFolderSection: [FavoriteFolderRow]] {
        let folders = directFavoriteFolders(allFolders, parentGroupName: nil).filter { matchesSearch($0.title) }
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
    
    private func folderStats(allFolders: [FavoriteFolderRow], currentGroupName: String?) -> FavoriteFolderStats? {
        guard !isSearchResultsMode else { return nil }
        guard let currentGroupName else {
            let pointsCount = allFolders.reduce(0) { $0 + $1.bridgeItem.pointsCount }
            guard !allFolders.isEmpty || pointsCount > 0 else { return nil }
            let fileSize = allFolders.reduce(Int64(0)) { $0 + $1.bridgeItem.fileSize }
            return FavoriteFolderStats(foldersCount: allFolders.count, pointsCount: Int(pointsCount), fileSize: fileSize)
        }

        let nestedFolders = allFolders.filter { isNestedFolder($0.bridgeItem.groupName, in: currentGroupName) }
        let currentFolder = allFolders.first { $0.bridgeItem.groupName == currentGroupName }
        let pointsCount = currentFolder?.bridgeItem.subtreePointsCount ?? nestedFolders.reduce(0) { $0 + $1.bridgeItem.pointsCount }
        guard !nestedFolders.isEmpty || pointsCount > 0 else { return nil }
        let fileSize = (currentFolder?.bridgeItem.fileSize ?? 0) + nestedFolders.reduce(Int64(0)) { $0 + $1.bridgeItem.fileSize }
        return FavoriteFolderStats(foldersCount: nestedFolders.count, pointsCount: Int(pointsCount), fileSize: fileSize)
    }
    
    private func directFavoriteFolders(_ folders: [FavoriteFolderRow], parentGroupName: String?) -> [FavoriteFolderRow] {
        folders.filter { isDirectFolder($0.bridgeItem.groupName, parentGroupName: parentGroupName) }
    }
    
    private func isDirectFolder(_ groupName: String, parentGroupName: String?) -> Bool {
        guard let parentGroupName else { return groupName.isEmpty || !groupName.contains("/") }
        guard !parentGroupName.isEmpty && groupName.hasPrefix(parentGroupName + "/") else { return false }
        let childPath = groupName.dropFirst(parentGroupName.count + 1)
        return !childPath.isEmpty && !childPath.contains("/")
    }
    
    private func matchesSearch(_ text: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return text?.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale.current) != nil
    }

    private func searchFavoritePointRows(allFolders: [FavoriteFolderRow], parentGroupName: String?) -> [FavoritePointRow] {
        favoritePointRows(allFolders: allFolders, parentGroupName: parentGroupName).filter { matchesSearch($0.title) || matchesSearch($0.bridgeItem.address) }
    }
}
