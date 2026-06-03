//
//  FavoriteListViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

final class FavoriteListViewController: UIViewController {
    fileprivate enum FavoriteFolderSection: Int, CaseIterable, Hashable {
        case pinned
        case visible
        case hidden

        var title: String {
            switch self {
            case .pinned:
                localizedString("shared_string_pinned")
            case .visible:
                localizedString("visible_categories")
            case .hidden:
                localizedString("hidden_categories")
            }
        }
    }

    fileprivate struct FavoriteFolder: Hashable {
        let identifier: String
        let groupName: String
        let title: String
        let pointsCount: Int
        let isVisible: Bool
        let isPinned: Bool
        let color: UIColor?
        let isVirtual: Bool

        init(item: FavoriteFolderBridgeItem) {
            identifier = item.identifier
            groupName = item.groupName
            title = Self.title(for: item.groupName, fallback: item.title)
            pointsCount = Int(item.pointsCount)
            isVisible = item.isVisible
            isPinned = item.isPinned
            color = item.color
            isVirtual = false
        }

        init(groupName: String, folders: [FavoriteFolder]) {
            let exactFolder = folders.first { $0.groupName == groupName }
            identifier = exactFolder?.identifier ?? "virtual-\(groupName)"
            self.groupName = groupName
            title = Self.title(for: groupName, fallback: exactFolder?.title ?? groupName)
            pointsCount = folders.reduce(0) { $0 + $1.pointsCount }
            isVisible = exactFolder?.isVisible ?? folders.contains { $0.isVisible }
            isPinned = exactFolder?.isPinned ?? false
            color = exactFolder?.color ?? folders.first { $0.color != nil }?.color
            isVirtual = exactFolder == nil
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }

        static func == (lhs: FavoriteFolder, rhs: FavoriteFolder) -> Bool {
            lhs.identifier == rhs.identifier
        }

        private static func title(for groupName: String, fallback: String) -> String {
            guard !groupName.isEmpty else { return fallback }
            return groupName.components(separatedBy: "/").last ?? fallback
        }
    }

    fileprivate struct FavoritePoint: Hashable {
        let identifier: String
        let groupName: String
        let title: String
        let subtitle: String?
        let icon: UIImage?
        let isVisible: Bool

        init(item: FavoritePointBridgeItem) {
            identifier = item.identifier
            groupName = item.groupName
            title = item.title
            subtitle = item.subtitle
            icon = item.icon
            isVisible = item.isVisible
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }

        static func == (lhs: FavoritePoint, rhs: FavoritePoint) -> Bool {
            lhs.identifier == rhs.identifier
        }
    }

    private enum ScreenMode {
        case root
        case folder(FavoriteFolder, previousTitle: String)
    }

    fileprivate enum FavoriteListSection: Hashable {
        case folderSection(FavoriteFolderSection)
        case favoritePoints
    }

