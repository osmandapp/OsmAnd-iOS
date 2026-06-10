//
//  ImportTracksViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 08.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

final class ImportTrackItem: Hashable {
    let index: Int
    let name: String
    let gpxFile: GpxFile
    var analysis: GpxTrackAnalysis?
    var statisticsCells: [OAGPXTableCellData] = []
    var selectedPoints: [WptPt] = []
    var suggestedPoints: [WptPt] = []
    var previewImage: UIImage?
    var isPreviewLoading = false
    var bitmapDrawer: TrackBitmapDrawer?

    init(index: Int, name: String, gpxFile: GpxFile, selectedPoints: [WptPt], suggestedPoints: [WptPt]) {
        self.index = index
        self.name = name
        self.gpxFile = gpxFile
        self.selectedPoints = selectedPoints
        self.suggestedPoints = suggestedPoints
    }
  
    static func == (lhs: ImportTrackItem, rhs: ImportTrackItem) -> Bool {
        lhs.index == rhs.index
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}

@objc protocol ImportTracksViewControllerDelegate: AnyObject {
    @objc optional func importTracksViewControllerDidFinishImport(_ controller: ImportTracksViewController, success: Bool)
    @objc optional func importTracksViewController(_ controller: ImportTracksViewController, didSaveTrack success: Bool, gpxFile: GpxFile)
}

final class ImportTracksViewController: OABaseButtonsViewController {
    private enum RowKey: String {
        case infoDescr
        case importAsOne
        case trackHeader
        case trackPreview
        case trackStats
        case trackWaypoints
        case selectGroups
        case folderChips
    }

    private enum RowObjKey {
        static let importTrackItem = "importTrackItem"
        static let tracksCount = "tracksCount"
        static let attributedTitleKey = "attributedTitle"
        static let statisticsCells = "statisticsCells"
        
        static let foldersValues = "values"
        static let foldersSizes = "sizes"
        static let foldersSelectedValue = "selectedValue"
        static let foldersAddButtonTitle = "addButtonTitle"
    }
    
    weak var delegate: ImportTracksViewControllerDelegate?
    
    // Input
    private let gpxFile: GpxFile
    private let fileName: String
    private var selectedFolderPath: String
    private let importURL: URL?
    private let openGpxView: Bool
    private var importCompletion: ((Bool) -> Void)?
    // Tracks
    private var trackItems: [ImportTrackItem] = []
    private var selectedTracks: Set<ImportTrackItem> = []
    private var isCollectingTracks = false
    private var isSavingTracks = false
    private var collectTracksTask: CollectTracksTask?
    private let trackPreviewManager = TrackPreviewManager()
    // Folders
    private var folderNames: [String] = []
    private var selectedFolderIndex: Int = 0
    private let foldersScrollState = OACollectionViewCellState()
    // UI
    private let progressStackView = UIStackView()
    private let progressIndicator = UIActivityIndicatorView(style: .medium)
    private let progressLabel = UILabel()
    
    // MARK: - Init
    
    @objc(initWithGpxFile:fileName:selectedFolderPath:importURL:openGpxView:completion:)
    init(gpxFile: GpxFile, fileName: String, selectedFolderPath: String?, importURL: URL?, openGpxView: Bool, completion: ((Bool) -> Void)?) {
        self.gpxFile = gpxFile
        self.fileName = fileName
        self.importURL = importURL
        self.openGpxView = openGpxView
        self.importCompletion = completion
        
        if let selectedFolderPath, !selectedFolderPath.isEmpty {
            self.selectedFolderPath = selectedFolderPath
        } else {
            let app = OsmAndApp.swiftInstance()
            self.selectedFolderPath = (app?.gpxPath as? String)?.appending("/import") ?? ""
        }
        super.init()
    }
    
