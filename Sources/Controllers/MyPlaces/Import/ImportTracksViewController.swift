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
    let selectedGpxFile: GpxFile
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
        self.selectedGpxFile = gpxFile
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

    private enum RowObjKey: String {
       case importTrackItem = "importTrackItem"
       case attributedTitleKey = "attributedTitle"
       case statisticsCells = "statisticsCells"
       case foldersValues = "values"
       case foldersSizes = "sizes"
       case foldersSelectedValue = "selectedValue"
       case foldersAddButtonTitle = "addButtonTitle"
    }

    weak var delegate: ImportTracksViewControllerDelegate?

    private let gpxFile: GpxFile
    private let fileName: String
    private var selectedFolderPath: String
    private let importURL: URL?
    private var importCompletion: ((Bool) -> Void)?

    private var trackItems: [ImportTrackItem] = []
    private var selectedTracks: Set<ImportTrackItem> = []
    private var isCollectingTracks = false
    private var isSavingTracks = false
    private var lastSavedPath: String?
    private var successfulSaveCount = 0
    private lazy var allPointsCount: Int = {
        gpxFile.getPointsList().count
    }()

    private var folderNames: [String] = []
    private var selectedFolderIndex = 0
    private let foldersScrollState = OACollectionViewCellState()
    private var foldersSizes: [NSNumber] = []

    private let trackPreviewManager = TrackPreviewManager()
    private var collectTracksTask: CollectTracksTask?
    private var saveAsOneTrackTask: SaveGpxAsyncTask?
    private var saveTracksTask: SaveTracksTask?

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
        self.selectedFolderPath = Self.resolveInitialFolderPath(from: selectedFolderPath)
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

        appendInfoSection()
        trackItems.forEach { appendTrackSection(for: $0) }
        appendFolderSection()
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)

        switch item.cellType {
        case OASimpleTableViewCell.reuseIdentifier:
            return configuredSimpleCell(for: item, at: indexPath)
        case OAValueTableViewCell.reuseIdentifier:
            return configuredValueCell(for: item, at: indexPath)
        case FolderCardsCell.reuseIdentifier:
            return configuredFolderCardsCell(for: item, at: indexPath)
        case TrackStatsTableCell.reuseIdentifier:
            return configuredStatsCell(for: item, at: indexPath)
        case OAImageDescTableViewCell.reuseIdentifier:
            return configuredPreviewCell(for: item, at: indexPath)
        default:
            return UITableViewCell()
        }
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        switch tableData.item(for: indexPath).key {
        case RowKey.importAsOne.rawValue:
            onImportAsOneTrackClicked()
        case RowKey.trackHeader.rawValue:
            onTrackItemSelected(at: indexPath)
        case RowKey.selectGroups.rawValue:
            onFoldersListSelected()
        case RowKey.trackWaypoints.rawValue:
            guard let trackItem = trackItem(from: indexPath) else { return }
            onTrackItemPointsSelected(track: trackItem)
        default:
            break
        }
    }

    override func hideFirstHeader() -> Bool { true }

    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        tableData.sectionData(for: UInt(section)).headerText.isEmpty ? 0 : UITableView.automaticDimension
    }

    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        tableData.sectionData(for: UInt(section)).footerText.isEmpty ? 16 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? FolderCardsCell)?.updateContentOffset()
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

    override func updateNavbar() {
        super.updateNavbar()
        (getLeftNavbarButton()?.customView as? UIButton)?.tintColor = .label
    }

    // MARK: - Bottom buttons

    override func getTopButtonTitle() -> String? {
        "\(localizedString("shared_string_import")) \(selectedTracks.count)/\(trackItems.count)"
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        selectedTracks.isEmpty ? .inactive : .purple
    }

    override func isBottomSeparatorVisible() -> Bool { false }

    override func onTopButtonPressed() {
        importSelectedTracksAction()
    }
}

// MARK: - Table Data

