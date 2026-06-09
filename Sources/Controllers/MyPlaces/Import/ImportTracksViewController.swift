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
    let gpxFile: GpxFile          // один track из исходного файла
    var selectedPoints: [WptPt] = []
    var suggestedPoints: [WptPt] = []

    // preview — позже
    // var previewImage: UIImage?
    
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

private enum ImportTracksRowKey: String {
    case infoDescr
    case importAsOne
    case track
    case selectGroups
    case folderChips
}

private enum ImportTracksRowObjKey {
    static let importTrackItem = "importTrackItem"
    static let isSelected = "isSelected"
    static let tracksCount = "tracksCount"
    static let chipsValues = "values"
    static let chipsSelectedIndex = "selectedValue"
}

@objc protocol ImportTracksViewControllerDelegate: AnyObject {
    @objc optional func importTracksViewControllerDidFinishImport(_ controller: ImportTracksViewController, success: Bool)
    @objc optional func importTracksViewController(_ controller: ImportTracksViewController, didSaveTrack success: Bool, gpxFile: GpxFile)
}

final class ImportTracksViewController: OABaseButtonsViewController {
    weak var delegate: ImportTracksViewControllerDelegate?
    
    private let gpxFile: GpxFile
    private let fileName: String
    private var selectedFolderPath: String
    private let importURL: URL?
    private let openGpxView: Bool
    private var importCompletion: ((Bool) -> Void)?
    
    private var trackItems: [ImportTrackItem] = []
    private var selectedTracks: Set<ImportTrackItem> = []
    private var isCollectingTracks = false
    private var isSavingTracks = false
    private var collectTracksTask: CollectTracksTask?
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressView()
        collectTracks()
    }
    
    // MARK: - Table
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OARightIconTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OAFoldersCell.reuseIdentifier)
        // когда будет готова:
        // addCell(ImportTrackTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()

        guard !trackItems.isEmpty else { return }

        // Section 0 — Info
        let infoSection = tableData.createNewSection()

        let descrRow = infoSection.createNewRow()
        descrRow.cellType = OASimpleTableViewCell.reuseIdentifier
        descrRow.key = ImportTracksRowKey.infoDescr.rawValue
        descrRow.title = getAttributedDescription()

        let importAsOneRow = infoSection.createNewRow()
        importAsOneRow.cellType = OARightIconTableViewCell.reuseIdentifier
        importAsOneRow.key = ImportTracksRowKey.importAsOne.rawValue
        importAsOneRow.title = localizedString("import_tracks_as_one_track")

        // Section 1 — Tracks
        for item in trackItems {
            let section = tableData.createNewSection()
            let row = section.createNewRow()
            row.cellType = OARightIconTableViewCell.reuseIdentifier // v1; потом ImportTrackTableViewCell
            row.key = ImportTracksRowKey.track.rawValue
            row.title = item.name
            row.descr = String(
                format: localizedString("ltr_or_rtl_combine_via_dash"),
                localizedString("shared_string_gpx_track"),
                "\(item.index + 1)/\(trackItems.count)"
            )
            row.setObj(item, forKey: ImportTracksRowObjKey.importTrackItem)
            row.setObj(selectedTracks.contains(item), forKey: ImportTracksRowObjKey.isSelected)
            row.setObj(trackItems.count, forKey: ImportTracksRowObjKey.tracksCount)
        }

        // Section 2 — Folder
        let folderSection = tableData.createNewSection()
        folderSection.headerText = localizedString("plan_route_folder")
        folderSection.footerText = localizedString("select_folder_descr")

        let selectGroupsRow = folderSection.createNewRow()
        selectGroupsRow.cellType = OAValueTableViewCell.reuseIdentifier
        selectGroupsRow.key = ImportTracksRowKey.selectGroups.rawValue
        selectGroupsRow.title = localizedString("select_group")
        selectGroupsRow.descr = folderDisplayName(for: selectedFolderPath)

        let chipsRow = folderSection.createNewRow()
        chipsRow.cellType = OAFoldersCell.reuseIdentifier
        chipsRow.key = ImportTracksRowKey.folderChips.rawValue
        chipsRow.setObj(getFoldersChipsValues(), forKey: ImportTracksRowObjKey.chipsValues)
        chipsRow.setObj(selectedFolderIndex + 1, forKey: ImportTracksRowObjKey.chipsSelectedIndex) // +1 из‑за Add chip
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)

        switch item.cellType {
        case OASimpleTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                for: indexPath
            ) as! OASimpleTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorSecondary
            cell.titleLabel.numberOfLines = 0
            return cell

        case OARightIconTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OARightIconTableViewCell.reuseIdentifier,
                for: indexPath
            ) as! OARightIconTableViewCell

            if item.key == ImportTracksRowKey.importAsOne.rawValue {
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = nil
                cell.descriptionVisibility(false)
                cell.titleLabel.textColor = .iconColorActive
                cell.accessoryType = .none
            } else if item.key == ImportTracksRowKey.track.rawValue {
                let selected = item.bool(forKey: ImportTracksRowObjKey.isSelected)
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                cell.descriptionVisibility(true)
                cell.titleLabel.textColor = .textColorPrimary
                cell.leftIconView.image = UIImage.templateImageNamed(
                    selected ? "ic_action_done" : "ic_action_unchecked"
                )
                cell.leftIconView.tintColor = selected ? .iconColorActive : .iconColorSecondary
                cell.accessoryType = .disclosureIndicator
            }
            return cell

        case OAValueTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OAValueTableViewCell.reuseIdentifier,
                for: indexPath
            ) as! OAValueTableViewCell
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            cell.valueVisibility(true)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.accessoryType = .disclosureIndicator
            return cell

        case OAFoldersCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OAFoldersCell.reuseIdentifier,
                for: indexPath
            ) as! OAFoldersCell
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.rightActionButtonVisibility(false)
            cell.collectionView.foldersDelegate = self
            cell.collectionView.cellIndex = indexPath
            cell.collectionView.state = foldersScrollState
            if let values = item.obj(forKey: ImportTracksRowObjKey.chipsValues) as? [[String: String]],
               let index = item.obj(forKey: ImportTracksRowObjKey.chipsSelectedIndex) as? Int {
                cell.collectionView.setValues(values, withSelectedIndex: index)
            }
            cell.collectionView.reloadData()
            return cell

        default:
            return UITableViewCell()
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        switch item.key {
        case ImportTracksRowKey.importAsOne.rawValue:
            importAsOneTrack() // SaveGpxAsyncTask — позже
        case ImportTracksRowKey.track.rawValue:
            guard let trackItem = item.obj(forKey: ImportTracksRowObjKey.importTrackItem) as? ImportTrackItem else { return }
            if selectedTracks.contains(trackItem) {
                selectedTracks.remove(trackItem)
            } else {
                selectedTracks.insert(trackItem)
            }
            updateButtonsState()
            generateData()
            tableView.reloadData()
        case ImportTracksRowKey.selectGroups.rawValue:
            showSelectFolderScreen()
        default:
            break
        }
    }
    
