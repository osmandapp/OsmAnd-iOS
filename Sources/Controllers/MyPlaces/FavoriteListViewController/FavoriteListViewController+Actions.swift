//
//  FavoriteListViewController+Actions.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import UniformTypeIdentifiers

extension FavoriteListViewController {
    func openFavoriteGroupAppearance(_ groupName: String) {
        guard let viewController = OAFavoriteGroupEditorViewController(group: OAFavoritesBridgeHelper.pointsGroup(forGroupName: groupName)) else { return }
        favoriteGroupAppearanceGroupName = groupName
        favoriteGroupAppearanceEditor = viewController
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    func openFavoriteItemsMove(_ favoriteItems: [Any]) {
        guard !favoriteItems.isEmpty,
              let navigationController,
              let groupController = OAEditGroupViewController(groupName: nil, groups: OAFavoritesBridgeHelper.favoriteGroupNames(forMovingFavoriteItems: favoriteItems)) else {
            return
        }
        self.groupController = groupController
        favoriteItemsToMove = favoriteItems
        groupController.delegate = self
        navigationController.present(UINavigationController(rootViewController: groupController), animated: true)
    }

    func openFavoriteGroupAddToTrack(_ groupName: String) {
        guard OAFavoritesBridgeHelper.canUseGroup(withName: groupName), let navigationController, let viewController = OAOpenAddTrackViewController(screenType: .addToATrack) else { return }
        addToTrackGroupName = groupName
        addToTrackFavoriteItems = nil
        viewController.delegate = self
        navigationController.present(UINavigationController(rootViewController: viewController), animated: true)
    }

    func openFavoriteItemsAddToTrack(_ favoriteItems: [Any]) {
        guard !favoriteItems.isEmpty, let navigationController, let viewController = OAOpenAddTrackViewController(screenType: .addToATrack) else { return }
        addToTrackFavoriteItems = favoriteItems
        addToTrackGroupName = nil
        viewController.delegate = self
        navigationController.present(UINavigationController(rootViewController: viewController), animated: true)
    }

    func favoritePointRows(forGroupName groupName: String) -> [FavoritePointRow] {
        let sortMode = isSearchResultsMode ? searchFavoriteSortMode() : favoriteSortMode(entryId: groupName)
        let favorites = OAFavoritesBridgeHelper.favoritePoints(forGroupName: groupName).map { FavoritePointRow(item: $0) }
        return FavoriteSortModeHelper.sortFavoritePointsWithMode(favorites, mode: sortMode)
    }

    func favoritePointRows(allFolders: [FavoriteFolderRow], parentGroupName: String?) -> [FavoritePointRow] {
        allFolders.filter { isSearchGroup($0.bridgeItem.groupName, parentGroupName: parentGroupName) }.flatMap { OAFavoritesBridgeHelper.favoritePoints(forGroupName: $0.bridgeItem.groupName).map { FavoritePointRow(item: $0) } }
    }

    func makeActionsMenu() -> UIMenu {
        let selectAction = UIAction(title: localizedString("shared_string_select"), image: .icCustomSelectOutlined) { [weak self] _ in
            self?.selectButtonPressed()
        }
        let addFolderAction = UIAction(title: localizedString("add_new_folder"), image: .icCustomFolderAddOutlined) { [weak self] _ in
            self?.openNewFavoriteGroupEditor()
        }
        let importAction = UIAction(title: localizedString("shared_string_import"), image: .icCustomImportOutlined) { [weak self] _ in
            self?.openPickerToImport()
        }

        let selectSection = UIMenu(title: "", options: .displayInline, children: [selectAction])
        let addFolderSection = UIMenu(title: "", options: .displayInline, children: [addFolderAction])
        let importSection = UIMenu(title: "", options: .displayInline, children: [importAction])
        return UIMenu(title: "", children: [selectSection, addFolderSection, importSection])
    }

    func setEditing(_ isEditing: Bool) {
        let shouldResetSearchSelection = !isEditing && isSelectionModeInSearch
        if !isEditing {
            collectionView.indexPathsForSelectedItems?.forEach { collectionView.deselectItem(at: $0, animated: false) }
            isSelectionModeInSearch = false
            isSearchActive = false
            searchText = ""
            selectionManager.deselectAll()
        } else {
            let selectableItems = selectableIndexPaths().compactMap { dataSource.itemIdentifier(for: $0)?.selectionItem }
            selectionManager = SelectionManager(allItems: selectableItems)
        }

        collectionView.isEditing = isEditing
        collectionView.reloadData()
        myPlacesDelegate?.updateEditMode(isEditing)
        configureNavigation()
        navigationController?.setToolbarHidden(!isEditing, animated: true)
        if shouldResetSearchSelection {
            clearSearchControllerText()
            applySnapshot(animatingDifferences: false)
        }
    }

    func showRenameAlert(for folder: FavoriteFolderRow) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self, weak alert] _ in
            guard let self, let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            let oldGroupName = folder.bridgeItem.groupName
            let newGroupName = self.groupName(oldGroupName, replacingLastComponentWith: text)
            if self.hasFolderInList(named: newGroupName, excluding: oldGroupName) {
                self.showErrorAlert(localizedString("folder_already_exsists"))
                return
            }