private extension ImportTracksViewController {
    func appendInfoSection() {
        let section = tableData.createNewSection()

        let descriptionRow = section.createNewRow()
        descriptionRow.cellType = OASimpleTableViewCell.reuseIdentifier
        descriptionRow.key = RowKey.infoDescr.rawValue
        descriptionRow.setObj(makeImportTracksDescription(tracksCount: trackItems.count), forKey: RowObjKey.attributedTitleKey.rawValue)

        let importAsOneRow = section.createNewRow()
        importAsOneRow.cellType = OASimpleTableViewCell.reuseIdentifier
        importAsOneRow.key = RowKey.importAsOne.rawValue
        importAsOneRow.title = localizedString("import_as_one_track")
    }

    func appendTrackSection(for item: ImportTrackItem) {
        let section = tableData.createNewSection()

        let headerRow = section.createNewRow()
        headerRow.cellType = OASimpleTableViewCell.reuseIdentifier
        headerRow.key = RowKey.trackHeader.rawValue
        headerRow.title = item.name
        let positionText = String(format: localizedString("ltr_or_rtl_combine_via_of"), item.index, trackItems.count)
        headerRow.descr = String(
            format: localizedString("ltr_or_rtl_combine_via_space"),
            localizedString("shared_string_gpx_track"),
            positionText
        )
        headerRow.setObj(item, forKey: RowObjKey.importTrackItem.rawValue)

        let previewRow = section.createNewRow()
        previewRow.cellType = OAImageDescTableViewCell.reuseIdentifier
        previewRow.key = RowKey.trackPreview.rawValue
        previewRow.setObj(item, forKey: RowObjKey.importTrackItem.rawValue)

        if !item.statisticsCells.isEmpty {
            let statsRow = section.createNewRow()
            statsRow.cellType = TrackStatsTableCell.reuseIdentifier
            statsRow.key = RowKey.trackStats.rawValue
            statsRow.setObj(item.statisticsCells, forKey: RowObjKey.statisticsCells.rawValue)
            statsRow.setObj(item, forKey: RowObjKey.importTrackItem.rawValue)
        }

        let waypointsRow = section.createNewRow()
        waypointsRow.cellType = OAValueTableViewCell.reuseIdentifier
        waypointsRow.key = RowKey.trackWaypoints.rawValue
        waypointsRow.title = localizedString("shared_string_waypoints")
        waypointsRow.icon = .icCustomFolder
        waypointsRow.iconTintColor = .iconColorActive
        waypointsRow.setObj(item, forKey: RowObjKey.importTrackItem.rawValue)
        waypointsRow.accessibilityLabel = waypointsRow.title
        waypointsRow.accessibilityValue = waypointsRow.descr
    }

    func appendFolderSection() {
        let section = tableData.createNewSection()
        section.headerText = localizedString("plan_route_folder")
        section.footerText = localizedString("import_tracks_folders_footer")

        let selectGroupsRow = section.createNewRow()
        selectGroupsRow.cellType = OAValueTableViewCell.reuseIdentifier
        selectGroupsRow.key = RowKey.selectGroups.rawValue
        selectGroupsRow.title = localizedString("select_group")
        selectGroupsRow.descr = folderNames[safe: selectedFolderIndex]

        let chipsRow = section.createNewRow()
        chipsRow.cellType = FolderCardsCell.reuseIdentifier
        chipsRow.key = RowKey.folderChips.rawValue
        chipsRow.setObj(folderNames, forKey: RowObjKey.foldersValues.rawValue)
        chipsRow.setObj(foldersSizes, forKey: RowObjKey.foldersSizes.rawValue)
        chipsRow.setObj(selectedFolderIndex, forKey: RowObjKey.foldersSelectedValue.rawValue)
        chipsRow.setObj(localizedString("shared_string_add"), forKey: RowObjKey.foldersAddButtonTitle.rawValue)
    }
}

// MARK: - Cell Configuration

private extension ImportTracksViewController {
    func configuredSimpleCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.setCustomLeftSeparatorInset(true)
        cell.textStackView.isHidden = false