    fileprivate enum FavoriteListItem: Hashable {
        case header(FavoriteFolderSection)
        case folder(FavoriteFolder)
        case favorite(FavoritePoint)
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<FavoriteListSection, FavoriteListItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<FavoriteListSection, FavoriteListItem>

    weak var myPlacesDelegate: MyPlacesDelegate?

    private static let imageSize: CGFloat = 30

    private let screenMode: ScreenMode
    private var collectionView: UICollectionView!
    private var dataSource: DataSource!
    private var selectButton: UIBarButtonItem?
    private var actionsButton: UIBarButtonItem?
    private var searchController: UISearchController?
    private var isSearchActive = false
    private var searchText = ""

    private var isRootFolder: Bool {
        if case .root = screenMode {
            return true
        }
        return false
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

    private lazy var folderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FavoriteFolder> { [weak self] cell, _, folder in
        var content = cell.defaultContentConfiguration()
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

    private lazy var favoriteCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FavoritePoint> { cell, _, favorite in
        var content = cell.defaultContentConfiguration()
        content.image = favorite.icon
        content.text = favorite.title
        content.textProperties.color = favorite.titleColor
        content.textProperties.font = favorite.titleFont
        content.secondaryText = favorite.subtitle
        content.secondaryTextProperties.color = .textColorSecondary
        cell.contentConfiguration = content
        cell.accessories = [.multiselect()]
    }

    private lazy var headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FavoriteFolderSection> { cell, _, section in
        var content = cell.defaultContentConfiguration()
        content.text = section.title
        content.textProperties.color = .textColorPrimary
        content.textProperties.font = .systemFont(ofSize: 20, weight: .semibold)
        cell.contentConfiguration = content

        let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
        cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
        cell.tintColor = .iconColorActive
    }

    init(frame: CGRect) {
        screenMode = .root
        super.init(nibName: nil, bundle: nil)
        view.frame = frame
    }

    private init(frame: CGRect, folder: FavoriteFolder, previousTitle: String) {
        screenMode = .folder(folder, previousTitle: previousTitle)
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
        configureSearchController()
        dataSource = makeDataSource()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(favoriteGroupsDidChange(_:)),
                                               name: Notification.Name("FavoriteFoldersBridgeGroupsDidChangeNotification"),
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigation()
        applySnapshot()
    }

    private func configureNavigation() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = false

        configureNavigationButtons()
        configureSearchVisibility()
        updateNavigationBarTitle()
        updateSegmentedControlVisibility()
        myPlacesDelegate?.updateToolbar?(with: nil)
    }

    private func configureNavigationButtons() {
        if collectionView.isEditing {
            let cancelButton = OABaseNavbarViewController.createRightNavbarButton(
                localizedString("shared_string_cancel"),
                icon: nil,
                color: .label,
                action: #selector(cancelButtonPressed(_:)),
                target: self,
                menu: nil
            )
            cancelButton?.accessibilityLabel = localizedString("shared_string_cancel")
            setLeftBarButtonItem(cancelButton)
            setRightBarButtonItems(nil)
            setBackButtonVisible(false)
        } else {
            selectButton = OABaseNavbarViewController.createRightNavbarButton(
                localizedString("shared_string_select"),
                icon: nil,
                color: .label,
                action: #selector(selectButtonPressed(_:)),
                target: self,
                menu: nil
            )
            selectButton?.accessibilityLabel = localizedString("shared_string_select")

            actionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: actionsMenu())
            actionsButton?.accessibilityLabel = localizedString("shared_string_actions")

            setLeftBarButtonItem(nil)
            setRightBarButtonItems([actionsButton, selectButton].compactMap { $0 })
            setBackButtonVisible(true)
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
        navigationItem.searchController = collectionView.isEditing ? nil : searchController
    }

    private func updateNavigationBarTitle() {
        if collectionView.isEditing {
            let selectedItemsCount = collectionView.indexPathsForSelectedItems?.count ?? 0
            let title: String
            if selectedItemsCount == 0 {
                title = localizedString("select_items")
            } else {
                let itemText = localizedString(selectedItemsCount > 1 ? "shared_string_items" : "shared_string_item").lowercased()
                title = "\(selectedItemsCount) \(itemText)"
            }
            setNavigationTitle(title, subtitle: "", hideSubtitle: true)
        } else {
            setNavigationTitle(normalTitle, subtitle: normalSubtitle, hideSubtitle: false)
        }
    }

    private func updateSegmentedControlVisibility() {
        myPlacesDelegate?.updateSegmentedControlVisibility(isRootFolder && !collectionView.isEditing && !isSearchActive)
    }

    private func setNavigationTitle(_ title: String, subtitle: String, hideSubtitle: Bool) {
        if isRootFolder {
            myPlacesDelegate?.updateTitle?(title, hideSubtitle: hideSubtitle)
        } else {
            navigationItem.setStackViewWithTitle(title,
                                                 titleColor: .textColorPrimary,
                                                 titleFont: .scaledSystemFont(ofSize: 17.0, weight: .semibold, maximumSize: 22.0),
                                                 subtitle: hideSubtitle ? "" : subtitle,
                                                 subtitleColor: .textColorSecondary,
                                                 subtitleFont: .scaledSystemFont(ofSize: 12.0, maximumSize: 18.0))
        }
    }

    private func setBackButtonVisible(_ visible: Bool) {
        if isRootFolder {
            myPlacesDelegate?.showBackButton(visible)
        } else {
            navigationItem.hidesBackButton = !visible
        }
    }

    private func setLeftBarButtonItem(_ item: UIBarButtonItem?) {
        if isRootFolder {
            navigationController?.navigationBar.topItem?.leftBarButtonItem = item
        } else {
            navigationItem.leftBarButtonItem = item
        }
    }

    private func setRightBarButtonItems(_ items: [UIBarButtonItem]?) {
        if isRootFolder {
            navigationController?.navigationBar.topItem?.rightBarButtonItems = items
        } else {
            navigationItem.rightBarButtonItems = items
        }
    }

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelectionDuringEditing = true
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.searchTextField.placeholder = localizedString("search_activity")
        definesPresentationContext = true
    }

    private func createLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = isRootFolder ? .firstItemInSection : .none
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func makeDataSource() -> DataSource {
        let folderCellRegistration = folderCellRegistration
        let favoriteCellRegistration = favoriteCellRegistration
        let headerCellRegistration = headerCellRegistration

        return DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
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
        let foldersBySection = favoriteFoldersBySection(parentGroupName: nil)
        let folderSections = rootSections(foldersBySection: foldersBySection)

        var snapshot = Snapshot()
        snapshot.appendSections(folderSections.map { .folderSection($0) })
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)

        folderSections.forEach { section in
            let headerItem = FavoriteListItem.header(section)
            let folderItems = (foldersBySection[section] ?? []).map { FavoriteListItem.folder($0) }

            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<FavoriteListItem>()
            sectionSnapshot.append([headerItem])
            sectionSnapshot.append(folderItems, to: headerItem)
            sectionSnapshot.expand([headerItem])
            dataSource.apply(sectionSnapshot, to: .folderSection(section), animatingDifferences: animatingDifferences)
        }
    }