            OAFavoritesBridgeHelper.renameFavoriteGroup(oldGroupName, newName: newGroupName)
            self.renameFavoriteSortModeKeys(from: oldGroupName, to: newGroupName)
            self.applySnapshot(animatingDifferences: true)
        }

        alert.addAction(applyAction)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.addTextField { textField in
            textField.placeholder = localizedString("enter_new_name")
            textField.text = folder.title
        }

        alert.preferredAction = applyAction
        present(alert, animated: true)
    }

    func showDeleteAlert(for folder: FavoriteFolderRow) {
        let message = String(format: localizedString("favorite_confirm_delete_group"), folder.title, folder.bridgeItem.subtreePointsCount)
        let alert = UIAlertController(title: localizedString("delete_folder"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard OAFavoritesBridgeHelper.deleteFavoriteGroup(folder.bridgeItem.groupName) else { return }
            self?.clearFavoriteSortModes(forGroupNames: [folder.bridgeItem.groupName])
            self?.applySnapshot(animatingDifferences: true)
        })

        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func showFavoriteDeleteAlert(for favorite: FavoritePointRow) {
        let title = String(format: localizedString("delete_favorite_confirmation_title"), favorite.title)
        let alert = UIAlertController(title: title, message: localizedString("favorites_delete_confirmation_message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard OAFavoritesBridgeHelper.deleteFavoritePoint(favorite.bridgeItem) else { return }
            self?.applySnapshot(animatingDifferences: true)
        })

        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func shareFavoritePoint(_ point: OAFavoritePointBridgeItem, sourceView: UIView) {
        pointToShare = point
        let items = favoritePointShareItems(for: point)
        guard !items.isEmpty else {
            pointToShare = nil
            return
        }
        showActivity(items,
                     applicationActivities: favoritePointShareActivities(),
                     excludedActivityTypes: nil,
                     sourceView: sourceView,
                     barButtonItem: nil) { [weak self] in
            self?.pointToShare = nil
        }
    }
    
    func selectedFavoritePointsCount(for selectedItems: [Any]) -> Int {
        let folderPointsCount = selectedItems.compactMap { $0 as? OAFavoriteFolderBridgeItem }.reduce(0) { $0 + Int($1.subtreePointsCount) }
        let pointsCount = selectedItems.filter { $0 is OAFavoritePointBridgeItem }.count
        return folderPointsCount + pointsCount
    }

    func bridgeItems(for indexPaths: [IndexPath]) -> [Any] {
        indexPaths.compactMap { indexPath in
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch item {
            case .folder(let folder):
                return folder.bridgeItem
            case .favorite(let favorite):
                return favorite.bridgeItem
            default:
                return nil
            }
        }
    }

    func openFavoriteItemsAppearance() {
        guard collectionView.indexPathsForSelectedItems?.isEmpty == false else {
            let alert = UIAlertController(title: "", message: localizedString("fav_select"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
            present(alert, animated: true)
            return
        }

        guard let navigationController else { return }
        let colorController = OAEditColorViewController()
        colorController.delegate = self
        self.colorController = colorController
        let modalNavigationController = UINavigationController(rootViewController: colorController)
        navigationController.present(modalNavigationController, animated: true)
    }
    
    func updateSelection(at indexPath: IndexPath) {
        guard let selectionItem = dataSource.itemIdentifier(for: indexPath)?.selectionItem else { return }
        selectionManager.toggle(selectionItem)
    }

    func showSearchController() {
        if isRootFolder {
            myPlacesDelegate?.updateSearchEnabling(true)
        } else {
            if #available(iOS 26.0, *) {
                navigationItem.preferredSearchBarPlacement = .stacked
            }

            navigationItem.searchController = subfolderSearchController
            subfolderSearchController.isActive = true
        }
    }

    func hideSearchController() {
        if isRootFolder {
            let searchController = navigationController?.navigationBar.topItem?.searchController
            searchController?.isActive = false
            if isSelectionModeInSearch {
                searchController?.searchBar.text = ""
            }
            myPlacesDelegate?.updateSearchEnabling(false)
        } else {
            subfolderSearchController.isActive = false
            if isSelectionModeInSearch {
                subfolderSearchController.searchBar.text = ""
            }
            navigationItem.searchController = nil
        }
    }

    @objc func selectButtonPressed() {
        setEditing(true)
    }

    @objc func searchButtonPressed(_ sender: Any) {
        isSearchActive = true
        showSearchController()
        configureNavigationButtons()
        configureToolbar()
        navigationController?.setToolbarHidden(shouldHideSearchToolbar(), animated: true)
    }

    @objc func searchSelectButtonPressed() {
        isSelectionModeInSearch = true
        isSearchActive = false
        hideSearchController()

        selectButtonPressed()
    }

    @objc func cancelButtonPressed() {
        setEditing(false)
        configureToolbar()
    }

    @objc func selectAllButtonPressed() {
        let selectableIndexPaths = selectableIndexPaths()
        if selectionManager.areAllSelected {
            selectableIndexPaths.forEach { collectionView.deselectItem(at: $0, animated: false) }
            selectionManager.deselectAll()
        } else {
            selectableIndexPaths.forEach { collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }
            selectionManager.selectAll()
        }

        updateSelectionUI()
    }

    @objc func favoriteDataDidChange() {
        DispatchQueue.main.async { [weak self] in
            OAFavoritesBridgeHelper.invalidateFavoriteFoldersCache()
            self?.applySnapshot(animatingDifferences: true)
        }
    }

    @objc func productPurchased() {
        DispatchQueue.main.async { [weak self] in
            self?.applySnapshot(animatingDifferences: true)
        }
    }

    @objc func shareButtonClicked(_ sender: Any) {
        let sourceView = sender as? UIView ?? collectionView
        shareItems(for: sourceView)
        setEditing(false)
        applySnapshot()
    }

    @objc func moveButtonClicked(_ sender: Any) {
        guard let selectedItems = collectionView.indexPathsForSelectedItems, !selectedItems.isEmpty else {
            let alert = UIAlertController(title: "", message: localizedString("fav_select"), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: localizedString("shared_string_ok"), style: .default)
            alert.addAction(defaultAction)
            present(alert, animated: true)
            return
        }

        openFavoriteItemsMove(bridgeItems(for: selectedItems))
    }

    @objc func deleteButtonClicked(_ sender: Any) {
        let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
        if selectedIndexPaths.isEmpty {
            let alert = UIAlertController(title: nil, message: localizedString("fav_select_remove"), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: localizedString("ok"), style: .default)
            alert.addAction(defaultAction)
            present(alert, animated: true)
            return
        }

        let selectedBridgeItems = bridgeItems(for: selectedIndexPaths)
        let title = deleteConfirmationTitle(for: selectedBridgeItems)
        let message = deleteConfirmationMessage(for: selectedBridgeItems)

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let deleteButton = UIAlertAction(
            title: localizedString("shared_string_delete"),
            style: .destructive
        ) { [weak self] _ in
            self?.removeSelectedFavoriteItems()
        }

        let cancelButton = UIAlertAction(
            title: localizedString("shared_string_cancel"),
            style: .cancel,
            handler: nil
        )

        alert.addAction(deleteButton)
        alert.addAction(cancelButton)

        present(alert, animated: true, completion: nil)
    }

    @objc func importButtonClicked(_ sender: Any) {
        openPickerToImport()
    }

    @objc func clearSearchButtonClicked(_ sender: Any) {
        searchText = ""
        clearSearchControllerText()
        configureToolbar()
        navigationController?.setToolbarHidden(shouldHideSearchToolbar(), animated: true)
        applySnapshot(animatingDifferences: false)
    }
    
    @objc func updateDistanceAndDirection() {
        updateDistanceAndDirection(false)
    }
    
    private func selectableIndexPaths() -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        for section in 0..<collectionView.numberOfSections {
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else { continue }
                switch itemIdentifier {
                case .folder, .favorite:
                    indexPaths.append(indexPath)
                default:
                    continue
                }
            }
        }

        return indexPaths
    }
    
    private func openNewFavoriteGroupEditor() {
        guard let navigationController, let viewController = OAFavoriteGroupEditorViewController(new: ()) else { return }
        viewController.parentGroupName = parentGroupName
        viewController.validatesGroupUniqueness = true
        viewController.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        navigationController.present(modalNavigationController, animated: true)
    }
    
    private func isSearchGroup(_ groupName: String, parentGroupName: String?) -> Bool {
        guard let parentGroupName else { return true }
        guard !parentGroupName.isEmpty else { return groupName.isEmpty }
        return groupName == parentGroupName || isNestedFolder(groupName, in: parentGroupName)
    }
    
    private func groupName(_ groupName: String, replacingLastComponentWith lastComponent: String) -> String {
        guard let separatorIndex = groupName.lastIndex(of: "/") else { return lastComponent }
        let parentGroupName = groupName[..<separatorIndex]
        guard !parentGroupName.isEmpty else { return lastComponent }
        return "\(parentGroupName)/\(lastComponent)"
    }
    
    private func showErrorAlert(_ text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel))
        present(alert, animated: true)
    }

    private func hasFolderInList(named groupName: String, excluding excludedGroupName: String) -> Bool {
        favoriteFolders().contains { folder in
            let existingGroupName = folder.bridgeItem.groupName
            return existingGroupName != excludedGroupName && existingGroupName == groupName
        }
    }
    
    private func favoritePointShareItems(for point: OAFavoritePointBridgeItem) -> [Any] {
        var items: [Any] = []
        let sharingText = NSMutableString()
        appendFavoritePointShareLine(point.title, to: sharingText)
        appendFavoritePointShareLine(point.displayGroupName, to: sharingText)
        appendFavoritePointShareLine(point.itemDescription, to: sharingText)
        appendFavoritePointCoordinatesAndURL(to: sharingText, point: point)
        if let url = URL(string: OAFavoritesBridgeHelper.sharePoiURLString(forFavoritePoint: point)) {
            items.append(ShareLinkItem(url: url, title: point.title, icon: point.icon()))
        }
        if sharingText.length > 0 {
            items.append(sharingText)
        }
        return items
    }

    private func appendFavoritePointShareLine(_ line: String?, to sharingText: NSMutableString) {
        guard let line, !line.isEmpty else { return }
        if sharingText.length > 0 {
            sharingText.append("\n")
        }
        sharingText.append(line)
    }
    
    private func appendFavoritePointCoordinatesAndURL(to sharingText: NSMutableString, point: OAFavoritePointBridgeItem) {
        let geoURLString = OAFavoritesBridgeHelper.geoURLString(forFavoritePoint: point)
        if !geoURLString.isEmpty {
            sharingText.append("\n\(localizedString("shared_string_location")): \(geoURLString)")
        }

        let shareURLString = OAFavoritesBridgeHelper.sharePoiURLString(forFavoritePoint: point)
        if !shareURLString.isEmpty {
            sharingText.append("\n\(shareURLString)")
        }
    }

    private func favoritePointShareActivities() -> [UIActivity] {
        let activities: [OAShareMenuActivityType] = [.clipboard, .copyAddress, .copyPOIName, .copyCoordinates, .geo]
        return activities.compactMap { type in
            let activity = OAShareMenuActivity(type: type)
            activity?.delegate = self
            return activity
        }
    }
    
    private func shareItems(for sourceView: UIView) {
        guard let selectedItems = collectionView.indexPathsForSelectedItems, !selectedItems.isEmpty else {
            let alert = UIAlertController(
                title: "",
                message: localizedString("fav_export_select"),
                preferredStyle: .alert
            )

            let defaultAction = UIAlertAction(
                title: localizedString("shared_string_ok"),
                style: .default,
                handler: nil
            )

            alert.addAction(defaultAction)
            present(alert, animated: true, completion: nil)
            return
        }

        guard let favoritesUrl = OAFavoritesBridgeHelper.shareFavoriteItems(bridgeItems(for: selectedItems)) else { return }
        showActivity(
            [favoritesUrl],
            sourceView: sourceView,
            barButtonItem: nil,
            completionWithItemsHandler: {
                try? FileManager.default.removeItem(at: favoritesUrl)
            }
        )
    }

    private func removeSelectedFavoriteItems() {
        let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
        let items = bridgeItems(for: selectedIndexPaths)
        let groupNames = items.compactMap { ($0 as? OAFavoriteFolderBridgeItem)?.groupName }
        if OAFavoritesBridgeHelper.deleteFavoriteItems(items) {
            clearFavoriteSortModes(forGroupNames: groupNames)
        }

        setEditing(false)
        applySnapshot(animatingDifferences: true)
    }
    
    private func deleteConfirmationTitle(for selectedItems: [Any]) -> String {
        let foldersCount = selectedItems.filter { $0 is OAFavoriteFolderBridgeItem }.count
        let pointsCount = selectedItems.filter { $0 is OAFavoritePointBridgeItem }.count

        if foldersCount > 0 && pointsCount == 0 {
            return String(format: localizedString("folders_delete_confirmation_title"), foldersCount)
        } else if pointsCount > 0 && foldersCount == 0 {
            return String(format: localizedString("favorites_delete_confirmation_title"), pointsCount)
        } else {
            return String(format: localizedString("items_delete_confirmation_title"), pointsCount + foldersCount)
        }
    }

    private func deleteConfirmationMessage(for selectedItems: [Any]) -> String {
        let folders = selectedItems.compactMap { $0 as? OAFavoriteFolderBridgeItem }
        let points = selectedItems.compactMap { $0 as? OAFavoritePointBridgeItem }
        if folders.isEmpty {
            return localizedString("favorites_delete_confirmation_message")
        }

        let folderPointsCount = folders.reduce(0) { $0 + Int($1.subtreePointsCount) }
        let pointsCount = folderPointsCount + points.count

        return String(format: localizedString("mixed_delete_confirmation_message"), folders.count, pointsCount)
    }
    
    private func openPickerToImport() {
        let gpxType = UTType(importedAs: "com.topografix.gpx", conformingTo: .xml)
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [gpxType], asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
}
