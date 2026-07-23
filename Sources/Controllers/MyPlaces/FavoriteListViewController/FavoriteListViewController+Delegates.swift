//
//  FavoriteListViewController+Delegates.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

extension FavoriteListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .folder(let folder):
            if collectionView.isEditing {
                updateSelection(at: indexPath)
                updateSelectionUI()
                return
            }
            let viewController = FavoriteListViewController(frame: view.bounds, screenMode: .folder(folder, previousTitle: normalTitle))
            viewController.myPlacesDelegate = myPlacesDelegate
            navigationController?.pushViewController(viewController, animated: true)
        case .favorite(let favorite):
            if collectionView.isEditing {
                updateSelection(at: indexPath)
                updateSelectionUI()
                return
            }
            OAFavoritesBridgeHelper.openFavoritePoint(withIdentifier: favorite.bridgeItem.identifier)
        default:
            break
        }

        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView.isEditing else { return }
        updateSelection(at: indexPath)
        updateSelectionUI()
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        isContextMenuVisible = true
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        animator?.addCompletion { [weak self] in
            guard let self else { return }
            self.isContextMenuVisible = false
            if self.shouldReloadCollectionView {
                self.shouldReloadCollectionView = false
                self.updateDistanceAndDirection(true)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !collectionView.isEditing, let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let menuProvider: UIContextMenuActionProvider = { [weak self] _ in
            guard let self else { return nil }
            switch item {
            case .folder(let folder):
                return self.makeFolderContextMenu(for: folder, indexPath: indexPath)
            case .favorite(let favorite):
                return self.makePointContextMenu(for: favorite, indexPath: indexPath)
            default:
                return nil
            }
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
    }
}

extension FavoriteListViewController: OAShareMenuDelegate {
    func onCopy(_ type: OAShareMenuActivityType) {
        guard let pointToShare else { return }
        switch type {
        case .clipboard:
            copyFavoritePointShareText(OAFavoritesBridgeHelper.sharePoiURLString(forFavoritePoint: pointToShare))
        case .copyAddress:
            if let address = pointToShare.address, !address.isEmpty {
                copyFavoritePointShareText(address)
            } else {
                OAUtilities.showToast(localizedString("no_address_found"), details: nil, duration: 4, in: view)
            }
        case .copyPOIName:
            if !pointToShare.title.isEmpty {
                copyFavoritePointShareText(pointToShare.title)
            } else {
                OAUtilities.showToast(localizedString("toast_empty_name_error"), details: nil, duration: 4, in: view)
            }
        case .copyCoordinates:
            copyFavoritePointShareText(OAFavoritesBridgeHelper.formattedCoordinates(forFavoritePoint: pointToShare))
        case .geo:
            copyFavoritePointShareText(OAFavoritesBridgeHelper.geoURLString(forFavoritePoint: pointToShare))
        default:
            break
        }
    }

    func copyFavoritePointShareText(_ text: String) {
        UIPasteboard.general.string = text
        OAUtilities.showToast(localizedString("copied_to_clipboard"), details: text, duration: 4, in: view)
    }
}

extension FavoriteListViewController: MyPlacesSearchable, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        searchResults(for: searchController)
    }

    func searchResults(for searchController: UISearchController) {
        isSearchActive = searchController.isActive
        if isSearchActive || !isSelectionModeInSearch {
            searchText = searchController.searchBar.searchTextField.text ?? ""
        }
        configureToolbar()
        navigationController?.setToolbarHidden(shouldHideSearchToolbar(), animated: true)
        applySnapshot(animatingDifferences: false)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        if !isSelectionModeInSearch {
            searchText = ""
            searchBar.text = ""
            hideSearchController()
        }
        configureNavigationButtons()
        configureToolbar()
        navigationController?.setToolbarHidden(!collectionView.isEditing, animated: true)
        applySnapshot(animatingDifferences: false)
    }

    func presentSearchController(_ searchController: UISearchController) {
        let searchBarActivationDelay = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + searchBarActivationDelay) {
            guard !searchController.searchBar.isFirstResponder else { return }
            searchController.searchBar.becomeFirstResponder()
        }
    }
}

extension FavoriteListViewController: OAEditColorViewControllerDelegate {
    func colorChanged() {
        guard let colorController else { return }
        defer {
            self.colorController = nil
        }

        let selectedItems = bridgeItems(for: selectionManager.selectedItems)
        guard !selectedItems.isEmpty else { return }
        if colorController.saveChanges {
            OAFavoritesBridgeHelper.changeFavoriteItems(selectedItems, colorIndex: colorController.colorIndex)
        }

        setEditing(false)
        applySnapshot(animatingDifferences: true)
    }
}