    private func applyFolderSnapshot(folder: FavoriteFolder, animatingDifferences: Bool) {
        let folders = directFavoriteFolders(parentGroupName: folder.groupName)
            .filter { matchesSearch($0.title) }
        let favorites = FavoriteFoldersBridge.favoritePoints(forGroupName: folder.groupName)
            .map { FavoritePoint(item: $0) }
            .filter { matchesSearch($0.title) || matchesSearch($0.subtitle) }

        var snapshot = Snapshot()
        snapshot.appendSections([.favoritePoints])
        snapshot.appendItems(folders.map { .folder($0) }, toSection: .favoritePoints)
        snapshot.appendItems(favorites.map { .favorite($0) }, toSection: .favoritePoints)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func favoriteFoldersBySection(parentGroupName: String?) -> [FavoriteFolderSection: [FavoriteFolder]] {
        let folders = directFavoriteFolders(parentGroupName: parentGroupName)
            .filter { matchesSearch($0.title) }

        return [
            .pinned: folders.filter { $0.isPinned },
            .visible: folders.filter { $0.isVisible && !$0.isPinned },
            .hidden: folders.filter { !$0.isVisible && !$0.isPinned }
        ]
    }

    private func rootSections(foldersBySection: [FavoriteFolderSection: [FavoriteFolder]]) -> [FavoriteFolderSection] {
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

    private func directFavoriteFolders(parentGroupName: String?) -> [FavoriteFolder] {
        let allFolders = FavoriteFoldersBridge.favoriteFolders().map { FavoriteFolder(item: $0) }
        let groupedFolders = Dictionary(grouping: allFolders) { folder in
            directChildGroupName(for: folder.groupName, parentGroupName: parentGroupName)
        }

        return groupedFolders.compactMap { entry -> FavoriteFolder? in
            guard let groupName = entry.key else { return nil }
            return FavoriteFolder(groupName: groupName, folders: entry.value)
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private func directChildGroupName(for groupName: String, parentGroupName: String?) -> String? {
        guard let parentGroupName else {
            if groupName.isEmpty {
                return groupName
            }
            return groupName.components(separatedBy: "/").first
        }

        guard !parentGroupName.isEmpty else {
            return nil
        }

        guard groupName != parentGroupName,
              groupName.hasPrefix(parentGroupName + "/") else {
            return nil
        }

        let childPath = String(groupName.dropFirst(parentGroupName.count + 1))
        guard let childName = childPath.components(separatedBy: "/").first, !childName.isEmpty else {
            return nil
        }

        return "\(parentGroupName)/\(childName)"
    }

    private func matchesSearch(_ text: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return text?.localizedCaseInsensitiveContains(searchText) ?? false
    }

    private func actionsMenu() -> UIMenu {
        let importAction = UIAction(
            title: localizedString("shared_string_import"),
            image: menuImage("ic_custom_import_outlined")
        ) { [weak self] _ in
            self?.onImportClicked()
        }

        return UIMenu(title: "", options: .displayInline, children: [importAction])
    }

    @objc private func selectButtonPressed(_ sender: UIBarButtonItem) {
        setEdit(true)
    }

    @objc private func cancelButtonPressed(_ sender: UIBarButtonItem) {
        setEdit(false)
    }

    private func setEdit(_ isEdit: Bool) {
        if !isEdit {
            collectionView.indexPathsForSelectedItems?.forEach {
                collectionView.deselectItem(at: $0, animated: false)
            }
        }

        collectionView.isEditing = isEdit
        collectionView.reloadData()
        myPlacesDelegate?.updateEditMode(isEdit)
        configureNavigation()
    }

    private func onImportClicked() {
        let gpxType = UTType(filenameExtension: "gpx") ?? UTType(importedAs: "com.topografix.gpx", conformingTo: .xml)
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [gpxType], asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }

    @objc private func favoriteGroupsDidChange(_ notification: Notification) {
        applySnapshot(animatingDifferences: true)
    }

    private func makeFolderContextMenu(for folder: FavoriteFolder, indexPath: IndexPath) -> UIMenu {
        let showHideAction = UIAction(
            title: localizedString(folder.isVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"),
            image: menuImage(folder.isVisible ? "ic_custom_hide_outlined" : "ic_custom_show_outlined")
        ) { [weak self] _ in
            FavoriteFoldersBridge.setFavoriteGroupVisible(folder.groupName, visible: !folder.isVisible)
            self?.applySnapshot(animatingDifferences: true)
        }

        let pinAction = UIAction(
            title: localizedString(folder.isPinned ? "unpin_folder" : "pin_folder"),
            image: menuImage("ic_custom_map_pin_outlined")
        ) { [weak self] _ in
            FavoriteFoldersBridge.setFavoriteGroupPinned(folder.groupName, pinned: !folder.isPinned)
            self?.applySnapshot(animatingDifferences: true)
        }
        let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showHideAction, pinAction])

        let renameAction = UIAction(
            title: localizedString("shared_string_rename"),
            image: menuImage("ic_custom_edit")
        ) { [weak self] _ in
            self?.showRenameAlert(for: folder)
        }
        let defaultAppearanceAction = UIAction(
            title: localizedString("default_appearance"),
            image: menuImage("ic_custom_appearance_outlined")
        ) { [weak self] _ in
            guard let navigationController = self?.navigationController else { return }
            FavoriteFoldersBridge.openFavoriteGroupAppearance(folder.groupName, navigationController: navigationController)
        }
        let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction, defaultAppearanceAction])

        let shareAction = UIAction(
            title: localizedString("shared_string_share"),
            image: menuImage("ic_custom_export_outlined")
        ) { [weak self] _ in
            guard let self else { return }
            let sourceView: UIView = self.collectionView.cellForItem(at: indexPath) ?? self.collectionView
            FavoriteFoldersBridge.shareFavoriteGroup(folder.groupName, sourceView: sourceView, viewController: self)
        }
        let moveAction = UIAction(
            title: localizedString("shared_string_move"),
            image: menuImage("ic_custom_folder_move_outlined")
        ) { [weak self] _ in
            guard let navigationController = self?.navigationController else { return }
            FavoriteFoldersBridge.openFavoriteGroupMove(folder.groupName, navigationController: navigationController)
        }
        let thirdButtonsSection = UIMenu(
            title: "",
            options: .displayInline,
            children: folder.groupName.isEmpty ? [shareAction] : [shareAction, moveAction]
        )

        let mapMarkersAction = UIAction(
            title: localizedString("map_markers"),
            image: menuImage("ic_custom_map_pin_outlined")
        ) { _ in
            FavoriteFoldersBridge.addFavoriteGroup(toMapMarkers: folder.groupName)
        }
        let trackAction = UIAction(
            title: localizedString("add_to_a_track"),
            image: menuImage("ic_custom_trip")
        ) { [weak self] _ in
            guard let navigationController = self?.navigationController else { return }
            FavoriteFoldersBridge.openFavoriteGroupAdd(toTrack: folder.groupName, navigationController: navigationController)
        }
        let navigationAction = UIAction(
            title: localizedString("shared_string_navigation"),
            image: menuImage("ic_custom_navigation_outlined")
        ) { _ in
            FavoriteFoldersBridge.addFavoriteGroup(toNavigation: folder.groupName)
        }
        let addToMenu = UIMenu(
            title: localizedString("shared_string_add"),
            image: menuImage("ic_custom_add"),
            children: [mapMarkersAction, trackAction, navigationAction]
        )
        let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [addToMenu])

        let deleteAction = UIAction(
            title: localizedString("shared_string_delete"),
            image: menuImage("ic_custom_trash_outlined"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.showDeleteAlert(for: folder)
        }
        let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])