//    override func getCustomHeight(forRow indexPath: IndexPath) -> CGFloat {
//        let item = tableData.item(for: indexPath)
//        if item.cellType == OAFoldersCell.reuseIdentifier {
//            return 52
//        }
//        return UITableView.automaticDimension
//    }
    
    // MARK: - NavBar
    
    override func getTitle() -> String? {
        localizedString("import_tracks")
    }
    
    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        .templateImageNamed("ic_navbar_close")?.withTintColor(.label)
    }
    
    override func onLeftNavbarButtonPressed() {
        showExitConfirmation()
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]? {
        guard !trackItems.isEmpty, !isCollectingTracks, !isSavingTracks else {
            return nil
        }
        let allSelected = selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let button = OABaseNavbarViewController.createRightNavbarButton(title, icon: nil, color: .label,
                                                                              action: #selector(onSelectAllNavbarButtonPressed),
                                                                              target: self, menu: nil) else {
            return []
        }
        button.accessibilityLabel = title
        return [button]
    }
    
    override func updateNavbar() {
        super.updateNavbar()
        getLeftNavbarButton().tintColor = .label
    }
    
    // MARK: - Bottom buttons
    
    override func getTopButtonTitle() -> String? {
        let selected = selectedTracks.count
        let total = trackItems.count
        return "\(localizedString("shared_string_import")) \(selected)/\(total)"
    }

    override func isBottomSeparatorVisible() -> Bool {
        false
    }
    
    override func onTopButtonPressed() {
        importSelectedTracks()
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
        setupNavbarButtons()
    }
    
    private func collectTracks() {
        collectTracksTask = CollectTracksTask(
            gpxFile: gpxFile,
            fileName: fileName,
            listener: self
        )
        collectTracksTask?.execute()
    }

    // MARK: - Actions
    
    @objc private func onSelectAllNavbarButtonPressed() {
        if selectedTracks.count == trackItems.count {
            selectedTracks.removeAll()
        } else {
            selectedTracks = Set(trackItems)
        }
        updateButtonsState()
        tableView.reloadData()
    }
    
    private func importSelectedTracks() {
        // SaveTracksTask
    }
    
    private func importAsOneTrack() {
        
    }
    
    @objc
    private func showExitConfirmation() {
        let alert = UIAlertController(
            title: localizedString("import_tracks_cancel_title"),
            message: localizedString("import_tracks_cancel_descr"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: localizedString("shared_string_continue"),
            style: .default
        ))
        alert.addAction(UIAlertAction(
            title: localizedString("shared_string_close"),
            style: .destructive
        ) { [weak self] _ in
            self?.collectTracksTask?.cancelled = true
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func updateButtonsState() {
        topButton.isEnabled = !selectedTracks.isEmpty
        updateBottomButtons()
    }
    
    private func showSelectFolderScreen() {
//        let vc = OASelectTrackFolderViewController(selectedFolderName: folderDisplayName(for: selectedFolderPath))
//        vc.delegate = self
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAddFolderScreen() {
//        let vc = OAAddTrackFolderViewController()
//        vc.delegate = self
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Helpers methods
    
    private func getAttributedDescription() -> String {
        let tracksCount = selectedTracks.count
        let desc = tracksCount == 1 ? String(format: localizedString("import_tracks_descr_one"), fileName) :
                                                String(format: localizedString("import_tracks_descr_other"), fileName, tracksCount)
        
        return desc
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

    private func getFoldersChipsValues() -> [[String: String]] {
        var values: [[String: String]] = [[
            "title": localizedString("add_folder"),
            "img": "ic_action_plus"
        ]]
        for name in folderNames {
            values.append(["title": name, "img": "ic_custom_folder"])
        }
        return values
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
        updateProgress()
        updateButtonsState()
        generateData()
        tableView.reloadData()
    }
}

// MARK: - OAFoldersCellDelegate

extension ImportTracksViewController: OAFoldersCellDelegate {
    func onItemSelected(_ index: Int) {
        if index == 0 {
            showAddFolderScreen()
            return
        }
        let folderIndex = index - 1
        guard folderNames.indices.contains(folderIndex) else { return }
        selectedFolderIndex = folderIndex
        selectedFolderPath = folderPath(forDisplayName: folderNames[folderIndex])
        generateData()
        tableView.reloadData()
    }
}