extension FavoriteListViewController: OAEditGroupViewControllerDelegate {
    func groupChanged() {
        guard let groupController else { return }
        defer {
            self.groupController = nil
            favoriteItemsToMove = nil
        }

        guard groupController.saveChanges else { return }

        let targetGroupName = groupController.groupName ?? ""
        guard let favoriteItemsToMove else { return }
        createFavoriteMoveTargetGroupIfNeeded(targetGroupName, favoriteItems: favoriteItemsToMove)
        OAFavoritesBridgeHelper.moveFavoriteItems(favoriteItemsToMove, toGroupName: targetGroupName)
        updateFavoriteSortModeKeysAfterMove(favoriteItemsToMove, toGroupName: targetGroupName)
        setEditing(false)
    }
}

extension FavoriteListViewController: OAOpenAddTrackDelegate {
    func onFileSelected(_ gpxFilePath: String) {
        if let addToTrackFavoriteItems {
            OAFavoritesBridgeHelper.addFavoriteItems(toTrack: addToTrackFavoriteItems, gpxFileName: gpxFilePath)
            self.addToTrackFavoriteItems = nil
        } else if let addToTrackGroupName {
            OAFavoritesBridgeHelper.addFavoriteGroup(toTrack: addToTrackGroupName, gpxFileName: gpxFilePath)
            self.addToTrackGroupName = nil
        }
    }
}

extension FavoriteListViewController: OAEditorDelegate {
    func addNewItem(withName name: String?, iconName: String, color: UIColor, backgroundIconName: String) {
        guard OAFavoritesBridgeHelper.addFavoriteGroup(name ?? "",
                                                      parentGroupName: parentGroupName,
                                                      iconName: iconName,
                                                      color: color,
                                                      backgroundIconName: backgroundIconName) else { return }
        applySnapshot(animatingDifferences: true)
    }

    func onEditorUpdated() {
        if let oldGroupName = favoriteGroupAppearanceGroupName, let newGroupName = favoriteGroupAppearanceEditor?.editName {
            renameFavoriteSortModeKeys(from: oldGroupName, to: newGroupName)
        }

        favoriteGroupAppearanceGroupName = nil
        favoriteGroupAppearanceEditor = nil
        OAFavoritesBridgeHelper.invalidateFavoriteFoldersCache()
    }

    func selectColorItem(_ colorItem: PaletteItemSolid) {}

    @discardableResult
    func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid {
        guard let newColorItem = appearanceCollection.addNewSelectedColor(color) else {
            return appearanceCollection.defaultPointColorItem()
        }

        return newColorItem
    }

    func changeColorItem(_ colorItem: PaletteItemSolid, with color: UIColor) {
        appearanceCollection.changeColor(colorItem, newColor: color)
    }

    @discardableResult
    func duplicateColorItem(_ colorItem: PaletteItemSolid) -> PaletteItemSolid {
        guard let duplicatedColorItem = appearanceCollection.duplicateColor(colorItem) else {
            return colorItem
        }

        return duplicatedColorItem
    }

    func deleteColorItem(_ colorItem: PaletteItemSolid) {
        appearanceCollection.deleteColor(colorItem)
    }
}

extension FavoriteListViewController: OAEditPointViewControllerDelegate {
    func saveTapped() {
        OAFavoritesBridgeHelper.invalidateFavoriteFoldersCache()
        applySnapshot()
    }
}

extension FavoriteListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        OARootViewController.instance().import(asFavorites: url)
    }
}

extension FavoriteListViewController: BackupBannerCollectionViewCellDelegate {
    func didClose() {
        closeFreeBackupBanner()
    }
    
    func didOpenOsmAndCloud() {
        navigationController?.pushViewController(OACloudIntroductionViewController(), animated: true)
    }
    
    func backupBannerHeight(_ banner: FreeBackupBanner, fittingWidth: CGFloat) -> CGFloat {
        let fallbackWidth = collectionView.bounds.width - collectionView.layoutMargins.left - collectionView.layoutMargins.right
        let bannerWidth = fittingWidth > 0.0 ? fittingWidth : fallbackWidth
        let textWidth = max(0.0, bannerWidth - CGFloat(banner.leadingTrailingOffset))
        let titleHeight = OAUtilities.calculateTextBounds(banner.titleLabel.text ?? "", width: textWidth, font: banner.titleLabel.font).height
        let descriptionHeight = OAUtilities.calculateTextBounds(banner.descriptionLabel.text ?? "", width: textWidth, font: banner.descriptionLabel.font).height
        return ceil(CGFloat(banner.defaultFrameHeight) + titleHeight + descriptionHeight)
    }
}