        switch item.key {
        case RowKey.infoDescr.rawValue:
            let attributedString = item.obj(forKey: RowObjKey.attributedTitleKey.rawValue) as? NSAttributedString
            let plainText = attributedString?.string
            cell.descriptionLabel.attributedText = attributedString
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = plainText
            cell.accessibilityTraits = .staticText
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(true)
            cell.titleVisibility(false)
            hideSeparator(for: cell, false)
            cell.selectionStyle = .none
        case RowKey.importAsOne.rawValue:
            cell.configureAccessibility(withTitle: item.title, selected: false)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorActive
            cell.titleLabel.font = .preferredFont(forTextStyle: .body)
            cell.leftIconVisibility(false)
            cell.titleVisibility(true)
            cell.descriptionVisibility(false)
            hideSeparator(for: cell, true)
            cell.selectionStyle = .default
        case RowKey.trackHeader.rawValue:
            guard let trackItem = item.obj(forKey: RowObjKey.importTrackItem.rawValue) as? ImportTrackItem else { break }
            let label = [item.title, item.descr].compactMap { $0 }.joined(separator: ", ")
            let isSelected = selectedTracks.contains(trackItem)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorPrimary
            cell.titleLabel.font = .preferredFont(forTextStyle: .headline)
            cell.descriptionLabel.text = item.descr
            cell.configureAccessibility(withTitle: label, selected: isSelected)
            cell.leftIconView.isAccessibilityElement = false
            cell.leftIconView.image = isSelected ? .icCustomDone : .icCustomCheckboxUnselected
            cell.leftIconView.tintColor = isSelected ? .iconColorActive : .iconColorSecondary
            cell.leftIconVisibility(true)
            cell.titleVisibility(true)
            cell.descriptionVisibility(true)
            hideSeparator(for: cell, true)
            cell.selectionStyle = .default
        default:
            break
        }

        return cell
    }

    func configuredValueCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
        cell.titleLabel.text = item.title
        cell.valueLabel.text = item.descr
        cell.valueVisibility(true)
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(item.key == RowKey.trackWaypoints.rawValue)
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityLabel = item.accessibilityLabel
        cell.accessibilityValue = item.accessibilityValue
        cell.accessibilityTraits = .button
        cell.setCustomLeftSeparatorInset(true)
        hideSeparator(for: cell, true)

        if item.key == RowKey.trackWaypoints.rawValue, let trackItem = item.obj(forKey: RowObjKey.importTrackItem.rawValue) as? ImportTrackItem {
            cell.valueLabel.text = "\(trackItem.selectedPoints.count)/\(allPointsCount)"
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
        }
        return cell
    }

    func configuredFolderCardsCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderCardsCell.reuseIdentifier, for: indexPath) as! FolderCardsCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.cellIndex = indexPath
        cell.state = foldersScrollState
        cell.configureCell(.importTracks)
        cell.setValues(
            item.obj(forKey: RowObjKey.foldersValues.rawValue) as? [String] ?? [],
            sizes: item.obj(forKey: RowObjKey.foldersSizes.rawValue) as? [NSNumber],
            colors: nil,
            hidden: nil,
            addButtonTitle: item.string(forKey: RowObjKey.foldersAddButtonTitle.rawValue) ?? localizedString("shared_string_add"),
            withSelectedIndex: Int32(item.integer(forKey: RowObjKey.foldersSelectedValue.rawValue))
        )
        return cell
    }

    func configuredStatsCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TrackStatsTableCell.reuseIdentifier, for: indexPath) as! TrackStatsTableCell
        cell.selectionStyle = .none
        cell.backgroundColor = .groupBg
        cell.isAccessibilityElement = false
        cell.accessibilityElementsHidden = true
        if let statisticsCells = item.obj(forKey: RowObjKey.statisticsCells.rawValue) as? [OAGPXTableCellData] {
            cell.configure(statistics: statisticsCells)
        }
        hideSeparator(for: cell, false)
        return cell
    }

    func configuredPreviewCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
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
        cell.isAccessibilityElement = false
        cell.accessibilityElementsHidden = true
        hideSeparator(for: cell, true)

        guard let trackItem = item.obj(forKey: RowObjKey.importTrackItem.rawValue) as? ImportTrackItem else {
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
        return cell
    }
}

