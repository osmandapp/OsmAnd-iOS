//
//  FavoriteListViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

private enum ScreenMode {
    case root
    case folder(FavoriteFolderRow, previousTitle: String)
}

private enum FavoriteFolderSection: Hashable {
    case pinned
    case visible
    case hidden

    var title: String {
        switch self {
        case .pinned:
            localizedString("shared_string_pinned")
        case .visible:
            localizedString("shared_string_visible")
        case .hidden:
            localizedString("shared_string_hidden")
        }
    }
}

private enum FavoriteListSection: Hashable {
    case backupBanner
    case folderSection(FavoriteFolderSection)
    case content
}

private enum FavoriteListItem: Hashable {
    case backupBanner
    case header(FavoriteFolderSection)
    case folder(FavoriteFolderRow)
    case favorite(FavoritePointRow)
}

private struct FavoriteFolderRow: Hashable {
    let identifier: String
    let groupName: String
    let title: String
    let pointsCount: Int
    let isVisible: Bool
    let isPinned: Bool
    let color: UIColor?

    var iconName: String {
        isVisible ? "ic_custom_folder" : "ic_custom_folder_hidden_outlined"
    }

    var iconColor: UIColor {
        isVisible ? (color ?? .iconColorSelected) : .iconColorSecondary
    }

    var titleColor: UIColor {
        isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(item: OAFavoriteFolderBridgeItem) {
        identifier = item.identifier
        groupName = item.groupName
        title = Self.title(for: item.groupName, fallback: item.title)
        pointsCount = Int(item.pointsCount)
        isVisible = item.isVisible
        isPinned = item.isPinned
        color = item.color
    }

    private static func title(for groupName: String, fallback: String) -> String {
        guard !groupName.isEmpty else { return fallback }
        return groupName.components(separatedBy: "/").last ?? fallback
    }
}

private struct FavoritePointRow: Hashable {
    let identifier: String
    let title: String
    let subtitle: String?
    let icon: UIImage?
    let isVisible: Bool

    var titleColor: UIColor {
        isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(item: OAFavoritePointBridgeItem) {
        identifier = item.identifier
        title = item.title
        subtitle = item.subtitle
        icon = item.icon
        isVisible = item.isVisible
    }
}

final class FavoriteListViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<FavoriteListSection, FavoriteListItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<FavoriteListSection, FavoriteListItem>
    private typealias CellRegistration<Item> = UICollectionView.CellRegistration<UICollectionViewListCell, Item>

    weak var myPlacesDelegate: MyPlacesDelegate?

    private static let imageSize: CGFloat = 30.0
    private static let favoriteIconSize: CGFloat = 36.0
    private static let navigationTitleFontSize: CGFloat = 17.0
    private static let navigationTitleMaximumSize: CGFloat = 22.0
    private static let navigationSubtitleFontSize: CGFloat = 12.0
    private static let navigationSubtitleMaximumSize: CGFloat = 18.0
    private static let rowContentInsets = NSDirectionalEdgeInsets(top: 12.0, leading: 0.0, bottom: 12.0, trailing: 0.0)
    private static let wasClosedFreeBackupFavoritesBannerKey = "wasClosedFreeBackupFavoritesBanner"

    private let screenMode: ScreenMode
    private var layoutSections: [FavoriteListSection] = []

