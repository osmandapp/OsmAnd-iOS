//
//  FavoriteListViewController+Cells.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

extension FavoriteListViewController {
    var headerCellRegistration: CellRegistration<FavoriteFolderSection> {
        CellRegistration<FavoriteFolderSection> { cell, _, section in
            var content = cell.defaultContentConfiguration()
            content.text = section.title
            content.textProperties.color = .textColorPrimary
            content.textProperties.font = .systemFont(ofSize: 20, weight: .semibold)
            cell.contentConfiguration = content
            let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
            cell.tintColor = .iconColorActive
        }
    }

    var sortHeaderCellRegistration: UICollectionView.CellRegistration<SortButtonCollectionViewCell, FavoriteSortHeader> {
        UICollectionView.CellRegistration<SortButtonCollectionViewCell, FavoriteSortHeader> { [weak self] cell, _, sortHeader in
            cell.sortButton.setImage(sortHeader.sortMode.image?.resizedMenuImage(), for: .normal)
            cell.sortButton.menu = self?.makeSortMenu(includesDistanceSortModes: sortHeader.includesDistanceSortModes)
        }
    }

    var backupBannerCellRegistration: UICollectionView.CellRegistration<BackupBannerCollectionViewCell, FavoriteListItem> {
        UICollectionView.CellRegistration<BackupBannerCollectionViewCell, FavoriteListItem> { [weak self] cell, _, _ in
            cell.delegate = self
        }
    }

    var folderCellRegistration: RowCellRegistration<FavoriteFolderRow> {
        RowCellRegistration<FavoriteFolderRow> { [weak self] cell, indexPath, folder in
            var content = cell.defaultContentConfiguration()
            content.image = (folder.isPinned ? .icCustomFolderPin : UIImage.templateImageNamed(folder.iconName))?.resizedTemplateImage(with: FavoriteListViewController.imageSize)
            content.imageProperties.tintColor = folder.iconColor
            content.text = folder.title
            content.textProperties.color = folder.titleColor
            content.textProperties.font = folder.titleFont
            content.textProperties.numberOfLines = 2
            content.secondaryText = folder.subtitle
            content.secondaryTextProperties.color = .textColorSecondary
            cell.contentConfiguration = content
            cell.backgroundConfiguration = self?.listCellBackgroundConfiguration()
            cell.accessories = [.multiselect(), .disclosureIndicator(displayed: .whenNotEditing)]
            self?.updateVisibleSelectionState(at: indexPath)
        }
    }

    var favoriteCellRegistration: RowCellRegistration<FavoritePointRow> {
        RowCellRegistration<FavoritePointRow> { [weak self] cell, indexPath, favorite in
            guard let self else { return }
            if !currentSortMode.isDistanceOriented {
                favorite.bridgeItem.updateDistanceAndDirection()
            }
            cell.contentConfiguration = favoriteContentConfiguration(for: favorite)
            cell.backgroundConfiguration = PointContentConfiguration.backgroundConfiguration()
            cell.accessories = [.multiselect()]
            updateVisibleSelectionState(at: indexPath)
        }
    }

    var statsFooterCellRegistration: UICollectionView.CellRegistration<StatsFooterCollectionViewCell, FavoriteFolderStats> {
        UICollectionView.CellRegistration<StatsFooterCollectionViewCell, FavoriteFolderStats> { cell, _, stats in
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            cell.label.text = stats.text
        }
    }

    var emptyStateCellRegistration: UICollectionView.CellRegistration<EmptyStateCollectionViewCell, Void> {
        UICollectionView.CellRegistration<EmptyStateCollectionViewCell, Void>(cellNib: UINib(nibName: EmptyStateCollectionViewCell.reuseIdentifier, bundle: nil)) { [weak self] cell, _, _ in
            guard let self else { return }
            cell.button.removeTarget(nil, action: nil, for: .touchUpInside)
            if self.isSearchResultsMode {
                cell.configure(image: .icCustomSearch,
                               title: localizedString("no_search_results"),
                               description: localizedString("favorite_search_empty_state_description"))
                cell.button.setTitle(localizedString("shared_string_clear_all"), for: .normal)
                cell.button.addTarget(self, action: #selector(self.clearSearchButtonClicked), for: .touchUpInside)
                return
            }

            let isRootFolder = self.isRootFolder
            cell.configure(image: isRootFolder ? .icCustomFavorites : .icCustomFolderOpen,
                           title: localizedString(isRootFolder ? "empty_state_favourites" : "tracks_empty_folder"),
                           description: localizedString(isRootFolder ? "empty_state_favourites_desc" : "tracks_empty_folder_description"))
            cell.button.setTitle(localizedString("shared_string_import"), for: .normal)
            cell.button.addTarget(self, action: #selector(self.importButtonClicked), for: .touchUpInside)
        }
    }

    func updateVisibleFavoriteCellsDistanceAndDirection() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard case .favorite(let favorite) = dataSource.itemIdentifier(for: indexPath),
                  let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell,
                  var configuration = cell.contentConfiguration as? PointContentConfiguration else {
                continue
            }

            favorite.bridgeItem.updateDistanceAndDirection()
            configuration.secondaryContent = favoriteSecondaryContent(for: favorite)
            cell.contentConfiguration = configuration
        }
    }

    private func favoriteContentConfiguration(for favorite: FavoritePointRow) -> PointContentConfiguration {
        PointContentConfiguration(icon: favorite.bridgeItem.icon(), title: favorite.title, isVisible: favorite.bridgeItem.isVisible, secondaryContent: favoriteSecondaryContent(for: favorite))
    }

    private func favoriteSecondaryContent(for favorite: FavoritePointRow) -> PointSecondaryContent {
        let date = favorite.lastModified.map { DateFormatter.detailsDateFormatter.string(from: $0) }
        let formattedDistance = favorite.distance.flatMap { OAOsmAndFormatter.getFormattedDistance(Float($0)) }
        let directionColor: UIColor = currentSortMode.isMapCenterDistanceOriented ? .iconColorDirectionMapCenter : .iconColorDirectionActive
        var groupName: String?
        if isSearchResultsMode {
            groupName = favorite.bridgeItem.groupName.isEmpty ? localizedString("shared_string_favorites") : favorite.bridgeItem.groupName
        }

        return PointSecondaryContent(formattedDistance: formattedDistance, direction: favorite.bridgeItem.direction, directionColor: directionColor, address: favorite.bridgeItem.address, date: date, trailingText: groupName, isDateFirst: currentSortMode.isDateOriented)
    }
}
