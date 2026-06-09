//
//  FavoriteListViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
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
    case sortHeader
    case backupBanner
    case folderSection(FavoriteFolderSection)
    case content
    case statsFooter
}

private enum FavoriteListItem: Hashable {
    case sortHeader(FavoriteSortMode)
    case backupBanner
    case header(FavoriteFolderSection)
    case folder(FavoriteFolderRow)
    case favorite(FavoritePointRow)
    case statsFooter(FavoriteFolderStats)
}

private struct FavoriteFolderRow: Hashable, FavoriteSortableFolder {
    private static let subtitleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    let bridgeItem: OAFavoriteFolderBridgeItem

    var title: String {
        bridgeItem.title
    }
    
    var isVisible: Bool {
        bridgeItem.isVisible
    }
    
    var isPinned: Bool {
        bridgeItem.isPinned
    }
    
    var lastModified: Date? {
        bridgeItem.lastModifiedDate
    }
    
    var subtitle: String {
        let pointsText = "\(bridgeItem.subtreePointsCount) \(localizedString("shared_string_gpx_points").lowercased())"
        guard let lastModified else { return pointsText + "." }
        return String(format: localizedString("ltr_or_rtl_combine_via_comma"), Self.subtitleDateFormatter.string(from: lastModified), pointsText) + "."
    }

    var iconName: String {
        isVisible ? "ic_custom_folder" : "ic_custom_folder_hidden_outlined"
    }

    var iconColor: UIColor {
        isVisible ? (bridgeItem.color ?? .iconColorSelected) : .iconColorSecondary
    }

    var titleColor: UIColor {
        isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(item: OAFavoriteFolderBridgeItem) {
        bridgeItem = item
    }
}

private struct FavoritePointRow: Hashable, FavoriteSortablePoint {
    let bridgeItem: OAFavoritePointBridgeItem
    
    var title: String {
        bridgeItem.title
    }
    
    var distance: CLLocationDistance? {
        bridgeItem.distance?.doubleValue
    }
    
    var lastModified: Date? {
        bridgeItem.timestampDate
    }

    var titleColor: UIColor {
        bridgeItem.isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !bridgeItem.isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(item: OAFavoritePointBridgeItem) {
        bridgeItem = item
    }
}

private struct FavoriteFolderStats: Hashable {
    let foldersCount: Int
    let pointsCount: Int
    let fileSize: Int64

    var text: String {
        var parts: [String] = []
        if foldersCount > 0 {
            parts.append("\(localizedString("shared_string_folders").lowercased()) \(foldersCount)")
        }

        parts.append("\(localizedString("shared_string_gpx_points").lowercased()) \(pointsCount)")
        parts.append("\(localizedString("shared_string_size").lowercased()) \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
        let text = parts.joined(separator: ", ") + "."
        return text.prefix(1).uppercased() + String(text.dropFirst())
    }
}

private enum FavoriteGroupEditContext {
    case movingGroup(String)
    case movingItems([Any])
}

final class FavoriteListViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<FavoriteListSection, FavoriteListItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<FavoriteListSection, FavoriteListItem>
    private typealias CellRegistration<Item> = UICollectionView.CellRegistration<UICollectionViewListCell, Item>

    weak var myPlacesDelegate: MyPlacesDelegate?

    private static let imageSize: CGFloat = 30.0
    private static let favoriteIconSize: CGFloat = 36.0
    private static let sortHeaderHeight: CGFloat = 44.0
    private static let sortHeaderLeadingInset: CGFloat = 16.0
    private static let navigationTitleFontSize: CGFloat = 17.0
    private static let navigationTitleMaximumSize: CGFloat = 22.0
    private static let navigationSubtitleFontSize: CGFloat = 12.0
    private static let navigationSubtitleMaximumSize: CGFloat = 18.0
    private static let rowContentInsets = NSDirectionalEdgeInsets(top: 12.0, leading: 0.0, bottom: 12.0, trailing: 0.0)
    private static let statsFooterInsets = NSDirectionalEdgeInsets(top: 12.0, leading: 20.0, bottom: 12.0, trailing: 20.0)
    private static let wasClosedFreeBackupFavoritesBannerKey = "wasClosedFreeBackupFavoritesBanner"