        return UIMenu(title: "", children: [
            firstButtonsSection,
            secondButtonsSection,
            thirdButtonsSection,
            fourthButtonsSection,
            lastButtonsSection
        ])
    }

    private func showRenameAlert(for folder: FavoriteFolder) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"),
                                      message: localizedString("enter_new_name"),
                                      preferredStyle: .alert)
        let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self, weak alert] _ in
            guard let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return }

            FavoriteFoldersBridge.renameFavoriteGroup(folder.groupName, newName: text)
            self?.applySnapshot(animatingDifferences: true)
        }
        alert.addAction(applyAction)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.addTextField { textField in
            textField.placeholder = localizedString("enter_new_name")
            textField.text = folder.groupName
        }
        alert.preferredAction = applyAction
        present(alert, animated: true)
    }

    private func showDeleteAlert(for folder: FavoriteFolder) {
        let alert = UIAlertController(title: nil,
                                      message: localizedString("fav_remove_q"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_yes"), style: .destructive) { [weak self] _ in
            FavoriteFoldersBridge.deleteFavoriteGroup(folder.groupName)
            self?.applySnapshot(animatingDifferences: true)
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_no"), style: .cancel))
        present(alert, animated: true)
    }

    private func menuImage(_ name: String) -> UIImage? {
        UIImage(named: name)?.resizedMenuImage()
    }
}

private extension FavoriteListViewController.FavoriteFolder {
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
        guard !isVisible,
              let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else {
            return .preferredFont(forTextStyle: .body)
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

private extension FavoriteListViewController.FavoritePoint {
    var titleColor: UIColor {
        isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !isVisible,
              let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else {
            return .preferredFont(forTextStyle: .body)
        }
        return UIFont(descriptor: descriptor, size: 0)
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

            let viewController = FavoriteListViewController(frame: view.bounds,
                                                            folder: folder,
                                                            previousTitle: normalTitle)
            viewController.myPlacesDelegate = myPlacesDelegate
            navigationController?.pushViewController(viewController, animated: true)
        case .favorite(let favorite):
            if collectionView.isEditing {
                updateNavigationBarTitle()
                return
            }

            FavoriteFoldersBridge.openFavoritePoint(withIdentifier: favorite.identifier)
        case .header:
            break
        }

        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView.isEditing else { return }

        updateNavigationBarTitle()
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard !collectionView.isEditing else { return nil }
        guard let item = dataSource.itemIdentifier(for: indexPath),
              case .folder(let folder) = item,
              !folder.isVirtual else { return nil }

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