// MARK: - Setup & State

private extension ImportTracksViewController {
    static func resolveInitialFolderPath(from selectedFolderPath: String?) -> String {
        guard let selectedFolderPath, !selectedFolderPath.isEmpty else {
            let gpxPath = OsmAndApp.swiftInstance()?.gpxPath as String? ?? ""
            return gpxPath.appending("/import")
        }

        if selectedFolderPath.lowercased().hasSuffix(".gpx") {
            return (selectedFolderPath as NSString).deletingLastPathComponent
        }
        return selectedFolderPath
    }

    func setupProgressView() {
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

    func updateProgress() {
        let progressVisible = isCollectingTracks || isSavingTracks
        progressLabel.text = isCollectingTracks
            ? localizedString("reading_file") + localizedString("shared_string_ellipsis")
            : String(format: localizedString("importing_from"), fileName)

        if progressVisible {
            progressIndicator.startAnimating()
        } else {
            progressIndicator.stopAnimating()
        }
        progressStackView.isHidden = !progressVisible
        tableView.isHidden = progressVisible
        topButton.isHidden = progressVisible
        separatorBottomView.isHidden = progressVisible
        
        progressStackView.isAccessibilityElement = true
        progressStackView.accessibilityLabel = progressLabel.text
        progressIndicator.isAccessibilityElement = false
        if progressVisible {
            UIAccessibility.post(notification: .announcement, argument: progressLabel.text)
        }
    }

    func collectTracks() {
        collectTracksTask = CollectTracksTask(gpxFile: gpxFile, fileName: fileName, listener: self)
        collectTracksTask?.execute()
    }

    func updateButtonsState() {
        topButton.isEnabled = !selectedTracks.isEmpty
        updateBottomButtons()
        updateSelectAllButtonTitle()
    }

    func updateSelectAllButtonTitle() {
        let allSelected = !trackItems.isEmpty && selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let item = navigationItem.rightBarButtonItems?.first else { return }
        item.title = title
        item.accessibilityLabel = title
    }

    func trackItem(from indexPath: IndexPath) -> ImportTrackItem? {
        tableData.item(for: indexPath).obj(forKey: RowObjKey.importTrackItem.rawValue) as? ImportTrackItem
    }

    func hideSeparator(for cell: UITableViewCell, _ isHidden: Bool) {
        let inset = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        cell.separatorInset = UIEdgeInsets(
            top: 0,
            left: isHidden ? inset : 16,
            bottom: 0,
            right: isHidden ? -inset : 16
        )
    }

    func makeImportTracksDescription(tracksCount: Int) -> NSAttributedString {
        let text = tracksCount == 1
            ? String(format: localizedString("import_tracks_descr_one"), fileName)
            : String(format: localizedString("import_tracks_descr_other"), fileName, tracksCount)

        let result = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.textColorPrimary
            ]
        )

        let fileRange = (text as NSString).range(of: fileName)
        if fileRange.location != NSNotFound {
            result.addAttribute(.foregroundColor, value: UIColor.textColorActive, range: fileRange)
        }
        return result
    }

    func reloadPreviewRow(for item: ImportTrackItem) {
        for section in 0..<tableData.sectionCount() {
            for row in 0..<tableData.rowCount(section) {
                let indexPath = IndexPath(row: Int(row), section: Int(section))
                let rowItem = tableData.item(for: indexPath)
                guard rowItem.key == RowKey.trackPreview.rawValue,
                      let trackItem = rowItem.obj(forKey: RowObjKey.importTrackItem.rawValue) as? ImportTrackItem,
                      trackItem.index == item.index else { continue }
                tableView.reloadRows(at: [indexPath], with: .none)
                return
            }
        }
    }
}

// MARK: - Folders

private extension ImportTracksViewController {
    func reloadFolderNames() {
        folderNames = OAUtilities.getGpxFoldersListSorted(true, shouldAddRootTracksFolder: true)
        selectedFolderIndex = folderIndex(for: selectedFolderPath)
    }