    @available(*, unavailable)
    override init() {
        fatalError("Use init(gpxFile:fileName:selectedFolderPath:importURL:openGpxView:completion:)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        trackPreviewManager.cancelAll(trackItems)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressView()
        collectTracks()
        reloadFolderNames()
    }
    
    // MARK: - Table
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OAImageDescTableViewCell.reuseIdentifier)
        tableView.register(FolderCardsCell.self, forCellReuseIdentifier: FolderCardsCell.reuseIdentifier)
        tableView.register(TrackStatsTableCell.self, forCellReuseIdentifier: TrackStatsTableCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()

        guard !trackItems.isEmpty else { return }

        // Info
        let infoSection = tableData.createNewSection()

        let descrRow = infoSection.createNewRow()
        descrRow.cellType = OASimpleTableViewCell.reuseIdentifier
        descrRow.key = RowKey.infoDescr.rawValue
        descrRow.setObj(makeImportTracksDescription(fileName: fileName, tracksCount: trackItems.count), forKey: RowObjKey.attributedTitleKey)

        let importAsOneRow = infoSection.createNewRow()
        importAsOneRow.cellType = OASimpleTableViewCell.reuseIdentifier
        importAsOneRow.key = RowKey.importAsOne.rawValue
        importAsOneRow.title = localizedString("import_as_one_track")

        // Tracks
        for item in trackItems {
            // Header
            let section = tableData.createNewSection()
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.key = RowKey.trackHeader.rawValue
            row.title = item.name
            let ofPart = String(format: localizedString("ltr_or_rtl_combine_via_of"), item.index, trackItems.count)
            row.descr = String(format: localizedString("ltr_or_rtl_combine_via_space"), localizedString("shared_string_gpx_track"), ofPart)
            row.setObj(item, forKey: RowObjKey.importTrackItem)
            row.setObj(trackItems.count, forKey: RowObjKey.tracksCount)
            
            // Preview
            let previewRow = section.createNewRow()
            previewRow.cellType = OAImageDescTableViewCell.reuseIdentifier
            previewRow.key = RowKey.trackPreview.rawValue
            previewRow.setObj(item, forKey: RowObjKey.importTrackItem)
            
            // Stats
            if !item.statisticsCells.isEmpty {
                let statsRow = section.createNewRow()
                statsRow.cellType = TrackStatsTableCell.reuseIdentifier
                statsRow.key = RowKey.trackStats.rawValue
                statsRow.setObj(item.statisticsCells, forKey: RowObjKey.statisticsCells)
                statsRow.setObj(item, forKey: RowObjKey.importTrackItem)
            }
            
            let selectedPoints = item.selectedPoints.count
            let totalPoints = gpxFile.getPointsList().count
            let pointsRow = section.createNewRow()
            pointsRow.cellType = OAValueTableViewCell.reuseIdentifier
            pointsRow.key = RowKey.trackWaypoints.rawValue
            pointsRow.title = localizedString("shared_string_waypoints")
            pointsRow.descr = "\(selectedPoints)/\(totalPoints)"
            pointsRow.icon = .icCustomFolder
            pointsRow.iconTintColor = .iconColorActive
        }

        // Folders
        let folderSection = tableData.createNewSection()
        folderSection.headerText = localizedString("plan_route_folder")
        folderSection.footerText = localizedString("import_tracks_folders_footer")

        let selectGroupsRow = folderSection.createNewRow()
        selectGroupsRow.cellType = OAValueTableViewCell.reuseIdentifier
        selectGroupsRow.key = RowKey.selectGroups.rawValue
        selectGroupsRow.title = localizedString("select_group")
        selectGroupsRow.descr = folderNames[safe: selectedFolderIndex]

        let chipsRow = folderSection.createNewRow()
        chipsRow.cellType = FolderCardsCell.reuseIdentifier
        chipsRow.key = RowKey.folderChips.rawValue
        chipsRow.setObj(folderNames, forKey: RowObjKey.foldersValues)
        chipsRow.setObj(folderTrackCounts(), forKey: RowObjKey.foldersSizes)
        chipsRow.setObj(selectedFolderIndex, forKey: RowObjKey.foldersSelectedValue)
        chipsRow.setObj(localizedString("add_folder"), forKey: RowObjKey.foldersAddButtonTitle)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)