    private var searchText = ""
    private var isSearchActive = false
    private var isAvailablePaymentBanner: Bool {
        isRootFolder && !UserDefaults.standard.bool(forKey: Self.wasClosedFreeBackupFavoritesBannerKey) && !OAIAPHelper.isOsmAndProAvailable() && !OABackupHelper.sharedInstance().isRegistered()
    }
    private var isRootFolder: Bool {
        guard case .root = screenMode else { return false }
        return true
    }
    private var normalTitle: String {
        switch screenMode {
        case .root:
            localizedString("shared_string_favorites")
        case .folder(let folder, _):
            folder.title
        }
    }
    private var normalSubtitle: String {
        switch screenMode {
        case .root:
            localizedString("shared_string_my_places")
        case .folder(_, let previousTitle):
            previousTitle
        }
    }
    private var parentGroupName: String? {
        guard case .folder(let folder, _) = screenMode, !folder.groupName.isEmpty else { return nil }
        return folder.groupName
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.tintColor = .iconColorActive
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelectionDuringEditing = true
        return collectionView
    }()
    private lazy var headerCellRegistration = CellRegistration<FavoriteFolderSection> { cell, _, section in
        var content = cell.defaultContentConfiguration()
        content.text = section.title
        content.textProperties.color = .textColorPrimary
        content.textProperties.font = .systemFont(ofSize: 20, weight: .semibold)
        cell.contentConfiguration = content
        let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
        cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
        cell.tintColor = .iconColorActive
    }
    private lazy var backupBannerCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, FavoriteListItem> { [weak self] cell, _, _ in
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        guard let self, let banner = Bundle.main.loadNibNamed("FreeBackupBanner", owner: self)?.first as? FreeBackupBanner else { return }
        banner.configure(bannerType: .favorite)
        banner.didOsmAndCloudButtonAction = { [weak self] in
            self?.navigationController?.pushViewController(OACloudIntroductionViewController(), animated: true)
        }
        banner.didCloseButtonAction = { [weak self] in
            self?.closeFreeBackupBanner()
        }
        banner.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(banner)
        let fittingWidth = cell.contentView.bounds.width > 0.0 ? cell.contentView.bounds.width : cell.bounds.width
        NSLayoutConstraint.activate([banner.topAnchor.constraint(equalTo: cell.contentView.topAnchor), banner.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor), banner.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)])
        NSLayoutConstraint.activate([banner.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor), banner.heightAnchor.constraint(equalToConstant: self.backupBannerHeight(banner, fittingWidth: fittingWidth))])
    }
    private lazy var folderCellRegistration = CellRegistration<FavoriteFolderRow> { [weak self] cell, _, folder in
        var content = cell.defaultContentConfiguration()
        content.directionalLayoutMargins = Self.rowContentInsets
        content.image = UIImage.templateImageNamed(folder.iconName)?.resizedTemplateImage(with: FavoriteListViewController.imageSize)
        content.imageProperties.tintColor = folder.iconColor
        content.text = folder.title
        content.textProperties.color = folder.titleColor
        content.textProperties.font = folder.titleFont
        content.secondaryText = "\(localizedString("points_count")) \(folder.pointsCount)"
        content.secondaryTextProperties.color = .textColorSecondary
        cell.contentConfiguration = content
        cell.accessories = self?.collectionView.isEditing == true ? [.multiselect()] : [.multiselect(), .disclosureIndicator()]
    }
    private lazy var favoriteCellRegistration = CellRegistration<FavoritePointRow> { cell, _, favorite in
        var content = cell.defaultContentConfiguration()
        content.directionalLayoutMargins = Self.rowContentInsets
        content.image = OAUtilities.resize(favorite.icon, newSize: CGSize(width: Self.favoriteIconSize, height: Self.favoriteIconSize))
        content.text = favorite.title
        content.textProperties.color = favorite.titleColor
        content.textProperties.font = favorite.titleFont
        content.secondaryText = favorite.subtitle
        content.secondaryTextProperties.color = .textColorSecondary
        cell.contentConfiguration = content
        cell.accessories = [.multiselect()]
    }
    private lazy var subfolderSearchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchTextField.placeholder = localizedString("search_activity")
        return searchController
    }()
    private lazy var dataSource: DataSource = makeDataSource()

    convenience init(frame: CGRect) {
        self.init(frame: frame, screenMode: .root)
    }

    private init(frame: CGRect, screenMode: ScreenMode) {
        self.screenMode = screenMode
        super.init(nibName: nil, bundle: nil)
        view.frame = frame
    }

    required init?(coder: NSCoder) {
        screenMode = .root
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        configureCollectionView()
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteDataDidChange), name: .favoriteImportViewControllerDidDismiss, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(productPurchased), name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .favoriteImportViewControllerDidDismiss, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigation()
        navigationController?.setToolbarHidden(true, animated: false)
        configureToolbar()
        applySnapshot()
    }

    private func configureCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([collectionView.topAnchor.constraint(equalTo: view.topAnchor), collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor), collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor), collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            let section = self?.layoutSections.indices.contains(sectionIndex) == true ? self?.layoutSections[sectionIndex] : nil
            configuration.headerMode = self?.isRootFolder == true && section != .backupBanner ? .firstItemInSection : .none
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }

    private func configureNavigation() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = false
        configureNavigationButtons()
        configureSearchVisibility()
        updateNavigationBarTitle()
        updateSegmentedControlVisibility()
    }

    private func configureNavigationButtons() {
        let targetNavigationItem = isRootFolder ? navigationController?.navigationBar.topItem : navigationItem
        if collectionView.isEditing {
            let cancelButton = UIBarButtonItem(title: localizedString("shared_string_cancel"), style: .plain, target: self, action: #selector(cancelButtonPressed))
            cancelButton.accessibilityLabel = localizedString("shared_string_cancel")
            let selectAllButton = UIBarButtonItem(title: localizedString("shared_string_select_all"), style: .plain, target: self, action: #selector(selectAllButtonPressed))
            selectAllButton.accessibilityLabel = localizedString("shared_string_select_all")
            targetNavigationItem?.leftBarButtonItem = cancelButton
            targetNavigationItem?.rightBarButtonItems = [selectAllButton]
            if isRootFolder {
                myPlacesDelegate?.showBackButton(false)
            } else {
                self.navigationItem.hidesBackButton = true
            }
        } else {
            let selectButton = UIBarButtonItem(title: localizedString("shared_string_select"), style: .plain, target: self, action: #selector(selectButtonPressed))
            selectButton.accessibilityLabel = localizedString("shared_string_select")
            let actionsButton = UIBarButtonItem(image: .icNavbarOverflowMenuOutlined, menu: makeActionsMenu())
            actionsButton.accessibilityLabel = localizedString("shared_string_actions")
            targetNavigationItem?.leftBarButtonItem = nil
            targetNavigationItem?.rightBarButtonItems = [actionsButton, selectButton]
            if isRootFolder {
                myPlacesDelegate?.showBackButton(true)
            } else {
                self.navigationItem.hidesBackButton = false
            }
        }
    }

    private func configureSearchVisibility() {
        guard !isRootFolder else {
            navigationController?.navigationBar.topItem?.hidesSearchBarWhenScrolling = false
            return
        }

        if #available(iOS 26.0, *), !OAUtilities.isIPad() {
            navigationItem.preferredSearchBarPlacement = .stacked
        }

        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = collectionView.isEditing ? nil : subfolderSearchController
    }

    private func configureToolbar() {
        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let actionsFixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let shareButton = UIBarButtonItem(image: .icCustomExportOutlined, style: .plain, target: self, action: #selector(shareButtonClicked))
        let moveButton = UIBarButtonItem(image: .icCustomFolderMoveOutlined, style: .plain, target: self, action: #selector(moveButtonClicked))
        let actionsButton = UIBarButtonItem(image: .icNavbarOverflowMenuOutlined, style: .plain, target: self, action: #selector(actionsButtonClicked))
        let deleteButton = UIBarButtonItem(image: .icCustomTrashOutlined, style: .plain, target: self, action: #selector(deleteButtonClicked))
        deleteButton.tintColor = .iconColorDisruptive
        let items = [shareButton, fixedSpacer, moveButton, actionsFixedSpacer, actionsButton, flexibleSpacer, deleteButton]
        if isRootFolder {
            myPlacesDelegate?.updateToolbar?(with: items)
        } else {
            toolbarItems = items
        }
    }

    private func updateNavigationBarTitle() {
        if collectionView.isEditing {
            let selectedItemsCount = collectionView.indexPathsForSelectedItems?.count ?? 0
            let itemText = localizedString(selectedItemsCount > 1 ? "shared_string_items" : "shared_string_item").lowercased()
            let title = selectedItemsCount == 0 ? localizedString("select_items") : "\(selectedItemsCount) \(itemText)"
            setNavigationTitle(title, subtitle: "", hideSubtitle: true)
        } else {
            setNavigationTitle(normalTitle, subtitle: normalSubtitle, hideSubtitle: false)
        }
    }

    private func setNavigationTitle(_ title: String, subtitle: String, hideSubtitle: Bool) {
        if isRootFolder {
            myPlacesDelegate?.updateTitle?(title, hideSubtitle: hideSubtitle)
        } else {
            navigationItem.setStackViewWithTitle(title, titleColor: .textColorPrimary, titleFont: .scaledSystemFont(ofSize: Self.navigationTitleFontSize, weight: .semibold, maximumSize: Self.navigationTitleMaximumSize), subtitle: hideSubtitle ? "" : subtitle, subtitleColor: .textColorSecondary, subtitleFont: .scaledSystemFont(ofSize: Self.navigationSubtitleFontSize, maximumSize: Self.navigationSubtitleMaximumSize))
        }
    }

    private func updateSegmentedControlVisibility() {
        myPlacesDelegate?.updateSegmentedControlVisibility(isRootFolder && !collectionView.isEditing && !isSearchActive)
    }

    private func makeDataSource() -> DataSource {
        let backupBannerCellRegistration = backupBannerCellRegistration
        let folderCellRegistration = folderCellRegistration
        let favoriteCellRegistration = favoriteCellRegistration
        let headerCellRegistration = headerCellRegistration
        return DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .backupBanner:
                return collectionView.dequeueConfiguredReusableCell(using: backupBannerCellRegistration, for: indexPath, item: item)
            case .header(let section):
                return collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: section)
            case .folder(let folder):
                return collectionView.dequeueConfiguredReusableCell(using: folderCellRegistration, for: indexPath, item: folder)
            case .favorite(let favorite):
                return collectionView.dequeueConfiguredReusableCell(using: favoriteCellRegistration, for: indexPath, item: favorite)
            }
        }
    }

    private func applySnapshot(animatingDifferences: Bool = false) {
        switch screenMode {
        case .root:
            applyRootSnapshot(animatingDifferences: animatingDifferences)
        case .folder(let folder, _):
            applyFolderSnapshot(folder: folder, animatingDifferences: animatingDifferences)
        }
    }

    private func applyRootSnapshot(animatingDifferences: Bool) {
        let foldersBySection = favoriteFoldersBySection()
        let folderSections = rootSections(foldersBySection: foldersBySection)
        let isPaymentBannerVisible = isAvailablePaymentBanner
        var snapshot = Snapshot()
        var sections = folderSections.map { FavoriteListSection.folderSection($0) }
        if isPaymentBannerVisible {
            sections.insert(.backupBanner, at: 0)
        }
        
        layoutSections = sections
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections(sections)
        if isPaymentBannerVisible {
            snapshot.appendItems([.backupBanner], toSection: .backupBanner)
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
        let folders = directFavoriteFolders(parentGroupName: folder.groupName).filter { matchesSearch($0.title) }
        let favorites = OAFavoriteFoldersBridge.favoritePoints(forGroupName: folder.groupName).map { FavoritePointRow(item: $0) }.filter { matchesSearch($0.title) || matchesSearch($0.subtitle) }
        var snapshot = Snapshot()
        layoutSections = [.content]
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections([.content])
        snapshot.appendItems(folders.map(FavoriteListItem.folder), toSection: .content)
        snapshot.appendItems(favorites.map(FavoriteListItem.favorite), toSection: .content)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func favoriteFoldersBySection() -> [FavoriteFolderSection: [FavoriteFolderRow]] {
        let folders = directFavoriteFolders(parentGroupName: nil).filter { matchesSearch($0.title) }
        return [.pinned: folders.filter { $0.isPinned }, .visible: folders.filter { $0.isVisible && !$0.isPinned }, .hidden: folders.filter { !$0.isVisible && !$0.isPinned }]
    }

    private func rootSections(foldersBySection: [FavoriteFolderSection: [FavoriteFolderRow]]) -> [FavoriteFolderSection] {
        var sections: [FavoriteFolderSection] = []
        if !(foldersBySection[.pinned] ?? []).isEmpty {
            sections.append(.pinned)
        }

        if !isSearchActive || !(foldersBySection[.visible] ?? []).isEmpty {
            sections.append(.visible)
        }

        if !(foldersBySection[.hidden] ?? []).isEmpty {
            sections.append(.hidden)
        }

        return sections
    }

    private func backupBannerHeight(_ banner: FreeBackupBanner, fittingWidth: CGFloat) -> CGFloat {
        let fallbackWidth = collectionView.bounds.width - collectionView.layoutMargins.left - collectionView.layoutMargins.right
        let bannerWidth = fittingWidth > 0.0 ? fittingWidth : fallbackWidth
        let textWidth = max(0.0, bannerWidth - CGFloat(banner.leadingTrailingOffset))
        let titleHeight = OAUtilities.calculateTextBounds(banner.titleLabel.text ?? "", width: textWidth, font: banner.titleLabel.font).height
        let descriptionHeight = OAUtilities.calculateTextBounds(banner.descriptionLabel.text ?? "", width: textWidth, font: banner.descriptionLabel.font).height
        return ceil(CGFloat(banner.defaultFrameHeight) + titleHeight + descriptionHeight)
    }
    
    private func closeFreeBackupBanner() {
        UserDefaults.standard.set(true, forKey: Self.wasClosedFreeBackupFavoritesBannerKey)
        applySnapshot(animatingDifferences: true)
    }

    private func directFavoriteFolders(parentGroupName: String?) -> [FavoriteFolderRow] {
        OAFavoriteFoldersBridge.favoriteFolders()
            .map { FavoriteFolderRow(item: $0) }
            .filter { isDirectFolder($0.groupName, parentGroupName: parentGroupName) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func isDirectFolder(_ groupName: String, parentGroupName: String?) -> Bool {
        guard let parentGroupName else { return groupName.isEmpty || !groupName.contains("/") }
        guard !parentGroupName.isEmpty else { return false }
        guard groupName.hasPrefix(parentGroupName + "/") else { return false }
        let childPath = groupName.dropFirst(parentGroupName.count + 1)
        return !childPath.isEmpty && !childPath.contains("/")
    }

    private func matchesSearch(_ text: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return text?.localizedCaseInsensitiveContains(searchText) ?? false
    }

    private func makeActionsMenu() -> UIMenu {
        let addFolderAction = UIAction(title: localizedString("add_new_folder"), image: .icCustomFolderAddOutlined.resizedMenuImage()) { [weak self] _ in
            guard let self, let navigationController = self.navigationController else { return }
            OAFavoriteFoldersBridge.openNewFavoriteGroupEditor(withParentGroupName: self.parentGroupName, navigationController: navigationController) { [weak self] in
                self?.applySnapshot(animatingDifferences: true)
            }
        }
        let importAction = UIAction(title: localizedString("shared_string_import"), image: .icCustomImportOutlined.resizedMenuImage()) { [weak self] _ in
            guard let self else { return }
            let gpxType = UTType(importedAs: "com.topografix.gpx", conformingTo: .xml)
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [gpxType], asCopy: true)
            documentPicker.allowsMultipleSelection = false
            documentPicker.delegate = self
            present(documentPicker, animated: true)
        }
        
        let addFolderSection = UIMenu(title: "", options: .displayInline, children: [addFolderAction])
        let importSection = UIMenu(title: "", options: .displayInline, children: [importAction])
        return UIMenu(title: "", children: [addFolderSection, importSection])
    }

    private func setEdit(_ isEdit: Bool) {
        if !isEdit {
            collectionView.indexPathsForSelectedItems?.forEach { collectionView.deselectItem(at: $0, animated: false) }
        }

        collectionView.isEditing = isEdit
        collectionView.reloadData()
        myPlacesDelegate?.updateEditMode(isEdit)
        configureNavigation()
        navigationController?.setToolbarHidden(!isEdit, animated: true)
    }

    private func makeFolderContextMenu(for folder: FavoriteFolderRow, indexPath: IndexPath) -> UIMenu {
        let showHideAction = UIAction(title: localizedString(folder.isVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: menuImage(folder.isVisible ? "ic_custom_hide_outlined" : "ic_custom_show_outlined")) { [weak self] _ in
            OAFavoriteFoldersBridge.setFavoriteGroupVisible(folder.groupName, visible: !folder.isVisible)
            self?.applySnapshot(animatingDifferences: true)
        }
        let pinAction = UIAction(title: localizedString(folder.isPinned ? "unpin_folder" : "pin_folder"), image: menuImage("ic_custom_map_pin_outlined")) { [weak self] _ in
            OAFavoriteFoldersBridge.setFavoriteGroupPinned(folder.groupName, pinned: !folder.isPinned)
            self?.applySnapshot(animatingDifferences: true)
        }
        let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showHideAction, pinAction])

        let renameAction = UIAction(title: localizedString("shared_string_rename"), image: menuImage("ic_custom_edit")) { [weak self] _ in
            self?.showRenameAlert(for: folder)
        }
        let defaultAppearanceAction = UIAction(title: localizedString("default_appearance"), image: menuImage("ic_custom_appearance_outlined")) { [weak self] _ in
            guard let navigationController = self?.navigationController else { return }
            OAFavoriteFoldersBridge.openFavoriteGroupAppearance(folder.groupName, navigationController: navigationController)
        }
        let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction, defaultAppearanceAction])

        let shareAction = UIAction(title: localizedString("shared_string_share"), image: menuImage("ic_custom_export_outlined")) { [weak self] _ in
            guard let self else { return }
            let sourceView: UIView = self.collectionView.cellForItem(at: indexPath) ?? self.collectionView
            OAFavoriteFoldersBridge.shareFavoriteGroup(folder.groupName, sourceView: sourceView, viewController: self)
        }
        let moveAction = UIAction(title: localizedString("shared_string_move"), image: menuImage("ic_custom_folder_move_outlined")) { [weak self] _ in
            guard let navigationController = self?.navigationController else { return }
            OAFavoriteFoldersBridge.openFavoriteGroupMove(folder.groupName, navigationController: navigationController) { [weak self] in
                self?.applySnapshot(animatingDifferences: true)
            }
        }
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: folder.groupName.isEmpty ? [shareAction] : [shareAction, moveAction])

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: menuImage("ic_custom_map_pin_outlined")) { _ in
            OAFavoriteFoldersBridge.addFavoriteGroup(toMapMarkers: folder.groupName)
        }
        let trackAction = UIAction(title: localizedString("add_to_a_track"), image: menuImage("ic_custom_trip")) { [weak self] _ in
            guard let navigationController = self?.navigationController else { return }
            OAFavoriteFoldersBridge.openFavoriteGroupAdd(toTrack: folder.groupName, navigationController: navigationController)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: menuImage("ic_custom_navigation_outlined")) { _ in
            OAFavoriteFoldersBridge.addFavoriteGroup(toNavigation: folder.groupName)
        }
        let addToMenu = UIMenu(title: localizedString("shared_string_add"), image: menuImage("ic_custom_add"), children: [mapMarkersAction, trackAction, navigationAction])
        let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])

        let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: menuImage("ic_custom_trash_outlined"), attributes: .destructive) { [weak self] _ in
            self?.showDeleteAlert(for: folder)
        }
        let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        return UIMenu(title: "", children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection])
    }

    private func showRenameAlert(for folder: FavoriteFolderRow) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self, weak alert] _ in
            guard let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            let newGroupName = self?.groupName(folder.groupName, replacingLastComponentWith: text) ?? text
            OAFavoriteFoldersBridge.renameFavoriteGroup(folder.groupName, newName: newGroupName)
            self?.applySnapshot(animatingDifferences: true)
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

    private func groupName(_ groupName: String, replacingLastComponentWith lastComponent: String) -> String {
        guard let separatorIndex = groupName.lastIndex(of: "/") else { return lastComponent }
        let parentGroupName = groupName[..<separatorIndex]
        guard !parentGroupName.isEmpty else { return lastComponent }
        return "\(parentGroupName)/\(lastComponent)"
    }

    private func showDeleteAlert(for folder: FavoriteFolderRow) {
        let alert = UIAlertController(title: nil, message: localizedString("fav_remove_q"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_yes"), style: .destructive) { [weak self] _ in
            OAFavoriteFoldersBridge.deleteFavoriteGroup(folder.groupName)
            self?.applySnapshot(animatingDifferences: true)
        })

        alert.addAction(UIAlertAction(title: localizedString("shared_string_no"), style: .cancel))
        present(alert, animated: true)
    }

    private func shareItems(_ selectedItems: [IndexPath], sourceView: UIView) {
        if selectedItems.isEmpty {
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

        // TODO
//        guard let favoritesUrl = OAFavoriteFoldersBridge.shareFavoriteItems(bridgeItems(for: selectedItems)) else { return }
//        showActivity(
//            [favoritesUrl],
//            sourceView: sourceView,
//            barButtonItem: nil,
//            completionWithItemsHandler: {
//                try? FileManager.default.removeItem(at: favoritesUrl)
//            }
//        )
    }

    private func menuImage(_ name: String) -> UIImage? {
        UIImage(named: name)?.resizedMenuImage()
    }

    @objc private func selectButtonPressed() {
        setEdit(true)
    }

    @objc private func cancelButtonPressed() {
        setEdit(false)
    }

    @objc private func selectAllButtonPressed() {
        for section in 0..<collectionView.numberOfSections {
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else { continue }
                switch itemIdentifier {
                case .backupBanner, .header:
                    continue
                case .folder, .favorite:
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }
        }

        updateNavigationBarTitle()
    }

    @objc private func favoriteDataDidChange() {
        applySnapshot(animatingDifferences: true)
    }

    @objc private func productPurchased() {
        DispatchQueue.main.async { [weak self] in
            self?.applySnapshot(animatingDifferences: true)
        }
    }

    @objc private func shareButtonClicked(_ sender: Any) {
        // TODO
//        guard let items = collectionView.indexPathsForSelectedItems else {
//            return
//        }
//        let sourceView = sender as? UIView ?? collectionView
//        shareItems(items, sourceView: sourceView)
//        setEdit(false)
//        applySnapshot()
    }

    @objc private func moveButtonClicked(_ sender: Any) {
        guard let selectedItems = collectionView.indexPathsForSelectedItems, !selectedItems.isEmpty else {
            let alert = UIAlertController(title: "", message: localizedString("fav_select"), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: localizedString("shared_string_ok"), style: .default)
            alert.addAction(defaultAction)
            present(alert, animated: true)
            return
        }

        // TODO
        //guard let navigationController else { return }
//        OAFavoriteFoldersBridge.openFavoriteItemsMove(bridgeItems(for: selectedItems), navigationController: navigationController) { [weak self] in
//            self?.setEdit(false)
//            self?.applySnapshot(animatingDifferences: true)
//        }
    }

    @objc private func actionsButtonClicked(_ sender: Any) {
        // TODO
    }

    @objc private func deleteButtonClicked(_ sender: Any) {
        if collectionView.indexPathsForSelectedItems?.isEmpty == true {
            let alert = UIAlertController(title: nil, message: localizedString("fav_select_remove"), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: localizedString("ok"), style: .default)
            alert.addAction(defaultAction)
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(
            title: nil,
            message: localizedString("fav_remove_q"),
            preferredStyle: .alert
        )

        let yesButton = UIAlertAction(
            title: localizedString("shared_string_yes"),
            style: .default
        ) { _ in
            // TODO
            //self?.removeSelectedFavoriteItems()
        }

        let cancelButton = UIAlertAction(
            title: localizedString("shared_string_no"),
            style: .cancel,
            handler: nil
        )

        alert.addAction(yesButton)
        alert.addAction(cancelButton)

        present(alert, animated: true, completion: nil)
    }
}

extension FavoriteListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .folder(let folder):
            if collectionView.isEditing {
                updateNavigationBarTitle()
                return
            }
            let viewController = FavoriteListViewController(frame: view.bounds, screenMode: .folder(folder, previousTitle: normalTitle))
            viewController.myPlacesDelegate = myPlacesDelegate
            navigationController?.pushViewController(viewController, animated: true)
        case .favorite(let favorite):
            if collectionView.isEditing {
                updateNavigationBarTitle()
                return
            }
            OAFavoriteFoldersBridge.openFavoritePoint(withIdentifier: favorite.identifier)
        case .backupBanner, .header:
            break
        }

        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView.isEditing else { return }
        updateNavigationBarTitle()
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !collectionView.isEditing else { return nil }
        guard let item = dataSource.itemIdentifier(for: indexPath), case .folder(let folder) = item else { return nil }
        let menuProvider: UIContextMenuActionProvider = { [weak self] _ in
            self?.makeFolderContextMenu(for: folder, indexPath: indexPath)
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
    }
}

extension FavoriteListViewController: MyPlacesSearchable, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        searchResults(for: searchController)
    }

    func searchResults(for searchController: UISearchController) {
        isSearchActive = searchController.isActive
        searchText = searchController.searchBar.searchTextField.text ?? ""
        updateSegmentedControlVisibility()
        applySnapshot(animatingDifferences: false)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        searchText = ""
        updateSegmentedControlVisibility()
        applySnapshot(animatingDifferences: false)
    }
}

extension FavoriteListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        OARootViewController.instance().import(asFavorites: url)
    }
}

extension Notification.Name {
    static let favoriteImportViewControllerDidDismiss = Notification.Name("OAFavoriteImportViewControllerDidDismissNotification")
}