    func folderIndex(for path: String) -> Int {
        folderNames.firstIndex(of: folderDisplayName(for: path)) ?? 0
    }

    func folderDisplayName(for path: String) -> String {
        let gpxPath = OsmAndApp.swiftInstance().gpxPath ?? ""
        if path.isEmpty || path == gpxPath {
            return localizedString("shared_string_gpx_tracks")
        }
        return (path as NSString).lastPathComponent
    }

    func folderPath(forDisplayName name: String) -> String {
        let gpxPath = OsmAndApp.swiftInstance().gpxPath ?? ""
        if name == localizedString("shared_string_gpx_tracks") {
            return gpxPath
        }
        return gpxPath.appendingPathComponent(name)
    }

    func folderTrackCounts() -> [NSNumber] {
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

    func indexPathForFoldersRow() -> IndexPath? {
        for section in 0..<tableData.sectionCount() {
            for row in 0..<tableData.rowCount(section) {
                let indexPath = IndexPath(row: Int(row), section: Int(section))
                guard tableData.item(for: indexPath).key == RowKey.folderChips.rawValue else { continue }
                return indexPath
            }
        }
        return nil
    }

    func applyFolderSelection(named name: String) {
        selectedFolderPath = folderPath(forDisplayName: name)
        selectedFolderIndex = folderIndex(for: selectedFolderPath)
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

    func createAndSelectFolder(named name: String) {
        let path = folderPath(forDisplayName: name)
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                foldersSizes.insert(NSNumber(0), at: 0)
                folderNames.insert(name, at: 0)
            } catch {
                debugPrint(error)
                return
            }
        }
        applyFolderSelection(named: name)
    }

    func suggestedFolderNameFromFile() -> String {
        (fileName as NSString).deletingPathExtension
    }
}

// MARK: - Actions

private extension ImportTracksViewController {
    @objc func onSelectAllAction() {
        selectedTracks = selectedTracks.count == trackItems.count ? [] : Set(trackItems)
        updateButtonsState()
        tableView.reloadData()
    }

    func importSelectedTracksAction() {
        guard !isCollectingTracks, !isSavingTracks, !selectedTracks.isEmpty else { return }
        let items = selectedTracks.sorted { $0.index < $1.index }
        saveTracksTask = SaveTracksTask(items: items, destinationDir: selectedFolderPath, listener: self)
        saveTracksTask?.execute()
    }

    func onImportAsOneTrackClicked() {
        guard !isCollectingTracks, !isSavingTracks else { return }

        let plannedPath = SaveGpxAsyncTask.plannedDestinationPath(destinationDir: selectedFolderPath, fileName: fileName)
        if FileManager.default.fileExists(atPath: plannedPath) {
            showFileExistsAlert { [weak self] overwrite in
                self?.startSaveAsOneTrack(overwrite: overwrite)
            }
        } else {
            startSaveAsOneTrack(overwrite: false)
        }
    }

    func startSaveAsOneTrack(overwrite: Bool) {
        saveAsOneTrackTask = SaveGpxAsyncTask(
            gpxFile: gpxFile,
            destinationDir: selectedFolderPath,
            fileName: fileName,
            overwrite: overwrite,
            importURL: importURL,
            listener: self
        )
        saveAsOneTrackTask?.execute()
    }
    
    func onTrackItemSelected(at indexPath: IndexPath) {
        guard let trackItem = trackItem(from: indexPath) else { return }
        if selectedTracks.contains(trackItem) {
            selectedTracks.remove(trackItem)
        } else {
            selectedTracks.insert(trackItem)
        }
        updateButtonsState()
        tableView.reloadData()
    }

