//
//  OsmEditsListViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class SortHeader: NSObject {
    let sortMode: MyPlacesSortMode
    let menu: UIMenu
    
    init(sortMode: MyPlacesSortMode, menu: UIMenu) {
        self.sortMode = sortMode
        self.menu = menu
    }
}

final class Header: NSObject {
    let title: String
    let points: [OsmPoint]
    
    init(title: String, points: [OsmPoint]) {
        self.title = title
        self.points = points
    }
}

final class OsmPoint: NSObject {
    let title: String
    let poiType: String?
    let descr: String
    let item: OAOsmPoint
    
    init(title: String, poiType: String? = nil, descr: String, item: OAOsmPoint) {
        self.title = title
        self.poiType = poiType
        self.descr = descr
        self.item = item
    }
}

final class OsmEditsListViewController: UIViewController, MyPlacesScrollResettable {
    private typealias DataSource = UICollectionViewDiffableDataSource<Header, ListItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Header, ListItem>
    
    enum ListItem: Hashable {
        case sortHeader(SortHeader)
        case header(Header)
        case point(OsmPoint)
        case emptyState

        var selectionItem: OsmPoint? {
            guard case .point(let point) = self else { return nil }
            return point
        }
    }
    
    // MARK: - Properties
    
    private static let imageSize: CGFloat = 30
    private static let sortHeaderHeight: CGFloat = 44.0

    weak var myPlacesDelegate: MyPlacesDelegate?
    
    private var dataSource: DataSource!
    private var collectionView: UICollectionView!

    private let settings = OAAppSettings.sharedManager()

    private var pendingNotes: [Any]?
    private var headerViews: [UITableViewHeaderFooterView] = []

    private var selectButton: UIBarButtonItem?
    private var searchButton: UIBarButtonItem?

    private var sortMode: MyPlacesSortMode = .nameAZ
    private var isSearchActive = false
    private var isSelectionModeInSearch = false
    private var selectionManager = SelectionManager<OsmPoint>(allItems: [])

    private let estimatedRowHeight: CGFloat = 48.0
    private let poiTypeTag = "poi_type_tag"
    
    private let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OsmPoint> { cell, _, item in
        let translatedNames = OAPOIHelper.sharedInstance().getAllTranslatedNames(false)
        var poiType: OAPOIType?
        if let poiTypeString = item.poiType {
            poiType = translatedNames[poiTypeString]
        }
        var content = cell.defaultContentConfiguration()
        content.image = poiType?.icon().resizedTemplateImage(with: imageSize) ?? .icCustomOsmNoteUnresolved.withRenderingMode(.alwaysOriginal)
        content.text = item.title
        content.secondaryText = item.descr
        var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
        backgroundConfig.backgroundColor = .groupBg
        cell.backgroundConfiguration = backgroundConfig
        cell.contentConfiguration = content
        cell.accessories = [.multiselect()]
    }
    
    private let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Header> { (cell, _, headerItem) in
        var content = cell.defaultContentConfiguration()
        content.text = headerItem.title
        content.textProperties.color = .textColorPrimary
        content.textProperties.font = .systemFont(ofSize: 20, weight: .semibold)
        cell.contentConfiguration = content
        
        let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
        cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
        cell.tintColor = .iconColorActive
    }
    
    private let sortHeaderCellRegistration = UICollectionView.CellRegistration<SortButtonCollectionViewCell, SortHeader> { (cell, _, headerItem) in
        cell.sortButton.setImage(headerItem.sortMode.image?.resizedMenuImage(), for: .normal)
        cell.sortButton.menu = headerItem.menu
    }

    private let emptyStateCellRegistration = UICollectionView.CellRegistration<EmptyStateCollectionViewCell, Void>(cellNib: UINib(nibName: EmptyStateCollectionViewCell.reuseIdentifier, bundle: nil)) { cell, _, _ in
        cell.configure(image: .icActionOpenstreetmapLogo, title: localizedString("osm_edits_empty_state_title"), description: localizedString("osm_edits_empty_state_description"))
        cell.button.isHidden = true
    }

