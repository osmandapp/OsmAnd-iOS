//
//  FavoriteListViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class FavoriteListViewController: UIViewController, MyPlacesScrollResettable {
    typealias DataSource = UICollectionViewDiffableDataSource<FavoriteListSection, FavoriteListItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<FavoriteListSection, FavoriteListItem>
    typealias CellRegistration<Item> = UICollectionView.CellRegistration<UICollectionViewListCell, Item>
    typealias RowCellRegistration<Item> = UICollectionView.CellRegistration<FavoriteListCell, Item>

    static let imageSize: CGFloat = 30.0
    static let favoriteIconSize: CGFloat = 36.0
    static let sortHeaderHeight: CGFloat = 44.0
    static let emptyStateHeaderTopPadding: CGFloat = 22.0
    static let navigationTitleFontSize: CGFloat = 17.0
    static let navigationTitleMaximumSize: CGFloat = 22.0
    static let navigationSubtitleFontSize: CGFloat = 12.0
    static let navigationSubtitleMaximumSize: CGFloat = 18.0
    static let wasClosedFreeBackupFavoritesBannerKey = "wasClosedFreeBackupFavoritesBanner"

    let screenMode: ScreenMode
    let settings = OAAppSettings.sharedManager()
    var layoutSections: [FavoriteListSection] = []
    let appearanceCollection: OAGPXAppearanceCollection = .sharedInstance()
    var groupController: OAEditGroupViewController?
    var colorController: OAEditColorViewController?
    var favoriteItemsToMove: [Any]?
    var favoriteGroupAppearanceGroupName: String?
    var favoriteGroupAppearanceEditor: OAFavoriteGroupEditorViewController?
    var addToTrackGroupName: String?
    var addToTrackFavoriteItems: [Any]?
    var pointToShare: OAFavoritePointBridgeItem?
    var searchText = ""
    var isSearchActive = false
    var isSelectionModeInSearch = false
    var lastDistanceDirectionUpdate: TimeInterval = 0.0
    var isContextMenuVisible = false
    var shouldReloadCollectionView = false
    var locationUpdateObserver: OAAutoObserverProxy?
    var headingUpdateObserver: OAAutoObserverProxy?
    var collapsedRootSections = FavoriteListViewController.loadCollapsedSections()
    var selectionManager = SelectionManager<FavoriteSelectionItem>(allItems: [])
    var savedScrollPosition: (linearIndex: Int, offsetY: CGFloat)?
    var shouldRestoreScrollPosition = false
    var isSearchResultsMode: Bool {
        isSearchActive || isSelectionModeInSearch
    }
    var isAvailablePaymentBanner: Bool {
        isRootFolder && !isSearchResultsMode && !UserDefaults.standard.bool(forKey: Self.wasClosedFreeBackupFavoritesBannerKey) && !OAIAPHelper.isOsmAndProAvailable() && !OABackupHelper.sharedInstance().isRegistered()
    }
    var isRootFolder: Bool {
        guard case .root = screenMode else { return false }
        return true
    }
    var normalTitle: String {
        switch screenMode {
        case .root: localizedString("shared_string_favorites")
        case .folder(let folder, _): folder.title
        }
    }
    var parentGroupName: String? {
        guard case .folder(let folder, _) = screenMode, !folder.bridgeItem.groupName.isEmpty else { return nil }
        return folder.bridgeItem.groupName
    }
    var searchParentGroupName: String? {
        guard case .folder(let folder, _) = screenMode else { return nil }
        return folder.bridgeItem.groupName
    }
    var currentSortMode: FavoriteSortMode {
        isSearchResultsMode ? searchFavoriteSortMode() : favoriteSortMode()
    }
    var currentSortHeader: FavoriteSortHeader {
        FavoriteSortHeader(sortMode: currentSortMode, includesDistanceSortModes: isSearchResultsMode || !isRootFolder)
    }
    var currentSortEntryId: String {
        parentGroupName ?? ""
    }

    lazy var collectionView: UICollectionView = {
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
    lazy var subfolderSearchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchTextField.placeholder = localizedString("search_activity")
        return searchController
    }()
    lazy var dataSource: DataSource = makeDataSource()
    
    weak var myPlacesDelegate: MyPlacesDelegate?
    
    private var normalSubtitle: String {
        switch screenMode {
        case .root: localizedString("shared_string_my_places")
        case .folder(_, let previousTitle): previousTitle
        }
    }
    
    convenience init(frame: CGRect) {
        self.init(frame: frame, screenMode: .root)
    }

    init(frame: CGRect, screenMode: ScreenMode) {
        self.screenMode = screenMode
        super.init(nibName: nil, bundle: nil)
        view.frame = frame
    }

    required init?(coder: NSCoder) {
        screenMode = .root
        super.init(coder: coder)
    }
    
    private static func loadCollapsedSections() -> Set<FavoriteFolderSection> {
        let sections = OAFavoritesBridgeHelper.collapsedSections()
        return Set(sections.compactMap(FavoriteFolderSection.init(rawValue:)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createMissingParentFolderIfNeeded()
        view.backgroundColor = .viewBg
        configureCollectionView()
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteDataDidChange), name: .favoriteImportViewControllerDidDismiss, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(productPurchased), name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        definesPresentationContext = true
        configureNavigation()
        navigationController?.setToolbarHidden(true, animated: false)
        configureToolbar()
        applySnapshot(shouldSaveScrollPosition: false)
        registerDistanceAndDirectionObservers()
        updateDistanceAndDirection(true)
        if isRootFolder {
            myPlacesDelegate?.updateContentScrollView(collectionView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        unregisterDistanceAndDirectionObservers()
        saveScrollPosition()
        if !isRootFolder {
            navigationItem.searchController = nil
            navigationController?.setNavigationBarHidden(true, animated: false)
        }

        definesPresentationContext = false
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldRestoreScrollPosition else { return }
        restoreScrollPositionIfNeeded()
    }
    
    func updateDistanceAndDirection(_ forceUpdate: Bool) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateDistanceAndDirection(forceUpdate)
            }
            return
        }

        if isContextMenuVisible {
            shouldReloadCollectionView = true
            return
        }

        guard !collectionView.isEditing
                && OsmAndApp.swiftInstance().locationServices.lastKnownLocation != nil
                && dataSource.snapshot().itemIdentifiers.contains(where: { item in
                    if case .favorite = item {
                        return true
                    }
                    return false
                }) else {
            return
        }

        let currentTime = Date.now.timeIntervalSince1970
        guard forceUpdate || currentTime - lastDistanceDirectionUpdate >= 0.3 else { return }
        lastDistanceDirectionUpdate = currentTime
        if currentSortMode.isDistanceOriented {
            applySnapshot(animatingDifferences: false)
        } else {
            updateVisibleFavoriteCellsDistanceAndDirection()
        }
    }
    
    func listCellBackgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listGroupedCell()
        configuration.backgroundColor = .groupBg
        return configuration
    }

    func configureNavigation() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        if !isRootFolder {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .viewBg
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.tintColor = .iconColorActive
        }

        navigationController?.navigationBar.prefersLargeTitles = false
        configureNavigationButtons()
        configureSearchVisibility()
        updateNavigationBarTitle()
        updateSegmentedControlVisibility()
    }
    
    func configureToolbar() {
        guard !isSearchActive || collectionView.isEditing else {
            if hasSearchResults() {
                configureSearchToolbar()
            }
            return
        }

        let isSelected = !selectionManager.selectedItems.isEmpty
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
            myPlacesDelegate?.updateToolbar(with: items)
        } else {
            toolbarItems = items
        }
    }
    
    func updateSelectionUI() {
        updateNavigationBarTitle()
        configureNavigationButtons()
        configureToolbar()
    }
    
    func updateSegmentedControlVisibility() {
        myPlacesDelegate?.updateSegmentedControlVisibility(isRootFolder && !collectionView.isEditing && !isSearchResultsMode)
    }
    
    func configureNavigationButtons() {
        let targetNavigationItem = isRootFolder ? navigationController?.navigationBar.topItem : navigationItem
        if collectionView.isEditing {
            let cancelButton = UIBarButtonItem(title: localizedString("shared_string_cancel"), style: .plain, target: self, action: #selector(cancelButtonPressed))
            cancelButton.accessibilityLabel = localizedString("shared_string_cancel")
            let selectAllTitle = localizedString(selectionManager.areAllSelected ? "shared_string_deselect_all" : "shared_string_select_all")
            let selectAllButton = UIBarButtonItem(title: selectAllTitle, style: .plain, target: self, action: #selector(selectAllButtonPressed))
            selectAllButton.accessibilityLabel = selectAllTitle
            targetNavigationItem?.leftBarButtonItem = cancelButton
            targetNavigationItem?.rightBarButtonItems = [selectAllButton]
            if isRootFolder {
                myPlacesDelegate?.showBackButton(false)
            } else {
                navigationItem.hidesBackButton = true
            }
        } else {
            let actionsButton = UIBarButtonItem(image: .init(systemName: "ellipsis.circle"), menu: makeActionsMenu())
            actionsButton.tintColor = .textColorPrimary
            actionsButton.accessibilityLabel = localizedString("shared_string_actions")
            let searchIcon = UIImage(systemName: "magnifyingglass",
                                     withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .textColorPrimary))
            let searchButton = UIBarButtonItem(image: searchIcon,
                                               style: .plain,
                                               target: self,
                                               action: #selector(searchButtonPressed(_:)))
            searchButton.accessibilityLabel = localizedString("shared_string_search")
            if #available(iOS 26.0, *) {
                searchButton.style = .prominent
                searchButton.tintColor = .clear
            }

            let rightBarButtonItems = [actionsButton, isSearchActive ? nil : searchButton].compactMap { $0 }
            targetNavigationItem?.leftBarButtonItem = nil
            targetNavigationItem?.setRightBarButtonItems(rightBarButtonItems, animated: false)
            if isRootFolder {
                myPlacesDelegate?.showBackButton(true)
            } else {
                navigationItem.hidesBackButton = false
            }
        }
    }
    
    func resetScrollPosition() {
        savedScrollPosition = nil
        shouldRestoreScrollPosition = false
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: -collectionView.adjustedContentInset.top), animated: false)
    }

    func saveScrollPosition() {
        guard !isSearchResultsMode else { return }
        savedScrollPosition = currentScrollPosition()
    }

    private func currentScrollPosition() -> (linearIndex: Int, offsetY: CGFloat)? {
        let topY = collectionView.contentOffset.y + collectionView.adjustedContentInset.top
        let visibleItems = collectionView.indexPathsForVisibleItems.compactMap { indexPath -> (indexPath: IndexPath, minY: CGFloat, maxY: CGFloat)? in
            guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else { return nil }
            return (indexPath: indexPath, minY: attributes.frame.minY, maxY: attributes.frame.maxY)
        }

        let topEdgeItems = visibleItems.filter { $0.minY <= topY && $0.maxY > topY }
        let candidates = topEdgeItems.isEmpty ? visibleItems.filter { $0.maxY > topY } : topEdgeItems
        guard let anchor = (candidates.isEmpty ? visibleItems : candidates).min(by: { lhs, rhs in
            let lhsDistance = abs(lhs.minY - topY)
            let rhsDistance = abs(rhs.minY - topY)
            if lhsDistance == rhsDistance {
                return lhs.minY < rhs.minY
            }

            return lhsDistance < rhsDistance
        }) else {
            return nil
        }

        return (linearIndex: linearIndex(for: anchor.indexPath),
                offsetY: max(0.0, topY - anchor.minY))
    }

    private func linearIndex(for indexPath: IndexPath) -> Int {
        guard indexPath.section < collectionView.numberOfSections else { return 0 }
        let previousItemsCount = (0..<indexPath.section).reduce(0) { result, section in
            result + collectionView.numberOfItems(inSection: section)
        }
        return previousItemsCount + indexPath.item
    }

    private func restoreScrollPositionIfNeeded() {
        guard !isSearchResultsMode, let savedScrollPosition else { return }
        collectionView.layoutIfNeeded()

        guard let indexPath = indexPath(for: savedScrollPosition.linearIndex) else { return }
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)

        guard let attributes = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath) else { return }
        self.savedScrollPosition = nil
        shouldRestoreScrollPosition = false
        let minY = -collectionView.adjustedContentInset.top
        let offsetY = max(minY, attributes.frame.minY + savedScrollPosition.offsetY - collectionView.adjustedContentInset.top)
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: offsetY), animated: false)
    }

    private func indexPath(for linearIndex: Int) -> IndexPath? {
        guard collectionView.numberOfSections > 0 else { return nil }
        var remainingIndex = max(0, linearIndex)
        for section in 0..<collectionView.numberOfSections {
            let itemCount = collectionView.numberOfItems(inSection: section)
            if remainingIndex < itemCount {
                return IndexPath(item: remainingIndex, section: section)
            }

            remainingIndex -= itemCount
        }

        return lastIndexPath()
    }

    private func lastIndexPath() -> IndexPath? {
        guard collectionView.numberOfSections > 0 else { return nil }
        for section in stride(from: collectionView.numberOfSections - 1, through: 0, by: -1) {
            let itemCount = collectionView.numberOfItems(inSection: section)
            if itemCount > 0 {
                return IndexPath(item: itemCount - 1, section: section)
            }
        }

        return nil
    }

    private func registerDistanceAndDirectionObservers() {
        unregisterDistanceAndDirectionObservers()
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let updateDistanceAndDirectionSelector = #selector(updateDistanceAndDirection as () -> Void)
        locationUpdateObserver = OAAutoObserverProxy(self,
                                                     withHandler: updateDistanceAndDirectionSelector,
                                                     andObserve: app.locationServices.updateLocationObserver)
        headingUpdateObserver = OAAutoObserverProxy(self,
                                                    withHandler: updateDistanceAndDirectionSelector,
                                                    andObserve: app.locationServices.updateHeadingObserver)
    }

    private func unregisterDistanceAndDirectionObservers() {
        locationUpdateObserver?.detach()
        locationUpdateObserver = nil
        headingUpdateObserver?.detach()
        headingUpdateObserver = nil
    }

    private func configureCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([collectionView.topAnchor.constraint(equalTo: view.topAnchor), collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor), collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor), collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        if !isRootFolder {
            setContentScrollView(collectionView, for: .top)
        }
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

            if section == .emptyState {
                configuration.headerTopPadding = Self.emptyStateHeaderTopPadding
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
        return NSCollectionLayoutSection(group: group)
    }

    private func statsFooterLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(64.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }

    private func configureSearchVisibility() {
        guard !isRootFolder else { return }

        if #available(iOS 26.0, *), !OAUtilities.isIPad() {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        
        navigationItem.searchController = collectionView.isEditing || !isSearchActive ? nil : subfolderSearchController
    }
    
    private func configureSearchToolbar() {
        let selectButton = UIBarButtonItem(title: localizedString("shared_string_select"), style: .plain, target: self, action: #selector(searchSelectButtonPressed))
        selectButton.accessibilityLabel = localizedString("shared_string_select")
        let items = [selectButton]
        if isRootFolder {
            myPlacesDelegate?.updateToolbar(with: items)
        } else {
            toolbarItems = items
        }
    }
    
    private func updateNavigationBarTitle() {
        if collectionView.isEditing {
            let selectedItems = bridgeItems(for: selectionManager.selectedItems)
            let pointsCount = selectedFavoritePointsCount(for: selectedItems)
            let subtitle = "\(pointsCount) \(localizedString("shared_string_gpx_points").lowercased())"
            setNavigationTitle("\(selectedItems.count)", subtitle: subtitle, hideSubtitle: false)
        } else {
            setNavigationTitle(normalTitle, subtitle: normalSubtitle, hideSubtitle: false)
        }
    }

    private func setNavigationTitle(_ title: String, subtitle: String, hideSubtitle: Bool) {
        if isRootFolder {
            if myPlacesDelegate?.updateTitle(title, subtitle: subtitle, hideSubtitle: hideSubtitle) == nil {
                myPlacesDelegate?.updateTitle(title, hideSubtitle: hideSubtitle)
            }
        } else {
            navigationItem.setStackViewWithTitle(title, titleColor: .textColorPrimary, titleFont: .scaledSystemFont(ofSize: Self.navigationTitleFontSize, weight: .semibold, maximumSize: Self.navigationTitleMaximumSize), subtitle: hideSubtitle ? "" : subtitle, subtitleColor: .textColorSecondary, subtitleFont: .scaledSystemFont(ofSize: Self.navigationSubtitleFontSize, maximumSize: Self.navigationSubtitleMaximumSize))
        }
    }

    private func createMissingParentFolderIfNeeded() {
        guard isRootFolder else { return }
        OAFavoritesBridgeHelper.createMissingParentFolderIfNeeded()
    }
    
    deinit {
        unregisterDistanceAndDirectionObservers()
        NotificationCenter.default.removeObserver(self, name: .favoriteImportViewControllerDidDismiss, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
    }
}

extension Notification.Name {
    static let favoriteImportViewControllerDidDismiss = Notification.Name("OAFavoriteImportViewControllerDidDismissNotification")
}
