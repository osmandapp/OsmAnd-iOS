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
    private var importCompletion: ((Bool) -> Void)?
    // Tracks
    private var trackItems: [ImportTrackItem] = []
    private var selectedTracks: Set<ImportTrackItem> = []
    private var isCollectingTracks = false
    private var isSavingTracks = false
    private var lastSavedPath: String?
    // Managers
    private let trackPreviewManager = TrackPreviewManager()
    // Tasks
    private var collectTracksTask: CollectTracksTask?
    private var saveAsOneTrackTask: SaveGpxTask?
    private var saveTracksTask: SaveTracksTask?
    // Save
    private var successfulSaveCount = 0
    // Folders
    private var folderNames: [String] = []
    private var selectedFolderIndex: Int = 0
    private let foldersScrollState = OACollectionViewCellState()
    // UI
    private let progressStackView = UIStackView()
    private let progressIndicator = UIActivityIndicatorView(style: .medium)
    private let progressLabel = UILabel()
    
    // MARK: - Init
    
    @objc(initWithGpxFile:fileName:selectedFolderPath:importURL:completion:)
    init(gpxFile: GpxFile, fileName: String, selectedFolderPath: String?, importURL: URL?, completion: ((Bool) -> Void)?) {
        self.gpxFile = gpxFile
        self.fileName = fileName
        self.importURL = importURL
        self.importCompletion = completion
        
        if let selectedFolderPath, !selectedFolderPath.isEmpty {
            var path = selectedFolderPath
            if path.lowercased().hasSuffix(".gpx") {
                path = (path as NSString).deletingLastPathComponent
            }
            self.selectedFolderPath = path
        } else {
            let app = OsmAndApp.swiftInstance()
            self.selectedFolderPath = (app?.gpxPath as? String)?.appending("/import") ?? ""
        }
        super.init()
    }
    
    @available(*, unavailable)
    override init() {
        fatalError("Use init(gpxFile:fileName:selectedFolderPath:importURL:completion:)")
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
            //Waypoints
            let selectedPoints = item.selectedPoints.count
            let totalPoints = gpxFile.getPointsList().count
            let pointsRow = section.createNewRow()
            pointsRow.cellType = OAValueTableViewCell.reuseIdentifier
            pointsRow.key = RowKey.trackWaypoints.rawValue
            pointsRow.title = localizedString("shared_string_waypoints")
            pointsRow.descr = "\(selectedPoints)/\(totalPoints)"
            pointsRow.icon = .icCustomFolder
            pointsRow.iconTintColor = .iconColorActive
            pointsRow.setObj(item, forKey: RowObjKey.importTrackItem)
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
        chipsRow.setObj(localizedString("shared_string_add"), forKey: RowObjKey.foldersAddButtonTitle)
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
                cell.titleLabel.font = .preferredFont(forTextStyle: .body)
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
                cell.titleLabel.font = .preferredFont(forTextStyle: .headline)
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
            cell.iconDefaultColor = .iconColorSelected
            cell.setValues(item.obj(forKey: RowObjKey.foldersValues) as? [String] ?? [],
                           sizes: item.obj(forKey: RowObjKey.foldersSizes) as? [NSNumber],
                           colors: nil,
                           hidden: nil,
                           addButtonTitle: item.string(forKey: RowObjKey.foldersAddButtonTitle) ?? localizedString("shared_string_add"),
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
        case RowKey.trackWaypoints.rawValue:
            guard let trackItem = item.obj(forKey: RowObjKey.importTrackItem) as? ImportTrackItem else { return }
            showSelectWaypointsAction(track: trackItem)
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let folderCell = cell as? FolderCardsCell {
            folderCell.updateContentOffset()
        }
    }
    
    // MARK: - NavBar
    
    override func getTitle() -> String? {
        localizedString("import_tracks")
    }
    
    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        guard let image = UIImage.templateImageNamed("ic_navbar_close") else { return nil }
        return OAUtilities.resize(image, newSize: CGSize(width: 24, height: 24))?.withRenderingMode(.alwaysTemplate)
    }
    
    override func getCustomAccessibilityForLeftNavbarButton() -> String? {
        localizedString("shared_string_close")
    }
    
    override func onLeftNavbarButtonPressed() {
        showExitConfirmationAction()
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]? {
        let allSelected = selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        let item = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(onSelectAllAction))
        item.tintColor = .label
        item.accessibilityLabel = title
        return [item]
    }
    
    private func updateSelectAllButtonTitle() {
        let allSelected = !trackItems.isEmpty && selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let item = navigationItem.rightBarButtonItems?.first else { return }
        item.title = title
        item.accessibilityLabel = title
    }
    
    override func updateNavbar() {
        super.updateNavbar()
        (getLeftNavbarButton()?.customView as? UIButton)?.tintColor = .label
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
        guard !isCollectingTracks, !isSavingTracks else { return }
        guard !selectedTracks.isEmpty else { return }

        let items = selectedTracks.sorted { $0.index < $1.index }
        startSaveSelectedTracks(items: items)
    }

    private func startSaveSelectedTracks(items: [ImportTrackItem]) {
        saveTracksTask = SaveTracksTask(
            items: items,
            destinationDir: selectedFolderPath,
            listener: self
        )
        saveTracksTask?.execute()
    }
    
    private func importAsOneTrackAction() {
        guard !isCollectingTracks, !isSavingTracks else { return }
        if FileManager.default.fileExists(atPath: SaveGpxTask.plannedDestinationPath(
            destinationDir: selectedFolderPath,
            fileName: fileName
        )) {
            showFileExistsAlert { [weak self] overwrite in
                self?.startSaveAsOneTrack(overwrite: overwrite)
            }
        } else {
            startSaveAsOneTrack(overwrite: false)
        }
    }
    
    private func startSaveAsOneTrack(overwrite: Bool) {
        saveAsOneTrackTask = SaveGpxTask(
            gpxFile: gpxFile,
            destinationDir: selectedFolderPath,
            fileName: fileName,
            overwrite: overwrite,
            importURL: importURL,
            listener: self
        )
        saveAsOneTrackTask?.execute()
    }
    
    @objc
    private func showExitConfirmationAction() {
        guard !isSavingTracks else { return }
        
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
    
    private func showFileExistsAlert(onChoice: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: localizedString("import_tracks"),
                                      message: localizedString("gpx_import_already_exists"),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: localizedString("gpx_overwrite"), style: .destructive) { _ in onChoice(true) })
        alert.addAction(UIAlertAction(title: localizedString("gpx_add_new"), style: .default) { _ in onChoice(false) })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func showSelectFolderScreenAction() {
        guard let vc = OASelectTrackFolderViewController(selectedFolderName: folderDisplayName(for: selectedFolderPath)) else {
            return
        }
        vc.delegate = self
        vc.suggestedFolderName = suggestedFolderNameFromFile()
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true)
    }
    
    private func showAddFolderScreenAction() {
        let vc = OAAddTrackFolderViewController()
        vc.delegate = self
        vc.suggestedFolderName = suggestedFolderNameFromFile()
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true)
    }
    
    private func showSelectWaypointsAction(track: ImportTrackItem) {
        let vc = SelectWaypointsViewController(track: track, allPoints: gpxFile.getPointsList())
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
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

        let baseFont = UIFont.preferredFont(forTextStyle: .body)
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
    
    // MARK: - Folders helper methods
    
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
        if path.isEmpty || path == gpxPath {
            return localizedString("shared_string_gpx_tracks")
        }
        return (path as NSString).lastPathComponent
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
    
    private func indexPathForFoldersRow() -> IndexPath? {
        for section in 0..<tableData.sectionCount() {
            for row in 0..<tableData.rowCount(section) {
                let indexPath = IndexPath(row: Int(row), section: Int(section))
                let rowItem = tableData.item(for: indexPath)
                guard rowItem.key == RowKey.folderChips.rawValue else { continue }
                return indexPath
            }
        }
        return nil
    }
    
    private func applyFolderSelection(named name: String) {
        selectedFolderPath = folderPath(forDisplayName: name)
        reloadFolderNames()
        generateData()
        tableView.reloadData()
        
        guard let index = folderNames.firstIndex(of: name),
              let foldersIndexPath = indexPathForFoldersRow() else { return }
        tableView.layoutIfNeeded()
        if let cell = tableView.cellForRow(at: foldersIndexPath) as? FolderCardsCell {
            cell.setSelectedIndex(index)
            cell.scrollToFolder(at: index, animated: false)
        }
    }
    
    private func createAndSelectFolder(named name: String) {
        let path = folderPath(forDisplayName: name)
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                debugPrint(error)
                return
            }
        }
        applyFolderSelection(named: name)
    }
    
    private func suggestedFolderNameFromFile() -> String {
        (fileName as NSString).deletingPathExtension
    }
    
    // MARK: - Post import
    
    private func showSaveError(_ message: String) {
        OAUtilities.showToast(
            nil,
            details: message,
            duration: 4,
            verticalOffset: 120,
            in: view
        )
    }

    private func notifyImportFinished(success: Bool) {
        delegate?.importTracksViewController?(self, didSaveTrack: success, gpxFile: gpxFile)
        delegate?.importTracksViewControllerDidFinishImport?(self, success: success)
        importCompletion?(success)
    }

    private func finishImportSuccessfully() {
        if let importURL {
            OAUtilities.denyAccess(toFile: importURL.path, removeFromInbox: true)
        }

        notifyImportFinished(success: true)

        dismiss(animated: true) {
            DispatchQueue.main.async {
                self.handlePostImportNavigation()
            }
            NotificationCenter.default.post(name: NSNotification.Name.OAGPXImportUIHelperDidFinishImport, object: nil)
        }
    }

    private func handlePostImportNavigation() {
        if successfulSaveCount <= 1 {
            openSavedTrackOnMap()
        } else {
            openMyPlacesTracksFolder()
        }
    }

    private func openSavedTrackOnMap() {
        guard let path = lastSavedPath ?? (gpxFile.path.isEmpty ? nil : gpxFile.path),
              let dataItem = OAGPXDatabase.sharedDb().getGPXItem(path) else { return }

        let trackItem = TrackItem(file: dataItem.file)
        trackItem.dataItem = dataItem
        OARootViewController.instance().navigationController?.popToRootViewController(animated: false)
        OARootViewController.instance().mapPanel.openTargetView(withGPX: trackItem)
    }
    
    private func openMyPlacesTracksFolder() {
        DeepLinkAppRouter(rootViewController: OARootViewController.instance()).openMyPlacesTracks(inFolder: selectedFolderPath)
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
            DispatchQueue.main.async {
                self?.reloadPreviewRow(for: item)
            }
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
        applyFolderSelection(named: selectedFolderName)
    }
    
    func onFolderAdded(_ addedFolderName: String) {
        createAndSelectFolder(named: addedFolderName)
    }
}