    // MARK: - Init

    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
        self.view.frame = frame
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        sortMode = savedSortMode()
        configureCollectionView()
        dataSource = makeDataSource()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)

        setupNavbarButtons()
        
        definesPresentationContext = true
        updateNavigationBarTitle()

        myPlacesDelegate?.updateContentScrollView(collectionView)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        definesPresentationContext = false
    }

    func resetScrollPosition() {
        let indexPath = IndexPath(item: 0, section: 0)
        guard collectionView.numberOfSections > indexPath.section,
              collectionView.numberOfItems(inSection: indexPath.section) > indexPath.item else {
            return
        }

        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
    }

    // MARK: - Generate Data
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .viewBg
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .onDrag
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.tintColor = .iconColorActive
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func sortHeaderLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(Self.sortHeaderHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self else { return nil }
            if self.isSortHeaderSection(at: sectionIndex) {
                return self.sortHeaderLayoutSection()
            }

            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.backgroundColor = .clear
            if !self.isSearchActive && !self.isSelectionModeInSearch && !self.isEmptyStateSection(at: sectionIndex) {
                config.headerMode = .firstItemInSection
            }

            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
        }
    }

    private func isSortHeaderSection(at sectionIndex: Int) -> Bool {
        guard let dataSource else { return false }
        let snapshot = dataSource.snapshot()
        guard snapshot.sectionIdentifiers.indices.contains(sectionIndex) else { return false }
        let section = snapshot.sectionIdentifiers[sectionIndex]
        return snapshot.itemIdentifiers(inSection: section).contains {
            guard case .sortHeader = $0 else { return false }
            return true
        }
    }

    private func isEmptyStateSection(at sectionIndex: Int) -> Bool {
        guard let dataSource else { return false }
        let snapshot = dataSource.snapshot()
        guard snapshot.sectionIdentifiers.indices.contains(sectionIndex) else { return false }
        return snapshot.itemIdentifiers(inSection: snapshot.sectionIdentifiers[sectionIndex]).contains(.emptyState)
    }
    
    private func makeDataSource() -> DataSource {
        let source = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item -> UICollectionViewCell in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .sortHeader(let headerItem):
                return collectionView.dequeueConfiguredReusableCell(using: sortHeaderCellRegistration, for: indexPath, item: headerItem)
            case .header(let headerItem):
                return collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: headerItem)
            case .point(let pointItem):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: pointItem)
            case .emptyState:
                return collectionView.dequeueConfiguredReusableCell(using: emptyStateCellRegistration, for: indexPath, item: ())
            }
        }

        return source
    }
    
    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = Snapshot()
        let poi = OAOsmEditsDBHelper.sharedDatabase().getOpenstreetmapPoints()
        let notes = OAOsmBugsDBHelper.sharedDatabase().getOsmBugsPoints()
        guard !poi.isEmpty || !notes.isEmpty else {
            let emptyStateSection = Header(title: "", points: [])
            snapshot.appendSections([emptyStateSection])
            snapshot.appendItems([.emptyState], toSection: emptyStateSection)
            dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
            return
        }
        
        let sortSection = Header(title: "", points: [])
        let sortHeader = SortHeader(sortMode: sortMode, menu: createSortMenu())
        snapshot.appendSections([sortSection])
        snapshot.appendItems([ListItem.sortHeader(sortHeader)], toSection: sortSection)
        
        if isSearchActive {
            var points: [OsmPoint] = []
            if !poi.isEmpty || !notes.isEmpty {
                let osmEdits = MyPlacesSortModeHelper.sortOsmEditsWithMode(poi + notes, mode: sortMode)
                
                for osmEdit in osmEdits {
                    let name = osmEdit.getName()
                    
                    if let poiEdit = osmEdit as? OAOpenStreetMapPoint {
                        let poiType = poiEdit.tag(from: poiTypeTag)?.lowercased()
                        points.append(OsmPoint(
                            title: name.isEmpty ? description(point: osmEdit) : name,
                            poiType: poiType,
                            descr: description(point: osmEdit),
                            item: osmEdit
                        ))
                    } else {
                        points.append(OsmPoint(
                            title: name,
                            descr: description(point: osmEdit),
                            item: osmEdit
                        ))
                    }
                }
            }
            let section = Header(title: "", points: [])
            snapshot.appendSections([section])
            snapshot.appendItems(points.map { ListItem.point($0) }, toSection: section)

            dataSource.apply(snapshot, animatingDifferences: false)
        } else {
            var headers: [Header] = []
            if !poi.isEmpty {
                let sortedPoi = MyPlacesSortModeHelper.sortOsmEditsWithMode(poi, mode: sortMode)
                var points: [OsmPoint] = []
                for point in sortedPoi {
                    if let point = point as? OAOpenStreetMapPoint {
                        let poiType = point.tag(from: poiTypeTag)?.lowercased()
                        let name = point.getName()
                        
                        points.append(OsmPoint(
                            title: name.isEmpty ? description(point: point) : name,
                            poiType: poiType,
                            descr: description(point: point),
                            item: point
                        ))
                    }
                }
                headers.append(Header(title: localizedString("poi"), points: points))
            }
            
            if !notes.isEmpty {
                let sortedNotes = MyPlacesSortModeHelper.sortOsmEditsWithMode(notes, mode: sortMode)
                var points: [OsmPoint] = []
                for point in sortedNotes {
                    points.append(OsmPoint(
                        title: point.getName(),
                        descr: description(point: point),
                        item: point
                    ))
                }
                headers.append(Header(title: localizedString("osm_edits_notes"), points: points))
            }
            
            snapshot.appendSections(headers)
            dataSource.apply(snapshot)
            
            for header in headers {
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()
                
                let headerListItem = ListItem.header(header)
                sectionSnapshot.append([headerListItem])
                
                let pointListItemArray = header.points.map { ListItem.point($0) }
                sectionSnapshot.append(pointListItemArray, to: headerListItem)
                sectionSnapshot.expand([headerListItem])
                
                dataSource.apply(sectionSnapshot, to: header, animatingDifferences: false)
            }
        }
    }
    
    private func setupNavbar() {
        if collectionView.isEditing {
            myPlacesDelegate?.showBackButton(false)

            let cancelButton = OABaseNavbarViewController.createRightNavbarButton(
                localizedString("shared_string_cancel"),
                icon: nil,
                color: .label,
                action: #selector(cancelButtonPressed(_:)),
                target: self,
                menu: nil
            )
            cancelButton?.accessibilityLabel = localizedString("shared_string_cancel")
            navigationController?.navigationBar.topItem?.leftBarButtonItem = cancelButton
            navigationItem.leftBarButtonItem = cancelButton
        } else {
            myPlacesDelegate?.showBackButton(true)
            navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
            navigationItem.leftBarButtonItem = nil
        }

        setupNavbarButtons()
    }

    private func setupNavbarButtons() {
        if collectionView.isEditing {
            let selectAllTitle = localizedString(selectionManager.areAllSelected ? "shared_string_deselect_all" : "shared_string_select_all")
            let selectAllButton = UIBarButtonItem(
                title: selectAllTitle,
                style: .plain,
                target: self,
                action: #selector(selectDeselectAllButtonPressed(_:))
            )
            selectAllButton.accessibilityLabel = selectAllTitle
            navigationController?.navigationBar.topItem?.setRightBarButtonItems([selectAllButton], animated: false)
            navigationItem.setRightBarButtonItems([selectAllButton], animated: false)
            return
        }

        selectButton = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(selectButtonPressed(_:)))
        selectButton?.tintColor = .textColorPrimary
        selectButton?.accessibilityLabel = localizedString("shared_string_select")

        let searchIcon = UIImage(systemName: "magnifyingglass",
                                 withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .textColorPrimary))
        searchButton = UIBarButtonItem(image: searchIcon,
                                       style: .plain,
                                       target: self,
                                       action: #selector(searchButtonPressed(_:)))
        searchButton?.accessibilityLabel = localizedString("shared_string_search")

        if #available(iOS 26.0, *) {
            searchButton?.style = .prominent
            searchButton?.tintColor = .clear
        }

        let rightButtons = [selectButton, isSearchActive || collectionView.isEditing ? nil : searchButton].compactMap { $0 }
        navigationController?.navigationBar.topItem?.setRightBarButtonItems(rightButtons, animated: false)
        navigationItem.setRightBarButtonItems(rightButtons, animated: false)
    }
    
    private func updateNavigationBarTitle() {
        var title = localizedString("osm_edits_title")
        if collectionView.isEditing {
            if selectionManager.selectedItems.isEmpty {
                title = localizedString("select_items")
            } else {
                let totalSelectedPoints = selectionManager.selectedItems.count
                let itemText = localizedString(totalSelectedPoints > 1 ? "shared_string_items" : "shared_string_item").lowercased()
                title = "\(NumberFormatter.localizedCount(totalSelectedPoints)) \(itemText)"
            }
        } else {
            title = localizedString("osm_edits_title")
        }
        
        myPlacesDelegate?.updateTitle(title, hideSubtitle: collectionView.isEditing)
    }
    
    private func setEdit(_ isEdit: Bool) {
        let shouldHideSearch = isEdit && isSearchActive
        let shouldResetSearchSelection = !isEdit && isSelectionModeInSearch
        if shouldHideSearch {
            isSearchActive = false
            isSelectionModeInSearch = true
        }

        if isEdit {
            let selectionItems = dataSource.snapshot().itemIdentifiers.compactMap { $0.selectionItem }
            selectionManager = SelectionManager(allItems: selectionItems)
        } else {
            selectionManager.deselectAll()
            updateCollectionViewSelection()
        }

        collectionView.isEditing = isEdit
        if shouldHideSearch {
            myPlacesDelegate?.updateSearchEnabling(false)
        } else if shouldResetSearchSelection {
            isSelectionModeInSearch = false
            collectionView.setCollectionViewLayout(createLayout(), animated: false)
            applySnapshot()
        }
        navigationController?.setToolbarHidden(!isEdit, animated: true)
        myPlacesDelegate?.updateEditMode(isEdit)
        setupNavbar()
        updateNavigationBarTitle()
        configureToolbar()
    }

    private func createSortMenu() -> UIMenu {
        let alphabeticalOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .nameAZ),
            createAction(for: .nameZA)
        ])

        return UIMenu(children: [alphabeticalOptions])
    }

    private func createAction(for sortType: MyPlacesSortMode) -> UIAction {
        let actionState: UIMenuElement.State = sortType == sortMode ? .on : .off
        return UIAction(title: sortType.title, image: sortType.image, state: actionState) { [weak self] _ in
            guard let self else { return }
            self.updateSortMode(sortType)
            self.sortMode = savedSortMode()
            applySnapshot()
        }
    }

    private func updateSortMode(_ sortMode: MyPlacesSortMode) {
        settings.osmEditsSortMode.set(sortMode.rawValue)
    }

    private func savedSortMode() -> MyPlacesSortMode {
        MyPlacesSortMode(rawValue: settings.osmEditsSortMode.get()) ?? MyPlacesSortModeHelper.defaultOsmEditsSortMode()
    }
    
    private func description(point: OAOsmPoint) -> String {
        var action = point.getLocalizedAction()
        let type = OAOsmEditingPlugin.getCategory(point)
        if !type.isEmpty {
            action += " • \(type)"
        }

        if point.getGroup() == .poi && point.getAction() != .CREATE {
            action += " • \(localizedString("osm_poi_id_label")) \(point.getId())"
        }

        return action
    }

    private func deleteConfirmationMessage(count: Int) -> NSAttributedString {
        let formattedCount = NumberFormatter.localizedCount(count)
        let message = String.localizedStringWithFormat(NSLocalizedString("osm_edits_delete_items_confirmation", comment: ""), count, formattedCount)
        let attributedString = NSMutableAttributedString(string: message)

        if let range = message.range(of: formattedCount) {
            let nsRange = NSRange(range, in: message)
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: nsRange)
        }

        return attributedString
    }

    private func delete(_ point: OAOsmPoint) {
        let attributedString = deleteConfirmationMessage(count: 1)
        
        let alert = UIAlertController(title: localizedString("delete_changes"), message: nil, preferredStyle: .alert)
        alert.setValue(attributedString, forKey: "attributedMessage")
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
        alert.addAction(
            UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
                guard let self else { return }
                
                if point.getGroup() == .poi {
                    if let point = point as? OAOpenStreetMapPoint {
                        OAOsmEditsDBHelper.sharedDatabase().deletePOI(point)
                    }
                } else {
                    if let point = point as? OAOsmNotePoint {
                        OAOsmBugsDBHelper.sharedDatabase().deleteAllBugModifications(point)
                    }
                }
                applySnapshot()
                OsmAndApp.swiftInstance().osmEditsChangeObservable.notifyEvent()
            }
        )
        present(alert, animated: true)
    }
    
    private func upload(_ point: OAOsmPoint) {
        if point.getGroup() == .poi {
            if let editsBottomsheet = OAOsmUploadPOIViewController(poiItems: [point]) {
                editsBottomsheet.delegate = self
                OARootViewController.instance().mapPanel.navigationController?.pushViewController(editsBottomsheet, animated: true)
            }
        } else {
            if let notesBottomsheet = OAOsmNoteViewController(
                editingPlugin: OAPluginsHelper.getPlugin(OAOsmEditingPlugin.self) as? OAOsmEditingPlugin,
                points: [point],
                type: .EOAOsmNoteViewConrollerModeUpload
            ) {
                notesBottomsheet.delegate = self
                OARootViewController.instance()
                    .mapPanel
                    .navigationController?
                    .pushViewController(notesBottomsheet, animated: true)
            }
        }
    }
    
    private func modify(_ point: OAOsmPoint) {
        if point.getGroup() == .poi {
            guard let point = point as? OAOpenStreetMapPoint,
                  let editingScreen = OAOsmEditingViewController(point: point) else {
                return
            }
            editingScreen.delegate = self
            navigationController?.pushViewController(editingScreen, animated: true)
        } else if let noteScreen = OAOsmNoteViewController(editingPlugin: OAPluginsHelper.getPlugin(OAOsmEditingPlugin.self) as? OAOsmEditingPlugin, points: [point], type: .EOAOsmNoteViewConrollerModeCreate) {
            let navigationController = UINavigationController(rootViewController: noteScreen)
            noteScreen.delegate = self
            self.navigationController?.present(navigationController, animated: true)
        }
    }
    
    private func configureToolbar() {
        if isSearchActive {
            let selectButton = UIBarButtonItem(
                title: localizedString("shared_string_select"),
                style: .plain,
                target: self,
                action: #selector(selectButtonPressed(_:))
            )
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.iconColorActive]
            selectButton.setTitleTextAttributes(attributes, for: .normal)
            myPlacesDelegate?.updateToolbar(with: [selectButton])
            return
        }

        let isSelected = !selectionManager.isEmpty
        
        let uploadButton = UIBarButtonItem(title: localizedString("shared_string_upload" ), style: .plain, target: self, action: #selector(uploadButtonPressed))
        let uploadAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.textColorActive]
        uploadButton.setTitleTextAttributes(uploadAttributes, for: .normal)
        uploadButton.isEnabled = isSelected
        
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let deleteButton = UIBarButtonItem(title: localizedString("shared_string_delete" ), style: .plain, target: self, action: #selector(deleteButtonPressed))
        let deleteAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.textColorDisruptive]
        deleteButton.setTitleTextAttributes(deleteAttributes, for: .normal)
        deleteButton.isEnabled = isSelected
        
        let items = [uploadButton, flexibleSpacer, deleteButton]
        myPlacesDelegate?.updateToolbar(with: items)
    }

    private func updateCollectionViewSelection() {
        for section in 0..<collectionView.numberOfSections {
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                guard let selectionItem = dataSource.itemIdentifier(for: indexPath)?.selectionItem else { continue }
                if selectionManager.selectedItems.contains(selectionItem) {
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                } else {
                    collectionView.deselectItem(at: indexPath, animated: false)
                }
            }
        }
    }
    
    // MARK: - Actions

    @objc
    private func selectButtonPressed(_ sender: Any) {
        setEdit(true)
    }
    
    @objc
    private func searchButtonPressed(_ sender: Any) {
        myPlacesDelegate?.updateSearchEnabling(true)
        isSearchActive = true
        setupNavbarButtons()
        navigationController?.setToolbarHidden(false, animated: true)
        configureToolbar()
    }

    @objc
    private func cancelButtonPressed(_ sender: Any) {
        setEdit(false)
    }

    @objc
    private func selectDeselectAllButtonPressed(_ sender: Any) {
        if selectionManager.areAllSelected {
            selectionManager.deselectAll()
        } else {
            selectionManager.selectAll()
        }
        updateCollectionViewSelection()
        updateNavigationBarTitle()
        setupNavbarButtons()
        configureToolbar()
    }
    
    @objc
    private func deleteButtonPressed(_ sender: Any) {
        let shouldEdit = !collectionView.isEditing
        let selectedPoints = Array(selectionManager.selectedItems)
        if !selectedPoints.isEmpty {
            let attributedString = deleteConfirmationMessage(count: selectedPoints.count)
            let alert = UIAlertController(title: localizedString("delete_changes"), message: nil, preferredStyle: .alert)
            alert.setValue(attributedString, forKey: "attributedMessage")
            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
            alert.addAction(
                UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
                    guard let self else { return }

                    for point in selectedPoints {
                        let item = point.item
                        if item.getGroup() == .poi {
                            if let item = item as? OAOpenStreetMapPoint {
                                OAOsmEditsDBHelper.sharedDatabase().deletePOI(item)
                            }
                        } else {
                            if let item = item as? OAOsmNotePoint {
                                OAOsmBugsDBHelper.sharedDatabase().deleteAllBugModifications(item)
                            }
                        }
                    }
                    setEdit(shouldEdit)
                    applySnapshot()
                    OsmAndApp.swiftInstance().osmEditsChangeObservable.notifyEvent()
                }
            )
            present(alert, animated: true)
        }
    }
    
    @objc
    private func uploadButtonPressed(_ sender: Any) {
        let shouldEdit = !collectionView.isEditing
        var edits: [OAOsmPoint] = []
        var notes: [OAOsmPoint] = []

        for point in selectionManager.selectedItems {
            let item = point.item
            if item.getGroup() == .poi {
                edits.append(item)
            } else {
                notes.append(item)
            }
        }

        if !edits.isEmpty {
            if let editsBottomsheet = OAOsmUploadPOIViewController(poiItems: edits) {
                editsBottomsheet.delegate = self
                pendingNotes = notes
                OARootViewController.instance().mapPanel.navigationController?.pushViewController(editsBottomsheet, animated: true)
            }
        } else if !notes.isEmpty {
            pendingNotes = nil

            if let notesBottomsheet = OAOsmNoteViewController(
                editingPlugin: OAPluginsHelper.getPlugin(OAOsmEditingPlugin.self) as? OAOsmEditingPlugin,
                points: notes,
                type: .EOAOsmNoteViewConrollerModeUpload
            ) {
                notesBottomsheet.delegate = self
                OARootViewController.instance()
                    .mapPanel
                    .navigationController?
                    .pushViewController(notesBottomsheet, animated: true)
            }
        }
        setEdit(shouldEdit)
    }

    // MARK: - Keyboard

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.collectionView.contentInset.bottom = frame.height
            self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset
        }
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.collectionView.contentInset.bottom = 0
            self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset
        }
    }
}

