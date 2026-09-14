//
//  FavoriteListViewController+ContextMenu.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

extension FavoriteListViewController {
    func makeFolderContextMenu(for folder: FavoriteFolderRow, indexPath: IndexPath) -> UIMenu {
        let folderFavoriteItem: [Any] = [folder.fullPath]
        let subtreeFavoriteItems: [Any] = favoritePointRows(inFolder: folder.fullPath).map { $0.bridgeItem }
        let hasFavoritePoints = !subtreeFavoriteItems.isEmpty
        var sections: [UIMenu] = []
        let showHideAction = UIAction(title: localizedString(folder.isVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: folder.isVisible ? .icCustomHideOutlined : .icCustomShowOutlined) { [weak self] _ in
            guard let self, let group = folder.group else { return }
            OAFavoritesHelperBridge.shared().setFavoriteGroupVisible(group.groupName, visible: !folder.isVisible)
            self.applySnapshot(animatingDifferences: true)
        }
        let pinAction = UIAction(title: localizedString(folder.isPinned ? "unpin_folder" : "pin_folder"), image: folder.isPinned ? .icCustomDrawingPinDisable : .icCustomDrawingPin) { [weak self] _ in
            guard let self, let group = folder.group else { return }
            OAFavoritesHelperBridge.shared().setFavoriteGroupPinned(group.groupName, pinned: !folder.isPinned)
            self.applySnapshot(animatingDifferences: true)
        }
        if folder.group != nil {
            sections.append(UIMenu(title: "", options: .displayInline, children: [showHideAction, pinAction]))
        }

        let renameAction = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit) { [weak self] _ in
            self?.showRenameAlert(for: folder)
        }
        let defaultAppearanceAction = UIAction(title: localizedString("default_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
            guard let self, let group = folder.group else { return }
            self.openFavoriteGroupAppearance(group.groupName)
        }
        var secondButtons: [UIMenuElement] = [renameAction]
        if folder.group != nil {
            secondButtons.append(defaultAppearanceAction)
        }
        sections.append(UIMenu(title: "", options: .displayInline, children: secondButtons))

        let shareAction = UIAction(title: localizedString("shared_string_share"), image: .icCustomExportOutlined) { [weak self] _ in
            guard let self else { return }
            let sourceView: UIView = self.collectionView.cellForItem(at: indexPath) ?? self.collectionView
            guard let favoritesUrl = OAFavoritesHelperBridge.shared().shareFavoriteItems(folderFavoriteItem) else { return }
            showActivity([favoritesUrl], sourceView: sourceView, barButtonItem: nil, completionWithItemsHandler: {
                try? FileManager.default.removeItem(at: favoritesUrl)
            })
        }
        let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { [weak self] _ in
            self?.openFavoriteItemsMove(folderFavoriteItem)
        }
        var thirdButtons: [UIMenuElement] = []
        if hasFavoritePoints {
            thirdButtons.append(shareAction)
        }
        if !folder.fullPath.isEmpty {
            thirdButtons.append(moveAction)
        }
        if !thirdButtons.isEmpty {
            sections.append(UIMenu(title: "", options: .displayInline, children: thirdButtons))
        }

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { _ in
            OAFavoritesHelperBridge.shared().addFavoriteItems(toMapMarkers: folderFavoriteItem)
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            self?.openFavoriteGroupAddToTrack(folder.fullPath)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { _ in
            OAFavoritesHelperBridge.shared().addFavoriteItems(toNavigation: folderFavoriteItem)
        }
        if hasFavoritePoints {
            let addToActions: [UIMenuElement] = folder.group == nil ? [trackAction] : [mapMarkersAction, trackAction, navigationAction]
            let addToMenu = UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: addToActions)
            sections.append(UIMenu(title: "", options: .displayInline, children: [addToMenu]))
        }

        let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
            self?.showDeleteAlert(for: folder)
        }
        sections.append(UIMenu(title: "", options: .displayInline, children: [deleteAction]))

        return UIMenu(title: "", children: sections)
    }