// MARK: - OAAddTrackFolderDelegate

extension ImportTracksViewController: OAAddTrackFolderDelegate {
    func onTrackFolderAdded(_ folderName: String) {
        createAndSelectFolder(named: folderName)
        dismiss(animated: true)
    }
}

// MARK: - SelectWaypointsDelegate

extension ImportTracksViewController: SelectWaypointsDelegate {
    func onPointsSelected(_ trackItem: ImportTrackItem, selectedPoints: [WptPt]) {
        trackItem.selectedPoints = selectedPoints
        generateData()
        tableView.reloadData()
    }
}

// MARK: - SaveImportedGpxListener

extension ImportTracksViewController: SaveImportedGpxListener {
    func gpxSavingStarted() {
        isSavingTracks = true
        updateProgress()
        updateNavbar()
        successfulSaveCount = 0
    }

    func gpxSaved(error: String?, savedPath: String?) {
        if let error {
            debugPrint("Save GPX error:", error)
            return
        }
        successfulSaveCount += 1
        lastSavedPath = savedPath
    }

    func gpxSavingFinished(warning: String?) {
        saveAsOneTrackTask = nil
        saveTracksTask = nil
        isSavingTracks = false
        updateProgress()
        updateNavbar()
        if let warning {
            showSaveError(warning)
        } else {
            finishImportSuccessfully()
        }
    }
}
