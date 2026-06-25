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

final class OsmEditsListViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<Header, ListItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Header, ListItem>
    
    enum ListItem: Hashable {
        case sortHeader(SortHeader)
        case header(Header)
        case point(OsmPoint)
    }
    
    // MARK: - Properties
    
    private static let imageSize: CGFloat = 30

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

    // MARK: - Generate Data
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
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
    
    private func createLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        if !isSearchActive {
            config.headerMode = .firstItemInSection
        }
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        return layout
    }
    
    private func makeDataSource() -> DataSource {
        let source = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item -> UICollectionViewCell in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .sortHeader(let headerItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: sortHeaderCellRegistration,
                                                                        for: indexPath,
                                                                        item: headerItem)
                return cell
            case .header(let headerItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                        for: indexPath,
                                                                        item: headerItem)
                return cell
            case .point(let pointItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                        for: indexPath,
                                                                        item: pointItem)
                return cell
            }
        }
        return source
    }
    
    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = Snapshot()
        let poi = OAOsmEditsDBHelper.sharedDatabase().getOpenstreetmapPoints()
        let notes = OAOsmBugsDBHelper.sharedDatabase().getOsmBugsPoints()
        
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
            navigationController?.navigationBar.topItem?.setRightBarButtonItems(nil, animated: false)
            navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }

        selectButton = OABaseNavbarViewController.createRightNavbarButton(
            nil,
            icon: UIImage(systemName: "checkmark.circle"),
            color: .label,
            action: #selector(selectButtonPressed(_:)),
            target: self,
            menu: nil
        )
        selectButton?.accessibilityLabel = localizedString("shared_string_select")

        searchButton = OABaseNavbarViewController.createRightNavbarButton(
            nil,
            icon: UIImage(systemName: "magnifyingglass"),
            color: .label,
            action: #selector(searchButtonPressed(_:)),
            target: self,
            menu: nil
        )
        searchButton?.accessibilityLabel = localizedString("shared_string_search")

        if #available(iOS 26.0, *) {
            searchButton?.style = .prominent
            searchButton?.tintColor = .navBarTextColorPrimary.withAlphaComponent(0.3)
        }

        let rightButtons = [selectButton, isSearchActive || collectionView.isEditing ? nil : searchButton].compactMap { $0 }
        navigationController?.navigationBar.topItem?.setRightBarButtonItems(rightButtons, animated: false)
        navigationItem.setRightBarButtonItems(rightButtons, animated: false)
    }
    
    private func updateNavigationBarTitle() {
        var title = localizedString("osm_edits_title")
        if collectionView.isEditing {
            let totalSelectedPoints = collectionView.indexPathsForSelectedItems?.count ?? 0
            if totalSelectedPoints == 0 {
                title = localizedString("select_items")
            } else {
                let itemText = localizedString(totalSelectedPoints > 1 ? "shared_string_items" : "shared_string_item").lowercased()
                title = "\(totalSelectedPoints) \(itemText)"
            }
        } else {
            title = localizedString("osm_edits_title")
        }
        
        myPlacesDelegate?.updateTitle(title, hideSubtitle: collectionView.isEditing)
    }
    
    private func setEdit(_ isEdit: Bool) {
        collectionView.isEditing = isEdit
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
        return UIAction(title: sortType.title, image: sortType.image?.resizedMenuImage(), state: actionState) { [weak self] _ in
            guard let self else { return }
            self.updateSortMode(sortType)
            self.sortMode = savedSortMode()
            applySnapshot()
        }
    }

    private func updateSortMode(_ sortMode: MyPlacesSortMode) {
        settings.osmEditsSortMode.set(sortMode.title)
    }

    private func savedSortMode() -> MyPlacesSortMode {
        MyPlacesSortMode.byTitle(settings.osmEditsSortMode.get())
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
    
    private func delete(_ point: OAOsmPoint) {
        let count = 1
        let message = String(format: localizedString("osm_edits_delete_item_confirmation"), count)
        let attributedString = NSMutableAttributedString(string: message)

        if let range = message.range(of: "\(count)") {
            let nsRange = NSRange(range, in: message)
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: nsRange)
        }
        
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
        let isSelected = !(collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
        
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
    }

    @objc
    private func cancelButtonPressed(_ sender: Any) {
        setEdit(false)
    }
    
    @objc
    private func deleteButtonPressed(_ sender: Any) {
        let shouldEdit = !collectionView.isEditing
        if let indexes = collectionView.indexPathsForSelectedItems, !indexes.isEmpty {
            let count = indexes.count
            let message = String(format: localizedString("osm_edits_delete_items_confirmation"), count)
            let attributedString = NSMutableAttributedString(string: message)

            if let range = message.range(of: "\(count)") {
                let nsRange = NSRange(range, in: message)
                attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: nsRange)
            }
            
            let alert = UIAlertController(title: localizedString("delete_changes"), message: nil, preferredStyle: .alert)
            alert.setValue(attributedString, forKey: "attributedMessage")
            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
            alert.addAction(
                UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
                    guard let self else { return }

                    for path in indexes {
                        guard case .point(let point) = dataSource.itemIdentifier(for: path) else {
                            continue
                        }

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
        let indexes = collectionView.indexPathsForSelectedItems ?? []
        var edits: [OAOsmPoint] = []
        var notes: [OAOsmPoint] = []

        for indexPath in indexes {
            guard case .point(let point) = dataSource.itemIdentifier(for: indexPath) else {
                continue
            }

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
        if let item = dataSource.itemIdentifier(for: indexPath), !collectionView.isEditing,
           case .point(let osmPoint) = item {
            navigationController?.popToRootViewController(animated: true)

            let mapPanel = OARootViewController.instance().mapPanel

            if let newTarget = mapPanel?.mapViewController.osmEditsTargetPoint(osmPoint.item, touch: nil) {
                newTarget.centerMap = true
                mapPanel?.showContextMenu(newTarget)
            }
        }
        updateNavigationBarTitle()
        configureToolbar()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateNavigationBarTitle()
        configureToolbar()
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath), case .point(let osmPoint) = item else {
            return nil
        }
        let menuProvider: UIContextMenuActionProvider = { [weak self] _ in
            guard let self else { return nil }
            let uploadToOsm = UIAction(title: localizedString("upload_to_osm_short"), image: .icCustomUploadToOpenstreetmapOutlined.resizedMenuImage()) { [weak self] _ in
                guard let self else { return }
                self.upload(osmPoint.item)
            }
            uploadToOsm.accessibilityLabel = localizedString("upload_to_osm_short")

            let modify = UIAction(title: localizedString("shared_string_modify"), image: .icCustomEdit.resizedMenuImage()) { [weak self] _ in
                guard let self else { return }
                self.modify(osmPoint.item)
            }
            modify.accessibilityLabel = localizedString("shared_string_modify")

            let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined.resizedMenuImage()) { [weak self] _ in
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
            collectionView.setCollectionViewLayout(createLayout(), animated: false)
            applySnapshot()
        }
        setupNavbarButtons()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        myPlacesDelegate?.updateSearchEnabling(false)
    }
}