    func makePointContextMenu(for point: FavoritePointRow, indexPath: IndexPath) -> UIMenu {
        let editAction = UIAction(title: localizedString("shared_string_edit"), image: .icCustomEdit) { [weak self] _ in
            guard let self, let viewController = OAFavoritesHelperBridge.shared().editPointViewController(forFavoritePoint: point.bridgeItem) else { return }
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            self.navigationController?.present(navigationController, animated: true)
        }
        let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction])

        let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { [weak self] _ in
            self?.openFavoriteItemsMove([point.bridgeItem])
        }
        let shareAction = UIAction(title: localizedString("shared_string_share"), image: .icCustomExportOutlined) { [weak self] _ in
            guard let self,
                  let sourceView: UIView = self.collectionView.cellForItem(at: indexPath) else {
                return
            }

            self.shareFavoritePoint(point.bridgeItem, sourceView: sourceView)
        }
        let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [moveAction, shareAction])

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { _ in
            OAFavoritesHelperBridge.shared().addFavoriteItems(toMapMarkers: [point.bridgeItem])
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            self?.openFavoriteItemsAddToTrack([point.bridgeItem])
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { _ in
            OAFavoritesHelperBridge.shared().addFavoriteItems(toNavigation: [point.bridgeItem])
        }
        let addToMenu = UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: [mapMarkersAction, trackAction, navigationAction])
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])

        let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
            self?.showFavoriteDeleteAlert(for: point)
        }
        let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        return UIMenu(title: "", children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, lastButtonsSection])
    }

    func makeAdditionalContextMenu() -> UIMenu {
        var menuElements: [UIMenuElement] = []
        let selectedBridgeItems = bridgeItems(for: selectionManager.selectedItems)
        let folderPaths = selectedBridgeItems.compactMap { $0 as? String }
        let folders = folderPaths.compactMap { FavoriteFolderProvider.shared.favoriteFolder($0)?.group }
        let containsVirtualFolder = folders.count != folderPaths.count
        let hasPoints = selectedBridgeItems.contains { $0 is OAFavoritePointBridgeItem }

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { [weak self] _ in
            OAFavoritesHelperBridge.shared().addFavoriteItems(toMapMarkers: selectedBridgeItems)
            self?.setEditing(false)
            self?.applySnapshot(animatingDifferences: true)
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            self?.openFavoriteItemsAddToTrack(selectedBridgeItems)
            self?.setEditing(false)
            self?.applySnapshot(animatingDifferences: true)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { [weak self] _ in
            OAFavoritesHelperBridge.shared().addFavoriteItems(toNavigation: selectedBridgeItems)
            self?.applySnapshot(animatingDifferences: true)
        }
        let addToActions: [UIMenuElement] = containsVirtualFolder ? [trackAction] : [navigationAction, trackAction, mapMarkersAction]
        let addToMenu = UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: addToActions)
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])
        menuElements.append(thirdButtonsSection)

        let changeAppearanceAction = UIAction(title: localizedString("change_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
            self?.openFavoriteItemsAppearance()
        }
        if !containsVirtualFolder {
            menuElements.append(UIMenu(title: "", options: .displayInline, children: [changeAppearanceAction]))
        }

        if !hasPoints {
            if !folders.isEmpty, !containsVirtualFolder {
                var folderMenuElements: [UIMenuElement] = []

                if folders.contains(where: { !$0.isPinned }) {
                    let unpinnedGroupNames = folders.filter({ !$0.isPinned }).map { $0.groupName }
                    let pinAction = UIAction(title: localizedString("pin_folder"), image: .icCustomMapPinOutlined) { [weak self] _ in
                        OAFavoritesHelperBridge.shared().setFavoriteGroupsPinned(unpinnedGroupNames, pinned: true)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(pinAction)
                }

                if folders.contains(where: { $0.isPinned }) {
                    let pinnedGroupNames = folders.filter({ $0.isPinned }).map { $0.groupName }
                    let unpinAction = UIAction(title: localizedString("unpin_folder"), image: .icCustomMapPinOutlined) { [weak self] _ in
                        OAFavoritesHelperBridge.shared().setFavoriteGroupsPinned(pinnedGroupNames, pinned: false)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(unpinAction)
                }

                if folders.contains(where: { $0.isVisible }) {
                    let visibleGroupNames = folders.filter({ $0.isVisible }).map { $0.groupName }
                    let hideAction = UIAction(title: localizedString("shared_string_hide_from_map"), image: .icCustomHideOutlined) { [weak self] _ in
                        OAFavoritesHelperBridge.shared().setFavoriteGroupsVisible(visibleGroupNames, visible: false)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(hideAction)
                }

                if folders.contains(where: { !$0.isVisible }) {
                    let hiddenGroupNames = folders.filter({ !$0.isVisible }).map { $0.groupName }
                    let showAction = UIAction(title: localizedString("shared_string_show_on_map"), image: .icCustomShowOutlined) { [weak self] _ in
                        OAFavoritesHelperBridge.shared().setFavoriteGroupsVisible(hiddenGroupNames, visible: true)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(showAction)
                }

                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: folderMenuElements)
                menuElements.append(firstButtonsSection)
            }
        }

        return UIMenu(title: "", children: menuElements)
    }
}