    @objc func showExitConfirmationAction() {
        guard !isSavingTracks else { return }

        let alert = UIAlertController(
            title: localizedString("import_tracks_cancel_title"),
            message: localizedString("import_tracks_cancel_descr"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localizedString("shared_string_continue"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_close"), style: .destructive) { [weak self] _ in
            self?.collectTracksTask?.cancelled = true
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    func showFileExistsAlert(onChoice: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: localizedString("import_tracks"),
            message: localizedString("gpx_import_already_exists"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localizedString("gpx_overwrite"), style: .destructive) { _ in onChoice(true) })
        alert.addAction(UIAlertAction(title: localizedString("gpx_add_new"), style: .default) { _ in onChoice(false) })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func onFoldersListSelected() {
        guard let vc = OASelectTrackFolderViewController(selectedFolderName: folderDisplayName(for: selectedFolderPath)) else {
            return
        }
        vc.delegate = self
        vc.suggestedFolderName = suggestedFolderNameFromFile()
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func onAddFolderSelected() {
        let vc = OAAddTrackFolderViewController()
        vc.delegate = self
        vc.suggestedFolderName = suggestedFolderNameFromFile()
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func onTrackItemPointsSelected(track: ImportTrackItem) {
        let vc = SelectPointsViewController(track: track, allPoints: gpxFile.getPointsList())
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - Post Import

private extension ImportTracksViewController {
    func showSaveError(_ message: String) {
        OAUtilities.showToast(nil, details: message, duration: 4, verticalOffset: 120, in: view)
    }

    func notifyImportFinished(success: Bool) {
        delegate?.importTracksViewController?(self, didSaveTrack: success, gpxFile: gpxFile)
        delegate?.importTracksViewControllerDidFinishImport?(self, success: success)
        importCompletion?(success)
    }

    func finishImportSuccessfully() {
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

    func handlePostImportNavigation() {
        if successfulSaveCount <= 1 {
            openSavedTrackOnMap()
        } else {
            openMyPlacesTracksFolder()
        }
    }

    func openSavedTrackOnMap() {
        guard let path = lastSavedPath ?? (gpxFile.path.isEmpty ? nil : gpxFile.path),
              let dataItem = OAGPXDatabase.sharedDb().getGPXItem(path) else { return }

        let trackItem = TrackItem(file: dataItem.file)
        trackItem.dataItem = dataItem
        OARootViewController.instance().navigationController?.popToRootViewController(animated: false)
        OARootViewController.instance().mapPanel.openTargetView(withGPX: trackItem)
    }

    func openMyPlacesTracksFolder() {
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

        DispatchQueue.global(qos: .userInitiated).async {
            self.foldersSizes = self.folderTrackCounts()
            
            for item in self.trackItems {
                guard let analysis = item.analysis else { continue }
                item.statisticsCells = OATrackMenuHeaderView.generateGpxBlockStatistics(analysis, withoutGaps: false) as? [OAGPXTableCellData] ?? []
            }
            
            DispatchQueue.main.async {
                self.postCollectTracks()
            }
        }
    }
    
    private func postCollectTracks() {
        updateProgress()
        updateNavbar()
        updateButtonsState()
        generateData()
        tableView.reloadData()

        let params = MapDrawParams.importTrackPreviewParams(size: CGSize(width: tableView.bounds.width - 64, height: 96))
        trackPreviewManager.startPreviews(for: trackItems, params: params) { [weak self] item in
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
        onAddFolderSelected()
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

// MARK: - SelectPointsDelegate

extension ImportTracksViewController: SelectPointsDelegate {
    func onPointsSelected(_ trackItem: ImportTrackItem, selectedPoints: [WptPt]) {
        trackItem.selectedPoints = selectedPoints
        tableView.reloadData()
    }
}

// MARK: - SaveImportedGpxListener

extension ImportTracksViewController: SaveImportedGpxListener {
    func onGpxSavingStarted() {
        isSavingTracks = true
        updateProgress()
        updateNavbar()
        successfulSaveCount = 0
    }

    func onGpxSaved(error: String?, savedPath: String?) {
        if let error {
            debugPrint("Save GPX error:", error)
            return
        }
        successfulSaveCount += 1
        lastSavedPath = savedPath
    }

    func onGpxSavingFinished(warning: [String]) {
        saveAsOneTrackTask = nil
        saveTracksTask = nil
        isSavingTracks = false
        updateProgress()
        updateNavbar()

        if warning.isEmpty {
            finishImportSuccessfully()
        } else {
            showSaveError(warning.joined(separator: "\n"))
        }
    }
}