    private let screenMode: ScreenMode
    private let settings = OAAppSettings.sharedManager()
    private var layoutSections: [FavoriteListSection] = []
    private let appearanceCollection: OAGPXAppearanceCollection = .sharedInstance()
    private var groupController: OAEditGroupViewController?
    private var colorController: OAEditColorViewController?
    private var groupEditContext: FavoriteGroupEditContext?
    private var addToTrackGroupName: String?
    private var addToTrackFavoriteItems: [Any]?

    private var searchText = ""
    private var isSearchActive = false
    private var isAvailablePaymentBanner: Bool {
        isRootFolder && !isSearchActive && !UserDefaults.standard.bool(forKey: Self.wasClosedFreeBackupFavoritesBannerKey) && !OAIAPHelper.isOsmAndProAvailable() && !OABackupHelper.sharedInstance().isRegistered()
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
        guard case .folder(let folder, _) = screenMode, !folder.bridgeItem.groupName.isEmpty else { return nil }
        return folder.bridgeItem.groupName
    }
    private var currentSortMode: FavoriteSortMode {
        isSearchActive ? searchFavoriteSortMode() : favoriteSortMode()
    }
    private var currentSortEntryId: String {
        parentGroupName ?? ""
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
    private lazy var sortHeaderCellRegistration = UICollectionView.CellRegistration<SortButtonCollectionViewCell, FavoriteSortMode> { [weak self] cell, _, sortMode in
        cell.sortButton.setImage(sortMode.image, for: .normal)
        cell.sortButton.menu = self?.makeSortMenu()
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
        let iconName = folder.isPinned ? "ic_custom_folder_pin" : folder.iconName
        content.image = UIImage.templateImageNamed(iconName)?.resizedTemplateImage(with: FavoriteListViewController.imageSize)
        content.imageProperties.tintColor = folder.iconColor
        content.text = folder.title
        content.textProperties.color = folder.titleColor
        content.textProperties.font = folder.titleFont
        content.secondaryText = folder.subtitle
        content.secondaryTextProperties.color = .textColorSecondary
        cell.contentConfiguration = content
        cell.backgroundConfiguration = self?.listCellBackgroundConfiguration()
        cell.accessories = self?.collectionView.isEditing == true ? [.multiselect()] : [.multiselect(), .disclosureIndicator()]
    }
    private lazy var favoriteCellRegistration = CellRegistration<FavoritePointRow> { [weak self] cell, _, favorite in
        var content = cell.defaultContentConfiguration()
        content.directionalLayoutMargins = Self.rowContentInsets
        content.image = OAUtilities.resize(favorite.bridgeItem.icon, newSize: CGSize(width: Self.favoriteIconSize, height: Self.favoriteIconSize))
        content.text = favorite.title
        content.textProperties.color = favorite.titleColor
        content.textProperties.font = favorite.titleFont
        content.secondaryText = favorite.bridgeItem.address
        content.secondaryTextProperties.color = .textColorSecondary
        cell.contentConfiguration = content
        cell.backgroundConfiguration = self?.listCellBackgroundConfiguration()
        cell.accessories = [.multiselect()]
    }
    private lazy var statsFooterCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, FavoriteFolderStats> { cell, _, stats in
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textColorSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = stats.text
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: Self.statsFooterInsets.top), label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Self.statsFooterInsets.leading), label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Self.statsFooterInsets.trailing), label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -Self.statsFooterInsets.bottom)])
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

    deinit {
        NotificationCenter.default.removeObserver(self, name: .favoriteImportViewControllerDidDismiss, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        configureCollectionView()
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteDataDidChange), name: .favoriteImportViewControllerDidDismiss, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(productPurchased), name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
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
            guard let self else { return nil }
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            let section = self.layoutSections.indices.contains(sectionIndex) ? self.layoutSections[sectionIndex] : nil
            if section == .sortHeader {
                return self.sortHeaderLayoutSection()
            }

            if section == .statsFooter {
                return self.statsFooterLayoutSection()
            }

            if case .folderSection = section, self.isRootFolder {
                configuration.headerMode = .firstItemInSection
            }

            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }

    private func sortHeaderLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(Self.sortHeaderHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets.leading = Self.sortHeaderLeadingInset
        return section
    }

    private func statsFooterLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(64.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }

    private func listCellBackgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listGroupedCell()
        configuration.backgroundColor = .groupBg
        return configuration
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
        let isSelected = collectionView.indexPathsForSelectedItems?.isEmpty == false
        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let actionsFixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let shareButton = UIBarButtonItem(image: .icCustomExportOutlined, style: .plain, target: self, action: #selector(shareButtonClicked))
        let moveButton = UIBarButtonItem(image: .icCustomFolderMoveOutlined, style: .plain, target: self, action: #selector(moveButtonClicked))
        let actionsButton = UIBarButtonItem(image: .icCustomOverflowMenuStroke, style: .plain, target: nil, action: nil)
        actionsButton.menu = makeAdditionalContextMenu()
        let deleteButton = UIBarButtonItem(image: .icCustomTrashOutlined, style: .plain, target: self, action: #selector(deleteButtonClicked))
        deleteButton.tintColor = .iconColorDisruptive
        let items = [shareButton, fixedSpacer, moveButton, actionsFixedSpacer, actionsButton, flexibleSpacer, deleteButton]
        items.forEach { $0.isEnabled = isSelected }
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

    private func favoriteSortMode(entryId: String? = nil) -> FavoriteSortMode {
        let sortModes = settings.getFavoriteSortModes()
        guard let sortModeTitle = sortModes[entryId ?? currentSortEntryId] else { return FavoriteSortModeHelper.defaultSortMode() }
        return FavoriteSortMode.byTitle(sortModeTitle)
    }

    private func searchFavoriteSortMode() -> FavoriteSortMode {
        let sortModeTitle = settings.searchFavoriteSortMode.get()
        return FavoriteSortMode.byTitle(sortModeTitle)
    }

    private func setFavoriteSortMode(_ sortMode: FavoriteSortMode) {
        if isSearchActive {
            settings.searchFavoriteSortMode.set(sortMode.title)
        } else {
            var sortModes = settings.getFavoriteSortModes()
            sortModes[currentSortEntryId] = sortMode.title
            settings.saveFavoriteSortModes(sortModes)
        }

        applySnapshot(animatingDifferences: false)
    }

    private func clearFavoriteSortModes(forGroupNames groupNames: [String]) {
        var sortModes = settings.getFavoriteSortModes()
        let keysToRemove = sortModes.keys.filter { key in
            groupNames.contains { groupName in
                key == groupName || (!groupName.isEmpty && key.hasPrefix(groupName + "/"))
            }
        }

        guard !keysToRemove.isEmpty else { return }
        keysToRemove.forEach { sortModes.removeValue(forKey: $0) }
        settings.saveFavoriteSortModes(sortModes)
    }

    private func makeSortMenu() -> UIMenu {
        let modes: [FavoriteSortMode] = isRootFolder && !isSearchActive ? [.lastModified, .nameAZ, .nameZA, .newestDateFirst, .oldestDateFirst] : FavoriteSortMode.allCases
        let groups: [[FavoriteSortMode]] = [[.lastModified], [.nameAZ, .nameZA], [.newestDateFirst, .oldestDateFirst], [.nearest, .farthest]]
        let sections = groups.compactMap { group -> UIMenu? in
            let actions = group.filter { modes.contains($0) }.map { makeSortAction(for: $0) }
            return actions.isEmpty ? nil : UIMenu(options: .displayInline, children: actions)
        }

        return UIMenu(title: "", children: sections)
    }

    private func makeSortAction(for sortMode: FavoriteSortMode) -> UIAction {
        UIAction(title: sortMode.title, image: sortMode.image, state: currentSortMode == sortMode ? .on : .off) { [weak self] _ in
            self?.setFavoriteSortMode(sortMode)
        }
    }

    private func makeDataSource() -> DataSource {
        let sortHeaderCellRegistration = sortHeaderCellRegistration
        let backupBannerCellRegistration = backupBannerCellRegistration
        let folderCellRegistration = folderCellRegistration
        let favoriteCellRegistration = favoriteCellRegistration
        let headerCellRegistration = headerCellRegistration
        let statsFooterCellRegistration = statsFooterCellRegistration
        return DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .sortHeader(let sortMode):
                return collectionView.dequeueConfiguredReusableCell(using: sortHeaderCellRegistration, for: indexPath, item: sortMode)
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
        let allFolders = favoriteFolders()
        let foldersBySection = favoriteFoldersBySection(folders: allFolders).mapValues { FavoriteSortModeHelper.sortFoldersWithMode($0, mode: currentSortMode) }
        let folderSections = rootSections(foldersBySection: foldersBySection)
        let isPaymentBannerVisible = isAvailablePaymentBanner
        let stats = folderStats(allFolders: allFolders, currentGroupName: nil)
        var snapshot = Snapshot()
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
        snapshot.appendItems([.sortHeader(currentSortMode)], toSection: .sortHeader)
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
        let folders = FavoriteSortModeHelper.sortFoldersWithMode(directFavoriteFolders(allFolders, parentGroupName: folder.bridgeItem.groupName).filter { matchesSearch($0.title) }, mode: currentSortMode)
        let favorites = FavoriteSortModeHelper.sortFavoritePointsWithMode(OAFavoritesSwiftHelper.favoritePoints(forGroupName: folder.bridgeItem.groupName).map { FavoritePointRow(item: $0) }.filter { matchesSearch($0.title) || matchesSearch($0.bridgeItem.address) }, mode: currentSortMode)
        let stats = folderStats(allFolders: allFolders, currentGroupName: folder.bridgeItem.groupName)
        var snapshot = Snapshot()
        layoutSections = stats == nil ? [.sortHeader, .content] : [.sortHeader, .content, .statsFooter]
        collectionView.collectionViewLayout.invalidateLayout()
        snapshot.appendSections(layoutSections)
        snapshot.appendItems([.sortHeader(currentSortMode)], toSection: .sortHeader)
        snapshot.appendItems(folders.map(FavoriteListItem.folder), toSection: .content)
        snapshot.appendItems(favorites.map(FavoriteListItem.favorite), toSection: .content)
        if let stats {
            snapshot.appendItems([.statsFooter(stats)], toSection: .statsFooter)
        }

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

    private func folderStats(allFolders: [FavoriteFolderRow], currentGroupName: String?) -> FavoriteFolderStats? {
        guard !isSearchActive else { return nil }
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

    private func closeFreeBackupBanner() {
        UserDefaults.standard.set(true, forKey: Self.wasClosedFreeBackupFavoritesBannerKey)
        applySnapshot(animatingDifferences: true)
    }

    private func directFavoriteFolders(_ folders: [FavoriteFolderRow], parentGroupName: String?) -> [FavoriteFolderRow] {
        folders.filter { isDirectFolder($0.bridgeItem.groupName, parentGroupName: parentGroupName) }
    }

    private func favoriteFolders() -> [FavoriteFolderRow] {
        OAFavoritesSwiftHelper.favoriteFolders()
            .map { FavoriteFolderRow(item: $0) }
    }

    private func isDirectFolder(_ groupName: String, parentGroupName: String?) -> Bool {
        guard let parentGroupName else { return groupName.isEmpty || !groupName.contains("/") }
        guard !parentGroupName.isEmpty else { return false }
        guard groupName.hasPrefix(parentGroupName + "/") else { return false }
        let childPath = groupName.dropFirst(parentGroupName.count + 1)
        return !childPath.isEmpty && !childPath.contains("/")
    }

    private func isNestedFolder(_ groupName: String, in parentGroupName: String) -> Bool {
        guard !parentGroupName.isEmpty else { return false }
        return groupName.hasPrefix(parentGroupName + "/")
    }

    private func matchesSearch(_ text: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return text?.localizedCaseInsensitiveContains(searchText) ?? false
    }

    private func openNewFavoriteGroupEditor() {
        guard let navigationController, let viewController = OAFavoriteGroupEditorViewController(new: ()) else { return }
        viewController.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        navigationController.present(modalNavigationController, animated: true)
    }

    private func openFavoriteGroupAppearance(_ groupName: String) {
        guard let viewController = OAFavoriteGroupEditorViewController(group: OAFavoritesSwiftHelper.pointsGroup(forGroupName: groupName)) else { return }
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openFavoriteGroupMove(_ groupName: String) {
        let groupNames = OAFavoritesSwiftHelper.favoriteGroupsToMove(forGroupName: groupName)
        guard let navigationController, let groupController = OAEditGroupViewController(groupName: nil, groups: groupNames) else { return }
        self.groupController = groupController
        groupEditContext = .movingGroup(groupName)
        groupController.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: groupController)
        navigationController.present(modalNavigationController, animated: true)
    }

    private func openFavoriteItemsMove(_ favoriteItems: [Any]) {
        guard !favoriteItems.isEmpty,
              let navigationController,
              let groupController = OAEditGroupViewController(groupName: nil, groups: OAFavoritesSwiftHelper.favoriteGroupNames(forMovingFavoriteItems: favoriteItems)) else {
            return
        }
        self.groupController = groupController
        groupEditContext = .movingItems(favoriteItems)
        groupController.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: groupController)
        navigationController.present(modalNavigationController, animated: true)
    }

    private func openFavoriteGroupAddToTrack(_ groupName: String) {
        guard OAFavoritesSwiftHelper.canUseGroup(withName: groupName), let navigationController, let viewController = OAOpenAddTrackViewController(screenType: .addToATrack) else { return }
        addToTrackGroupName = groupName
        addToTrackFavoriteItems = nil
        viewController.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        navigationController.present(modalNavigationController, animated: true)
    }

    private func openFavoriteItemsAddToTrack(_ favoriteItems: [Any]) {
        guard !favoriteItems.isEmpty, let navigationController, let viewController = OAOpenAddTrackViewController(screenType: .addToATrack) else { return }
        addToTrackFavoriteItems = favoriteItems
        addToTrackGroupName = nil
        viewController.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        navigationController.present(modalNavigationController, animated: true)
    }

    private func favoritePointRows(forGroupName groupName: String) -> [FavoritePointRow] {
        let sortMode = isSearchActive ? searchFavoriteSortMode() : favoriteSortMode(entryId: groupName)
        let favorites = OAFavoritesSwiftHelper.favoritePoints(forGroupName: groupName).map { FavoritePointRow(item: $0) }
        return FavoriteSortModeHelper.sortFavoritePointsWithMode(favorites, mode: sortMode)
    }

    private func makeActionsMenu() -> UIMenu {
        let addFolderAction = UIAction(title: localizedString("add_new_folder"), image: .icCustomFolderAddOutlined) { [weak self] _ in
            self?.openNewFavoriteGroupEditor()
        }
        let importAction = UIAction(title: localizedString("shared_string_import"), image: .icCustomImportOutlined) { [weak self] _ in
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
        let showHideAction = UIAction(title: localizedString(folder.isVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: folder.isVisible ? .icCustomHideOutlined : .icCustomShowOutlined) { [weak self] _ in
            guard let self else { return }
            OAFavoritesSwiftHelper.setFavoriteGroupVisible(folder.bridgeItem.groupName, visible: !folder.isVisible)
            self.applySnapshot(animatingDifferences: true)
        }
        let pinAction = UIAction(title: localizedString(folder.isPinned ? "unpin_folder" : "pin_folder"), image: folder.isPinned ? .icCustomDrawingPinDisable : .icCustomDrawingPin) { [weak self] _ in
            guard let self else { return }
            OAFavoritesSwiftHelper.setFavoriteGroupPinned(folder.bridgeItem.groupName, pinned: !folder.isPinned)
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
            guard let favoritesUrl = OAFavoritesSwiftHelper.shareFavoriteGroupName(folder.bridgeItem.groupName) else { return }
            showActivity([favoritesUrl], sourceView: sourceView, barButtonItem: nil, completionWithItemsHandler: {
                try? FileManager.default.removeItem(at: favoritesUrl)
            })
        }
        let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteGroupMove(folder.bridgeItem.groupName)
        }
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: folder.bridgeItem.groupName.isEmpty ? [shareAction] : [shareAction, moveAction])

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { _ in
            OAFavoritesSwiftHelper.addFavoriteGroup(toMapMarkers: folder.bridgeItem.groupName)
        }
        let trackAction = UIAction(title: localizedString("add_to_a_track"), image: .icCustomTrip) { [weak self] _ in
            guard let self else { return }
            self.openFavoriteGroupAddToTrack(folder.bridgeItem.groupName)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { [weak self] _ in
            guard let self else { return }
            OAFavoritesSwiftHelper.addFavoriteItems(toNavigation: self.favoritePointRows(forGroupName: folder.bridgeItem.groupName).map { $0.bridgeItem })
        }
        let addToMenu = UIMenu(title: localizedString("shared_string_add"), image: .icCustomAdd, children: [mapMarkersAction, trackAction, navigationAction])
        let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])

        let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
            guard let self else { return }
            self.showDeleteAlert(for: folder)
        }
        let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        return UIMenu(title: "", children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection])
    }

    private func showRenameAlert(for folder: FavoriteFolderRow) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self, weak alert] _ in
            guard let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            let newGroupName = self?.groupName(folder.bridgeItem.groupName, replacingLastComponentWith: text) ?? text
            OAFavoritesSwiftHelper.renameFavoriteGroup(folder.bridgeItem.groupName, newName: newGroupName)
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
        let message = String(format: localizedString("permanent_delete_warning"), "\"\(folder.title)\"")
        let alert = UIAlertController(title: localizedString("delete_folder"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard OAFavoritesSwiftHelper.deleteFavoriteGroup(folder.bridgeItem.groupName) else { return }
            self?.clearFavoriteSortModes(forGroupNames: [folder.bridgeItem.groupName])
            self?.applySnapshot(animatingDifferences: true)
        })

        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
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

        guard let favoritesUrl = OAFavoritesSwiftHelper.shareFavoriteItems(bridgeItems(for: selectedItems)) else { return }
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
        if OAFavoritesSwiftHelper.deleteFavoriteItems(items) {
            clearFavoriteSortModes(forGroupNames: groupNames)
        }

        setEdit(false)
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

    private func bridgeItems(for indexPaths: [IndexPath]) -> [Any] {
        indexPaths.compactMap { indexPath in
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch item {
            case .folder(let folder):
                return folder.bridgeItem
            case .favorite(let favorite):
                return favorite.bridgeItem
            case .backupBanner, .header, .statsFooter, .sortHeader:
                return nil
            }
        }
    }

    private func makeAdditionalContextMenu() -> UIMenu {
        var menuElements: [UIMenuElement] = []
        let indexPathItems = collectionView.indexPathsForSelectedItems ?? []
        let selectedBridgeItems = bridgeItems(for: indexPathItems)
        let hasPoints = indexPathItems.contains {
            guard case .favorite = dataSource.itemIdentifier(for: $0) else { return false }
            return true
        }

        let mapMarkersAction = UIAction(title: localizedString("map_markers"), image: .icCustomMarker) { [weak self] _ in
            OAFavoritesSwiftHelper.addFavoriteItems(toMapMarkers: selectedBridgeItems)
            self?.setEdit(false)
            self?.applySnapshot(animatingDifferences: true)
        }
        let trackAction = UIAction(title: localizedString("shared_string_gpx_track"), image: .icCustomTrip) { [weak self] _ in
            self?.openFavoriteItemsAddToTrack(selectedBridgeItems)
            self?.setEdit(false)
            self?.applySnapshot(animatingDifferences: true)
        }
        let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { [weak self] _ in
            OAFavoritesSwiftHelper.addFavoriteItems(toNavigation: selectedBridgeItems)
            self?.applySnapshot(animatingDifferences: true)
        }
        let addToMenu = UIMenu(title: localizedString("add_to"), image: .icCustomAdd, children: [trackAction, navigationAction, mapMarkersAction])
        let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])
        menuElements.append(thirdButtonsSection)

        let changeAppearanceAction = UIAction(title: localizedString("change_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
            self?.openFavoriteItemsAppearance()
        }
        let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [changeAppearanceAction])
        menuElements.append(secondButtonsSection)

        if !hasPoints {
            let folders: [FavoriteFolderRow] = indexPathItems.compactMap {
                guard case .folder(let folder) = dataSource.itemIdentifier(for: $0) else { return nil }
                return folder
            }

            if !folders.isEmpty {
                var folderMenuElements: [UIMenuElement] = []

                if folders.contains(where: { !$0.isPinned }) {
                    let unpinnedGroupNames = folders.filter({ !$0.isPinned }).map { $0.bridgeItem.groupName }
                    let pinAction = UIAction(title: localizedString("pin_folder"), image: .icCustomMapPinOutlined) { [weak self] _ in
                        OAFavoritesSwiftHelper.setFavoriteGroupsPinned(unpinnedGroupNames, pinned: true)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(pinAction)
                }

                if folders.contains(where: { $0.isPinned }) {
                    let pinnedGroupNames = folders.filter({ $0.isPinned }).map { $0.bridgeItem.groupName }
                    let unpinAction = UIAction(title: localizedString("unpin_folder"), image: .icCustomMapPinOutlined) { [weak self] _ in
                        OAFavoritesSwiftHelper.setFavoriteGroupsPinned(pinnedGroupNames, pinned: false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(unpinAction)
                }

                if folders.contains(where: { $0.isVisible }) {
                    let visibleGroupNames = folders.filter({ $0.isVisible }).map { $0.bridgeItem.groupName }
                    let hideAction = UIAction(title: localizedString("shared_string_hide_from_map"), image: .icCustomHideOutlined) { [weak self] _ in
                        OAFavoritesSwiftHelper.setFavoriteGroupsVisible(visibleGroupNames, visible: false)
                        self?.applySnapshot(animatingDifferences: true)
                    }
                    folderMenuElements.append(hideAction)
                }

                if folders.contains(where: { !$0.isVisible }) {
                    let hiddenGroupNames = folders.filter({ !$0.isVisible }).map { $0.bridgeItem.groupName }
                    let showAction = UIAction(title: localizedString("shared_string_show_on_map"), image: .icCustomShowOutlined) { [weak self] _ in
                        OAFavoritesSwiftHelper.setFavoriteGroupsVisible(hiddenGroupNames, visible: true)
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

    private func openFavoriteItemsAppearance() {
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
                case .sortHeader, .backupBanner, .header, .statsFooter:
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
        let sourceView = sender as? UIView ?? collectionView
        shareItems(for: sourceView)
        setEdit(false)
        applySnapshot()
    }

    @objc private func moveButtonClicked(_ sender: Any) {
        guard let selectedItems = collectionView.indexPathsForSelectedItems, !selectedItems.isEmpty else {
            let alert = UIAlertController(title: "", message: localizedString("fav_select"), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: localizedString("shared_string_ok"), style: .default)
            alert.addAction(defaultAction)
            present(alert, animated: true)
            return
        }

        openFavoriteItemsMove(bridgeItems(for: selectedItems))
    }

    @objc private func deleteButtonClicked(_ sender: Any) {
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
}

extension FavoriteListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .folder(let folder):
            if collectionView.isEditing {
                updateNavigationBarTitle()
                configureToolbar()
                return
            }
            let viewController = FavoriteListViewController(frame: view.bounds, screenMode: .folder(folder, previousTitle: normalTitle))
            viewController.myPlacesDelegate = myPlacesDelegate
            navigationController?.pushViewController(viewController, animated: true)
        case .favorite(let favorite):
            if collectionView.isEditing {
                updateNavigationBarTitle()
                configureToolbar()
                return
            }
            OAFavoritesSwiftHelper.openFavoritePoint(withIdentifier: favorite.bridgeItem.identifier)
        case .sortHeader, .backupBanner, .header, .statsFooter:
            break
        }

        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView.isEditing else { return }
        updateNavigationBarTitle()
        configureToolbar()
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

extension FavoriteListViewController: OAEditColorViewControllerDelegate {
    func colorChanged() {
        guard let colorController else { return }
        defer {
            self.colorController = nil
        }

        guard let selectedItems = collectionView.indexPathsForSelectedItems, !selectedItems.isEmpty else { return }
        if colorController.saveChanges {
            OAFavoritesSwiftHelper.changeFavoriteItems(bridgeItems(for: selectedItems), colorIndex: colorController.colorIndex)
        }

        setEdit(false)
        applySnapshot(animatingDifferences: true)
    }
}

extension FavoriteListViewController: OAEditGroupViewControllerDelegate {
    func groupChanged() {
        guard let groupController else { return }
        defer {
            self.groupController = nil
            groupEditContext = nil
        }

        guard groupController.saveChanges else { return }

        let targetGroupName = groupController.groupName ?? ""
        switch groupEditContext {
        case .movingGroup(let groupName):
            OAFavoritesSwiftHelper.moveFavoriteGroup(groupName, toGroupName: targetGroupName)
        case .movingItems(let favoriteItems):
            OAFavoritesSwiftHelper.moveFavoriteItems(favoriteItems, toGroupName: targetGroupName)
        case .none:
            return
        }
        setEdit(false)
        applySnapshot(animatingDifferences: true)
    }
}

extension FavoriteListViewController: OAOpenAddTrackDelegate {
    func onFileSelected(_ gpxFilePath: String) {
        if let addToTrackFavoriteItems {
            OAFavoritesSwiftHelper.addFavoriteItems(toTrack: addToTrackFavoriteItems, gpxFileName: gpxFilePath)
            self.addToTrackFavoriteItems = nil
        } else if let addToTrackGroupName {
            OAFavoritesSwiftHelper.addFavoriteGroup(toTrack: addToTrackGroupName, gpxFileName: gpxFilePath)
            self.addToTrackGroupName = nil
        }
    }
}

extension FavoriteListViewController: OAEditorDelegate {
    func addNewItem(withName name: String?, iconName: String, color: UIColor, backgroundIconName: String) {
        guard OAFavoritesSwiftHelper.addFavoriteGroup(name ?? "",
                                                      parentGroupName: parentGroupName,
                                                      iconName: iconName,
                                                      color: color,
                                                      backgroundIconName: backgroundIconName) else { return }
        applySnapshot(animatingDifferences: true)
    }

    func onEditorUpdated() {
        applySnapshot(animatingDifferences: true)
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

extension FavoriteListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        OARootViewController.instance().import(asFavorites: url)
    }
}

extension Notification.Name {
    static let favoriteImportViewControllerDidDismiss = Notification.Name("OAFavoriteImportViewControllerDidDismissNotification")
}