        switch item.cellType {
        case OASimpleTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.setCustomLeftSeparatorInset(true)
            
            if item.key == RowKey.infoDescr.rawValue,
                let attributed = item.obj(forKey: RowObjKey.attributedTitleKey) as? NSAttributedString {
                cell.descriptionLabel.attributedText = attributed
                cell.leftIconVisibility(false)
                cell.descriptionVisibility(true)
                cell.titleVisibility(false)
                hideSeparator(for: cell, false)
                cell.selectionStyle = .none
            } else if item.key == RowKey.importAsOne.rawValue {
                cell.titleLabel.text = item.title
                cell.titleLabel.textColor = .textColorActive
                cell.leftIconVisibility(false)
                cell.titleVisibility(true)
                cell.descriptionVisibility(false)
                hideSeparator(for: cell, true)
                cell.selectionStyle = .default
            } else if item.key == RowKey.trackHeader.rawValue,
                      let track = item.obj(forKey: RowObjKey.importTrackItem) as? ImportTrackItem {
                let selected = selectedTracks.contains(track)
                cell.titleLabel.text = item.title
                cell.titleLabel.textColor = .textColorPrimary
                cell.descriptionLabel.text = item.descr
                cell.leftIconView.image = selected ? .icCustomDone : .icCustomCheckboxUnselected
                cell.leftIconView.tintColor = selected ? .iconColorActive : .iconColorSecondary
                cell.leftIconVisibility(true)
                cell.titleVisibility(true)
                cell.descriptionVisibility(true)
                hideSeparator(for: cell, true)
                cell.selectionStyle = .default
            }
            cell.textStackView.isHidden = false
            
            return cell

        case OAValueTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            cell.valueVisibility(true)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.accessoryType = .disclosureIndicator
            cell.setCustomLeftSeparatorInset(true)
            hideSeparator(for: cell, true)
            
            if item.key == RowKey.trackWaypoints.rawValue {
                cell.leftIconVisibility(true)
                cell.leftIconView.image = item.icon
                cell.leftIconView.tintColor = item.iconTintColor
            }
            return cell

        case FolderCardsCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: FolderCardsCell.reuseIdentifier, for: indexPath) as! FolderCardsCell
            cell.selectionStyle = .none
            cell.delegate = self
            cell.cellIndex = indexPath
            cell.state = foldersScrollState
            cell.setValues(item.obj(forKey: RowObjKey.foldersValues) as? [String] ?? [],
                           sizes: item.obj(forKey: RowObjKey.foldersSizes) as? [NSNumber],
                           colors: nil,
                           hidden: nil,
                           addButtonTitle: item.string(forKey: RowObjKey.foldersAddButtonTitle) ?? localizedString("add_folder"),
                           withSelectedIndex: Int32(item.integer(forKey: RowObjKey.foldersSelectedValue)),
                           addButtonPosition: .beginning)
            return cell
            
        case TrackStatsTableCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: TrackStatsTableCell.reuseIdentifier, for: indexPath) as! TrackStatsTableCell
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            if let statisticsCells = item.obj(forKey: RowObjKey.statisticsCells) as? [OAGPXTableCellData] {
                cell.configure(statistics: statisticsCells)
            }
            hideSeparator(for: cell, false)
            return cell
            