// MARK: - UICollectionViewDelegate
extension OsmEditsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath),
           case .point(let osmPoint) = item {
            if collectionView.isEditing {
                selectionManager.toggle(osmPoint)
            } else {
                navigationController?.popToRootViewController(animated: true)

                let mapPanel = OARootViewController.instance().mapPanel

                if let newTarget = mapPanel?.mapViewController.osmEditsTargetPoint(osmPoint.item, touch: nil) {
                    newTarget.centerMap = true
                    mapPanel?.showContextMenu(newTarget)
                }
            }
        }
        updateNavigationBarTitle()
        setupNavbarButtons()
        configureToolbar()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.isEditing,
           let selectionItem = dataSource.itemIdentifier(for: indexPath)?.selectionItem {
            selectionManager.toggle(selectionItem)
        }
        updateNavigationBarTitle()
        setupNavbarButtons()
        configureToolbar()
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath), case .point(let osmPoint) = item else {
            return nil
        }
        let menuProvider: UIContextMenuActionProvider = { [weak self] _ in
            guard let self else { return nil }
            let uploadToOsm = UIAction(title: localizedString("upload_to_osm_short"), image: .icCustomUploadToOpenstreetmapOutlined) { [weak self] _ in
                guard let self else { return }
                self.upload(osmPoint.item)
            }
            uploadToOsm.accessibilityLabel = localizedString("upload_to_osm_short")

            let modify = UIAction(title: localizedString("shared_string_modify"), image: .icCustomEdit) { [weak self] _ in
                guard let self else { return }
                self.modify(osmPoint.item)
            }
            modify.accessibilityLabel = localizedString("shared_string_modify")

            let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined) { [weak self] _ in
                guard let self else { return }
                self.delete(osmPoint.item)
            }
            deleteAction.accessibilityLabel = localizedString("shared_string_delete")
            deleteAction.attributes = .destructive

            return UIMenu.composedMenu(from: [[uploadToOsm, modify], [deleteAction]])
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
    }
}

