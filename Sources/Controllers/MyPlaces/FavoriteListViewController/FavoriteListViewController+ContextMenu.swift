//
//  FavoriteListViewController+ContextMenu.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

extension FavoriteListViewController {
    func makeFolderContextMenu(for folder: FavoriteFolderRow, indexPath: IndexPath) -> UIMenu {
        let folderFavoriteItem: [Any] = [folder.bridgeItem]
        let subtreeFavoriteItems: [Any] = favoritePointRows(allFolders: favoriteFolders(), parentGroupName: folder.bridgeItem.groupName).map { $0.bridgeItem }
        let hasFavoritePoints = !subtreeFavoriteItems.isEmpty
        let showHideAction = UIAction(title: localizedString(folder.isVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: folder.isVisible ? .icCustomHideOutlined : .icCustomShowOutlined) { [weak self] _ in
            guard let self else { return }
            OAFavoritesBridgeHelper.setFavoriteGroupVisible(folder.bridgeItem.groupName, visible: !folder.isVisible)
            self.applySnapshot(animatingDifferences: true)
        }
        let pinAction = UIAction(title: localizedString(folder.isPinned ? "unpin_folder" : "pin_folder"), image: folder.isPinned ? .icCustomDrawingPinDisable : .icCustomDrawingPin) { [weak self] _ in
            guard let self else { return }
            OAFavoritesBridgeHelper.setFavoriteGroupPinned(folder.bridgeItem.groupName, pinned: !folder.isPinned)
            self.applySnapshot(animatingDifferences: true)
        }
        let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showHideAction, pinAction])