        case OAImageDescTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OAImageDescTableViewCell.reuseIdentifier, for: indexPath) as! OAImageDescTableViewCell

            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.descView.isHidden = true
            cell.imageBottomToLabelConstraint.priority = .defaultLow
            cell.imageBottomConstraint.priority = .required
            cell.imageBottomConstraint.constant = 0
            cell.imageTopConstraint.constant = 0
            cell.iconView.contentMode = .scaleAspectFill
            cell.iconView.clipsToBounds = true
            cell.iconView.layer.cornerRadius = 10
            cell.iconViewHeight.constant = 96

            guard let trackItem = item.obj(forKey: RowObjKey.importTrackItem) as? ImportTrackItem else {
                return cell
            }

            if let image = trackItem.previewImage {
                cell.activityIndicatorView.stopAnimating()
                cell.activityIndicatorView.isHidden = true
                cell.iconView.image = image
            } else {
                cell.iconView.image = nil
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
            }
            hideSeparator(for: cell, true)
            return cell

        default:
            return UITableViewCell()
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        switch item.key {
        case RowKey.importAsOne.rawValue:
            importAsOneTrackAction()
        case RowKey.trackHeader.rawValue:
            guard let trackItem = item.obj(forKey: RowObjKey.importTrackItem) as? ImportTrackItem else { return }
            if selectedTracks.contains(trackItem) {
                selectedTracks.remove(trackItem)
            } else {
                selectedTracks.insert(trackItem)
            }
            updateButtonsState()
            tableView.reloadData()
        case RowKey.selectGroups.rawValue:
            showSelectFolderScreenAction()
        default:
            break
        }
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        let headerText = tableData.sectionData(for: UInt(section)).headerText
        if !headerText.isEmpty {
            return UITableView.automaticDimension
        }
        return 0
    }
    
    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        let headerText = tableData.sectionData(for: UInt(section)).footerText
        if !headerText.isEmpty {
            return UITableView.automaticDimension
        }
        return 16
    }
    
    // MARK: - NavBar
    
    override func getTitle() -> String? {
        localizedString("import_tracks")
    }
    
    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        .templateImageNamed("ic_navbar_close")
    }
    
    override func onLeftNavbarButtonPressed() {
        showExitConfirmationAction()
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]? {
        guard !trackItems.isEmpty, !isCollectingTracks, !isSavingTracks else {
            return nil
        }
        let allSelected = selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let button = OABaseNavbarViewController.createRightNavbarButton(title, icon: nil, color: .label,
                                                                              action: #selector(onSelectAllAction),
                                                                              target: self, menu: nil) else {
            return []
        }
        button.accessibilityLabel = title
        return [button]
    }
    
    override func updateNavbar() {
        super.updateNavbar()
        if let button = getLeftNavbarButton().customView as? UIButton {
            button.tintColor = .label
        }
    }
    
    private func updateSelectAllButtonTitle() {
        let allSelected = !trackItems.isEmpty && selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        if let button = navigationItem.rightBarButtonItems?.first?.customView as? UIButton {
            button.setTitle(title, for: .normal)
            button.sizeToFit()
            button.accessibilityLabel = title
        }
    }
    
    // MARK: - Bottom buttons
    
    override func getTopButtonTitle() -> String? {
        let selected = selectedTracks.count
        let total = trackItems.count
        return "\(localizedString("shared_string_import")) \(selected)/\(total)"
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        selectedTracks.isEmpty ? .inactive : .purple
    }

    override func isBottomSeparatorVisible() -> Bool {
        false
    }
    
    override func onTopButtonPressed() {
        importSelectedTracksAction()
    }
    
    // MARK: - Setup
    
    private func setupProgressView() {
        progressStackView.translatesAutoresizingMaskIntoConstraints = false
        progressStackView.axis = .vertical
        progressStackView.alignment = .center
        progressStackView.spacing = 16
        progressStackView.addArrangedSubview(progressIndicator)
        progressStackView.addArrangedSubview(progressLabel)
        view.addSubview(progressStackView)

        progressLabel.font = .preferredFont(forTextStyle: .subheadline)
        progressLabel.textColor = .textColorSecondary
        progressLabel.textAlignment = .center
        progressLabel.numberOfLines = 0
        progressLabel.adjustsFontForContentSizeCategory = true
        NSLayoutConstraint.activate([
            progressStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func updateProgress() {
        let progressVisible = isCollectingTracks || isSavingTracks
        if isCollectingTracks {
            progressLabel.text = localizedString("reading_file") + localizedString("shared_string_ellipsis")
        } else if isSavingTracks {
            progressLabel.text = String(format: localizedString("importing_from"), fileName)
        }
        if progressVisible {
            progressIndicator.startAnimating()
        } else {
            progressIndicator.stopAnimating()
        }
        progressStackView.isHidden = !progressVisible
        tableView.isHidden = progressVisible
        topButton.isHidden = progressVisible
        separatorBottomView.isHidden = progressVisible
    }
    
    private func collectTracks() {
        collectTracksTask = CollectTracksTask(gpxFile: gpxFile, fileName: fileName, listener: self)
        collectTracksTask?.execute()
    }
    
    private func updateButtonsState() {
        topButton.isEnabled = !selectedTracks.isEmpty
        updateBottomButtons()
        updateSelectAllButtonTitle()
    }

    // MARK: - Actions
    
    @objc private func onSelectAllAction() {
        if selectedTracks.count == trackItems.count {
            selectedTracks.removeAll()
        } else {
            selectedTracks = Set(trackItems)
        }
        updateButtonsState()
        tableView.reloadData()
    }
    
    private func importSelectedTracksAction() {
        // SaveTracksTask
    }
    
    private func importAsOneTrackAction() {
    }
    
    @objc
    private func showExitConfirmationAction() {
        let alert = UIAlertController(title: localizedString("import_tracks_cancel_title"),
                                      message: localizedString("import_tracks_cancel_descr"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_continue"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_close"), style: .destructive) { [weak self] _ in
            self?.collectTracksTask?.cancelled = true
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showSelectFolderScreenAction() {
        guard let vc = OASelectTrackFolderViewController(selectedFolderName: folderDisplayName(for: selectedFolderPath)) else {
            return
        }
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true)
    }
    
    private func showAddFolderScreenAction() {
        let vc = OAAddTrackFolderViewController()
        vc.delegate = self
        present(vc, animated: true)
    }
    
    // MARK: - Helpers methods
    
    private func hideSeparator(for cell: UITableViewCell, _ isHide: Bool) {
        let inset = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        cell.separatorInset = .init(top: 0, left: isHide ? inset : 16, bottom: 0, right: isHide ? -inset : 16)
    }
    
    private func makeImportTracksDescription(fileName: String, tracksCount: Int) -> NSAttributedString {
        let text: String
        if tracksCount == 1 {
            text = String(format: localizedString("import_tracks_descr_one"), fileName)
        } else {
            text = String(format: localizedString("import_tracks_descr_other"), fileName, tracksCount)
        }

        let baseFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let activeColor = UIColor.textColorActive

        let result = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: baseFont,
                .foregroundColor: UIColor.textColorPrimary
            ]
        )

        let fileRange = (text as NSString).range(of: fileName)
        if fileRange.location != NSNotFound {
            result.addAttribute(.foregroundColor, value: activeColor, range: fileRange)
        }

        return result
    }
    
    private func reloadFolderNames() {
        folderNames = OAUtilities.getGpxFoldersListSorted(true, shouldAddRootTracksFolder: true)
        selectedFolderIndex = folderIndex(for: selectedFolderPath)
    }

    private func folderIndex(for path: String) -> Int {
        let name = folderDisplayName(for: path)
        return folderNames.firstIndex(of: name) ?? 0
    }

    private func folderDisplayName(for path: String) -> String {
        let gpxPath = OsmAndApp.swiftInstance().gpxPath ?? ""
        let folderPath = (path as NSString).deletingLastPathComponent
        if folderPath.isEmpty || folderPath == gpxPath {
            return localizedString("shared_string_gpx_tracks")
        }
        return (folderPath as NSString).lastPathComponent
    }

    private func folderPath(forDisplayName name: String) -> String {
        let gpxPath = OsmAndApp.swiftInstance().gpxPath ?? ""
        if name == localizedString("shared_string_gpx_tracks") {
            return gpxPath
        }
        return gpxPath.appendingPathComponent(name)
    }
    
    private func folderTrackCounts() -> [NSNumber] {
        let gpxPath = OsmAndApp.swiftInstance().gpxPath ?? ""
        let items = GpxDbHelper.shared.getItems()
        let rootTitle = localizedString("shared_string_gpx_tracks")

        return folderNames.map { name in
            let folderPath = folderPath(forDisplayName: name)
            let count = items.filter { item in
                let filePath = item.file.path()
                if name == rootTitle {
                    return (filePath as NSString).deletingLastPathComponent == gpxPath
                }
                return filePath.hasPrefix(folderPath + "/")
            }.count
            return NSNumber(value: count)
        }
    }

    private func reloadPreviewRow(for item: ImportTrackItem) {
        for section in 0..<tableData.sectionCount() {
            for row in 0..<tableData.rowCount(section) {
                let indexPath = IndexPath(row: Int(row), section: Int(section))
                let rowItem = tableData.item(for: indexPath)
                guard rowItem.key == RowKey.trackPreview.rawValue,
                      let trackItem = rowItem.obj(forKey: RowObjKey.importTrackItem) as? ImportTrackItem,
                      trackItem.index == item.index else { continue }
                tableView.reloadRows(at: [indexPath], with: .none)
                return
            }
        }
    }
}

// MARK: - CollectTracksListener

extension ImportTracksViewController: CollectTracksListener {
    func tracksCollectionStarted() {
        isCollectingTracks = true
        updateProgress()
    }

    func tracksCollectionFinished(_ items: [ImportTrackItem]) {
        collectTracksTask = nil
        isCollectingTracks = false
        trackItems = items
        selectedTracks = Set(items)
        for item in trackItems {
            if let analysis = item.analysis {
                item.statisticsCells = OATrackMenuHeaderView.generateGpxBlockStatistics(analysis, withoutGaps: false) as? [OAGPXTableCellData] ?? []
            }
        }
        updateProgress()
        updateNavbar()
        updateButtonsState()
        generateData()
        tableView.reloadData()
        
        let params = MapDrawParams.importTrackPreviewParams(size: .init(width: tableView.bounds.width - 64, height: 96))
        trackPreviewManager.startPreviews(for: items, params: params) { [weak self] item in
            self?.reloadPreviewRow(for: item)
        }
    }
}

// MARK: - FolderCardsCellDelegate

extension ImportTracksViewController: FolderCardsCellDelegate {
    func onItemSelected(_ index: Int) {
        guard folderNames.indices.contains(index) else { return }
        selectedFolderIndex = index
        selectedFolderPath = folderPath(forDisplayName: folderNames[index])
        generateData()
        tableView.reloadData()
    }
    func onAddFolderButtonPressed() {
        showAddFolderScreenAction()
    }
}

// MARK: - OASelectTrackFolderDelegate

extension ImportTracksViewController: OASelectTrackFolderDelegate {
    func onFolderSelected(_ selectedFolderName: String?) {
        guard let selectedFolderName else { return }
//        let validFolders = selectedFolders.filter { smartFolderHelper.getSmartFolder(name: $0) == nil }
//        if !selectedTracks.isEmpty || !validFolders.isEmpty {
//            let fullRelativeFolders = validFolders.map { folderName -> String in
//                var trimmedPath = currentFolderPath.hasPrefix("/") ? String(currentFolderPath.dropFirst()) : currentFolderPath
//                trimmedPath = trimmedPath.appendingPathComponent(folderName)
//                return trimmedPath
//            }
//            performMove(toFolder: selectedFolderName, tracks: selectedTracks, folders: fullRelativeFolders)
//        } else if let track = selectedTrack {
//            performMove(toFolder: selectedFolderName, tracks: [track], folders: nil)
//        } else if let folderPath = selectedFolderPath {
//            performMove(toFolder: selectedFolderName, tracks: nil, folders: [folderPath])
//        }
//        
//        updateAllFoldersVCData(forceLoad: true)
    }
    
    func onFolderAdded(_ addedFolderName: String) {
//        let newFolderPath = getAbsolutePath(addedFolderName)
//        if !FileManager.default.fileExists(atPath: newFolderPath) {
//            do {
//                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
//                onFolderSelected(addedFolderName)
//            } catch let error {
//                debugPrint(error)
//            }
//        }
    }
}

extension ImportTracksViewController: OAAddTrackFolderDelegate {
    func onTrackFolderAdded(_ folderName: String) {
        print(folderName)
    }
}