// MARK: - OAOsmEditingBottomSheetDelegate
extension OsmEditsListViewController: OAOsmEditingBottomSheetDelegate {
    func refreshData() {
        applySnapshot()
    }
    
    func uploadFinished(_ hasError: Bool) {
        refreshData()

        if let pendingNotes,
           !pendingNotes.isEmpty && !hasError,
           let notesBottomsheet = OAOsmNoteViewController(
               editingPlugin: OAPluginsHelper.getPlugin(OAOsmEditingPlugin.self)
                   as? OAOsmEditingPlugin,
               points: pendingNotes,
               type: .EOAOsmNoteViewConrollerModeUpload
           ) {
            notesBottomsheet.delegate = self
            OARootViewController.instance().mapPanel.navigationController?.pushViewController(notesBottomsheet, animated: true)
        }

        pendingNotes = nil
    }
}

// MARK: - MyPlacesSearchable
extension OsmEditsListViewController: MyPlacesSearchable {
    func searchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.searchTextField.text ?? ""

        if searchController.isActive && searchText.isEmpty {
            isSearchActive = true
            collectionView.setCollectionViewLayout(createLayout(), animated: false)
            applySnapshot()
        } else if searchController.isActive && !searchText.isEmpty {
            isSearchActive = true
            var snapshot = Snapshot()
            let poi = OAOsmEditsDBHelper.sharedDatabase().getOpenstreetmapPoints()
            let notes = OAOsmBugsDBHelper.sharedDatabase().getOsmBugsPoints()
            var points: [OsmPoint] = []
            if !poi.isEmpty || !notes.isEmpty {
                let osmEdits = MyPlacesSortModeHelper.sortOsmEditsWithMode(poi + notes, mode: sortMode)
                
                for osmEdit in osmEdits {
                    let name = osmEdit.getName()
                    let nameTagRange = name.range(of: searchText, options: .caseInsensitive)
                    if nameTagRange != nil {
                        if let poiEdit = osmEdit as? OAOpenStreetMapPoint {
                            let poiType = poiEdit.tag(from: poiTypeTag)?.lowercased()
                            points.append(OsmPoint(
                                title: name.isEmpty ? description(point: osmEdit) : name,
                                poiType: poiType,
                                descr: description(point: osmEdit),
                                item: osmEdit
                            ))
                        } else {
                            points.append(OsmPoint(
                                title: name,
                                descr: description(point: osmEdit),
                                item: osmEdit
                            ))
                        }
                    }
                }
            }
            let section = Header(title: "", points: [])
            snapshot.appendSections([section])
            snapshot.appendItems(points.map { ListItem.point($0) }, toSection: section)
            dataSource.apply(snapshot, animatingDifferences: false)
        } else {
            isSearchActive = false
            if !isSelectionModeInSearch {
                collectionView.setCollectionViewLayout(createLayout(), animated: false)
                applySnapshot()
            }
        }
        setupNavbarButtons()
        navigationController?.setToolbarHidden(!searchController.isActive && !collectionView.isEditing, animated: true)
        configureToolbar()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        myPlacesDelegate?.updateSearchEnabling(false)
    }
}