        let renameAction = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit) { [weak self] _ in
            guard let self else { return }
            self.showRenameAlert(for: folder)
        }
        let defaultAppearanceAction = UIAction(title: localizedString("default_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteGroupAppearance(folder.bridgeItem.groupName)
        }
        let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction, defaultAppearanceAction])

        let shareAction = UIAction(title: localizedString("shared_string_share"), image: .icCustomExportOutlined) { [weak self] _ in
            guard let self else { return }
            let sourceView: UIView = self.collectionView.cellForItem(at: indexPath) ?? self.collectionView
            guard let favoritesUrl = OAFavoritesBridgeHelper.shareFavoriteItems([folder.bridgeItem]) else { return }
            showActivity([favoritesUrl], sourceView: sourceView, barButtonItem: nil, completionWithItemsHandler: {
                try? FileManager.default.removeItem(at: favoritesUrl)
            })
        }
        let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteItemsMove([folder.bridgeItem])
        }
        let thirdButtons: [UIMenuElement] = (hasFavoritePoints ? [shareAction] : []) + (folder.bridgeItem.groupName.isEmpty ? [] : [moveAction])
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: thirdButtons)

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { _ in
            OAFavoritesBridgeHelper.addFavoriteItems(toMapMarkers: folderFavoriteItem)
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteGroupAddToTrack(folder.bridgeItem.groupName)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { _ in
            OAFavoritesBridgeHelper.addFavoriteItems(toNavigation: folderFavoriteItem)
        }
        let addToActions: [UIMenuElement] = hasFavoritePoints ? [mapMarkersAction, trackAction, navigationAction] : []
        let fourthButtons: [UIMenuElement] = addToActions.isEmpty ? [] : [UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: addToActions)]
        let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: fourthButtons)

        let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
            guard let self else { return }
            self.showDeleteAlert(for: folder)
        }
        let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        return UIMenu(title: "", children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection].filter { !$0.children.isEmpty })
    }

    func makePointContextMenu(for point: FavoritePointRow, indexPath: IndexPath) -> UIMenu {
        let editAction = UIAction(title: localizedString("shared_string_edit"), image: .icCustomEdit) { [weak self] _ in
            guard let self, let viewController = OAFavoritesBridgeHelper.editPointViewController(forFavoritePoint: point.bridgeItem) else { return }
            viewController.delegate = self
            let navigationController = UINavigationController(rootViewController: viewController)
            self.navigationController?.present(navigationController, animated: true)
        }
        let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction])

        let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteItemsMove([point.bridgeItem])
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
            OAFavoritesBridgeHelper.addFavoriteItems(toMapMarkers: [point.bridgeItem])
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteItemsAddToTrack([point.bridgeItem])
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { _ in
            OAFavoritesBridgeHelper.addFavoriteItems(toNavigation: [point.bridgeItem])
        }
        let addToMenu = UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: [mapMarkersAction, trackAction, navigationAction])
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])

        let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
            guard let self else { return }
            self.showFavoriteDeleteAlert(for: point)
        }
        let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        return UIMenu(title: "", children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, lastButtonsSection])
    }

    func makeAdditionalContextMenu() -> UIMenu {
        var menuElements: [UIMenuElement] = []
        let selectedBridgeItems = bridgeItems(for: selectionManager.selectedItems)
        let hasPoints = selectedBridgeItems.contains { $0 is OAFavoritePointBridgeItem }

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { [weak self] _ in
            OAFavoritesBridgeHelper.addFavoriteItems(toMapMarkers: selectedBridgeItems)
            self?.setEditing(false)
            self?.applySnapshot(animatingDifferences: true)
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            self?.openFavoriteItemsAddToTrack(selectedBridgeItems)
            self?.setEditing(false)
            self?.applySnapshot(animatingDifferences: true)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { [weak self] _ in
            OAFavoritesBridgeHelper.addFavoriteItems(toNavigation: selectedBridgeItems)
            self?.applySnapshot(animatingDifferences: true)
        }
        let addToMenu = UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: [navigationAction, trackAction, mapMarkersAction])
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])
        menuElements.append(thirdButtonsSection)

        let changeAppearanceAction = UIAction(title: localizedString("change_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
            self?.openFavoriteItemsAppearance()
        }
        let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [changeAppearanceAction])
        menuElements.append(secondButtonsSection)

        if !hasPoints {
            let folders = selectedBridgeItems.compactMap { $0 as? OAFavoriteFolderBridgeItem }

            if !folders.isEmpty {
                var folderMenuElements: [UIMenuElement] = []

                if folders.contains(where: { !$0.isPinned }) {
                    let unpinnedGroupNames = folders.filter({ !$0.isPinned }).map { $0.groupName }
                    let pinAction = UIAction(title: localizedString("pin_folder"), image: .icCustomMapPinOutlined) { [weak self] _ in
                        OAFavoritesBridgeHelper.setFavoriteGroupsPinned(unpinnedGroupNames, pinned: true)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(pinAction)
                }

                if folders.contains(where: { $0.isPinned }) {
                    let pinnedGroupNames = folders.filter({ $0.isPinned }).map { $0.groupName }
                    let unpinAction = UIAction(title: localizedString("unpin_folder"), image: .icCustomMapPinOutlined) { [weak self] _ in
                        OAFavoritesBridgeHelper.setFavoriteGroupsPinned(pinnedGroupNames, pinned: false)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(unpinAction)
                }

                if folders.contains(where: { $0.isVisible }) {
                    let visibleGroupNames = folders.filter({ $0.isVisible }).map { $0.groupName }
                    let hideAction = UIAction(title: localizedString("shared_string_hide_from_map"), image: .icCustomHideOutlined) { [weak self] _ in
                        OAFavoritesBridgeHelper.setFavoriteGroupsVisible(visibleGroupNames, visible: false)
                        self?.setEditing(false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(hideAction)
                }

                if folders.contains(where: { !$0.isVisible }) {
                    let hiddenGroupNames = folders.filter({ !$0.isVisible }).map { $0.groupName }
                    let showAction = UIAction(title: localizedString("shared_string_show_on_map"), image: .icCustomShowOutlined) { [weak self] _ in
                        OAFavoritesBridgeHelper.setFavoriteGroupsVisible(hiddenGroupNames, visible: true)
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
