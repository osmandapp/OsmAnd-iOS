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
        RowCellRegistration<FavoriteFolderRow> { [weak self] cell, _, folder in
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
            cell.accessories = self?.collectionView.isEditing == true ? [.multiselect()] : [.multiselect(), .disclosureIndicator()]
        }
    }

    var favoriteCellRegistration: RowCellRegistration<FavoritePointRow> {
        RowCellRegistration<FavoritePointRow> { [weak self] cell, _, favorite in
            if let self, !self.currentSortMode.isDistanceOriented {
                favorite.bridgeItem.updateDistanceAndDirection()
            }
            var content = cell.defaultContentConfiguration()
            content.image = OAUtilities.resize(favorite.bridgeItem.icon(), newSize: CGSize(width: Self.favoriteIconSize, height: Self.favoriteIconSize))
            content.text = favorite.title
            content.textProperties.numberOfLines = 2
            content.textProperties.color = favorite.titleColor
            content.textProperties.font = favorite.titleFont
            content.secondaryAttributedText = self?.favoriteSecondaryAttributedText(for: favorite, includesGroupName: self?.isSearchResultsMode == true)
            content.secondaryTextProperties.color = .textColorSecondary
            content.secondaryTextProperties.numberOfLines = 1
            cell.contentConfiguration = content
            cell.backgroundConfiguration = self?.listCellBackgroundConfiguration()
            cell.accessories = [.multiselect()]
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
                  let cell = collectionView.cellForItem(at: indexPath) as? FavoriteListCell,
                  var content = cell.contentConfiguration as? UIListContentConfiguration else {
                continue
            }

            favorite.bridgeItem.updateDistanceAndDirection()
            content.secondaryAttributedText = favoriteSecondaryAttributedText(for: favorite, includesGroupName: isSearchResultsMode)
            cell.contentConfiguration = content
        }
    }

    private func favoriteSecondaryAttributedText(for favorite: FavoritePointRow, includesGroupName: Bool) -> NSAttributedString {
        let font = UIFont.scaledSystemFont(ofSize: 15)
        let directionAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.textColorDirectionActive
        ]
        let secondaryAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.textColorSecondary
        ]

        let result = NSMutableAttributedString()
        let date = favorite.lastModified.map { DateFormatter.detailsDateFormatter.string(from: $0) }
        let groupName = favorite.bridgeItem.groupName.isEmpty ? localizedString("shared_string_favorites") : favorite.bridgeItem.groupName

        if currentSortMode.isDateOriented {
            appendFavoriteSecondaryText(date, to: result, attributes: secondaryAttributes)
            appendFavoriteDistance(favorite,
                                   to: result,
                                   font: font,
                                   directionAttributes: directionAttributes,
                                   separatorAttributes: secondaryAttributes)
            appendFavoriteSecondaryText(favorite.bridgeItem.address, to: result, attributes: secondaryAttributes)
        } else {
            appendFavoriteDistance(favorite,
                                   to: result,
                                   font: font,
                                   directionAttributes: directionAttributes,
                                   separatorAttributes: secondaryAttributes)
            appendFavoriteSecondaryText(favorite.bridgeItem.address, to: result, attributes: secondaryAttributes)
            appendFavoriteSecondaryText(date, to: result, attributes: secondaryAttributes)
        }
        if includesGroupName {
            appendFavoriteSecondaryText(groupName, to: result, attributes: secondaryAttributes)
        }

        return result
    }

    private func appendFavoriteSecondaryText(_ text: String?, to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard let text, !text.isEmpty else { return }
        appendFavoriteSecondarySeparatorIfNeeded(to: result, attributes: attributes)
        result.append(NSAttributedString(string: text, attributes: attributes))
    }

    private func appendFavoriteDistance(_ favorite: FavoritePointRow,
                                        to result: NSMutableAttributedString,
                                        font: UIFont,
                                        directionAttributes: [NSAttributedString.Key: Any],
                                        separatorAttributes: [NSAttributedString.Key: Any]) {
        guard let distance = favorite.distance, let formattedDistance = OAOsmAndFormatter.getFormattedDistance(Float(distance)) else { return }
        appendFavoriteSecondarySeparatorIfNeeded(to: result, attributes: separatorAttributes)
        if let directionIcon = favoriteDirectionIcon(tintColor: .iconColorDirectionActive) {
            let rotatedDirectionIcon = directionIcon.rotatedWithinBounds(by: favorite.bridgeItem.direction)
            let attachment = NSTextAttachment()
            attachment.image = rotatedDirectionIcon
            attachment.bounds = CGRect(x: 0.0,
                                       y: (font.capHeight - rotatedDirectionIcon.size.height) / 2.0,
                                       width: rotatedDirectionIcon.size.width,
                                       height: rotatedDirectionIcon.size.height)
            result.append(NSAttributedString(attachment: attachment))
        }
        result.append(NSAttributedString(string: formattedDistance, attributes: directionAttributes))
    }

    private func appendFavoriteSecondarySeparatorIfNeeded(to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard result.length > 0 else { return }
        result.append(NSAttributedString(string: " • ", attributes: attributes))
    }

    private func favoriteDirectionIcon(tintColor: UIColor) -> UIImage? {
        let size = UIFontMetrics.default.scaledValue(for: 18.0)
        return OAUtilities.resize(.icSmallDirection, newSize: CGSize(width: size, height: size))?.withTintColor(tintColor)
    }
}
