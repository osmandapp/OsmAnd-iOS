//
//  MapSettingsGpxViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import OsmAndShared

@objc(OAMapSettingsGpxViewControllerDelegate)
protocol MapSettingsGpxViewControllerDelegate: AnyObject {
    func onVisibleTracksUpdate()
}

@objc(OAMapSettingsGpxViewController)
@objcMembers
final class MapSettingsGpxViewController: OABaseNavbarSubviewViewController {
    private let previouslyVisibleTracksKey = "PreviouslyVisibleGpxFilePaths"
    private var searchController: UISearchController?
    private var segmentedControl: UISegmentedControl?
    private var lastUpdate: TimeInterval?
    private var currentSortType: TracksSortMode = .lastModified
    private var sortTypeForAllTracks: TracksSortMode = .lastModified
    private var sortTypeForVisibleTracks: TracksSortMode = .lastModified
    private var sortTypeForSearch: TracksSortMode = .nameAZ
    private var allGpxList: [GpxDataItem] = []
    private var visibleGpxList: [GpxDataItem] = []
    private var recentlyVisibleGpxList: [GpxDataItem] = []
    private var filteredGpxList: [GpxDataItem] = []
    private var selectedGpxTracks: [GpxDataItem] = []
    private var selectedTrack: GpxDataItem?
    private var previousSelectedSegmentIndex: Int = 0
    private var isShowingVisibleTracks = true
    private var isSearchActive = false
    private var isSearchFilteringActive = false
    private var isTracksAvailable = false
    private var isVisibleTracksAvailable = false
    private var importHelper: OAGPXImportUIHelper?
    private var rootVC: OARootViewController?
    private var routingHelper: OARoutingHelper?
    private var gpxHelper: OAGPXUIHelper?
    private var gpxDB: OAGPXDatabase?
    private var app: OsmAndAppProtocol?
    private var settings: OAAppSettings?
    private let lock = NSLock()
    weak var delegate: MapSettingsGpxViewControllerDelegate?

    private lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 16
        config.imagePlacement = .leading
        config.baseForegroundColor = .iconColorActive
        let button = UIButton(configuration: config, primaryAction: nil)
        button.setImage(UIImage(resource: .icCustomLastModified), for: .normal)
        button.menu = createSortMenu()
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.contentHorizontalAlignment = .left
        return button
    }()

    override func commonInit() {
        settings = OAAppSettings.sharedManager()
        importHelper = OAGPXImportUIHelper(hostViewController: self)
        rootVC = OARootViewController.instance()
        routingHelper = OARoutingHelper.sharedInstance()
        gpxHelper = OAGPXUIHelper()
        gpxDB = OAGPXDatabase.sharedDb()
        app = OsmAndApp.swiftInstance()
        loadGpxTracks()
        loadVisibleTracks()
        loadRecentlyVisibleTracks()
    }
    
    override func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        addNotification(NSNotification.Name.OAGPXImportUIHelperDidFinishImport, selector: #selector(didFinishImport))
    }
    
    override func registerObservers() {
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let updateDistanceAndDirectionSelector = #selector(updateDistanceAndDirection as () -> Void)
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateLocationObserver))
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateHeadingObserver))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.setEditing(true, animated: false)
        tableView.allowsMultipleSelectionDuringEditing = true
        searchController = UISearchController(searchResultsController: nil)
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = localizedString("shared_string_search")
        definesPresentationContext = true
        tableView.tableHeaderView = setupHeaderView()
        updateSelectedRows()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let searchController, searchController.isActive {
            searchController.isActive = false
            navigationItem.searchController = nil
            isSearchActive = false
            isSearchFilteringActive = false
            updateNavbar()
            guard let segmentedControl else { return }
            segmentedControl.selectedSegmentIndex = previousSelectedSegmentIndex
            segmentChanged(segmentedControl)
        }
    }
    
    override func getTitle() -> String? {
        localizedString("shared_string_gpx_tracks")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]? {
        guard let searchButton = createRightNavbarButton(nil, iconName: "ic_navbar_search", action: #selector(onSearchButtonClicked), menu: nil),
              let importButton = createRightNavbarButton(nil, iconName: "ic_custom_import_outlined", action: #selector(onImportButtonClicked), menu: nil) else { return nil }
        
        searchButton.accessibilityLabel = localizedString("shared_string_search")
        importButton.accessibilityLabel = localizedString("import_tracks")
        return [importButton, searchButton]
    }
    
    override func createSubview() -> UIView? {
        segmentedControl = UISegmentedControl(items: [localizedString("shared_string_visible"), localizedString("shared_string_all")])
        if !isSearchActive {
            segmentedControl?.selectedSegmentIndex = 0
            isShowingVisibleTracks = true
            segmentedControl?.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
            return segmentedControl
        } else {
            return nil
        }
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func useCustomTableViewHeader() -> Bool {
        true
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }
    
    override func getTopButtonTitle() -> String? {
        if !isTracksAvailable || (isShowingVisibleTracks && !isVisibleTracksAvailable && recentlyVisibleGpxList.isEmpty) {
            return localizedString("shared_string_select_all")
        }
        
        return localizedString(areAllTracksSelected() ? "shared_string_deselect_all" : "shared_string_select_all")
    }
    
    override func getBottomButtonTitle() -> String? {
        localizedString("shared_string_done")
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        shouldUseInactiveColorScheme() ? .inactive : .graySimple
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OALargeImageTitleDescrTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()
        if isTracksAvailable {
            let tracksSection = tableData.createNewSection()
            if isShowingVisibleTracks && !isVisibleTracksAvailable && !isSearchActive {
                let noVisibleTracksRow = tracksSection.createNewRow()
                noVisibleTracksRow.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
                noVisibleTracksRow.key = "noVisibleTracks"
                noVisibleTracksRow.title = localizedString("no_tracks_on_map")
                noVisibleTracksRow.descr = localizedString("select_tracks_to_display")
                noVisibleTracksRow.iconName = "ic_custom_trip_hide"
                noVisibleTracksRow.iconTintColor = UIColor.iconColorDefault
                noVisibleTracksRow.setObj(localizedString("show_all_tracks"), forKey: "buttonTitle")
            } else {
                let visibleGpxFilePaths = settings?.mapSettingVisibleGpx.get() ?? []
                let gpxListToShow = isSearchActive ? filteredGpxList : (isShowingVisibleTracks ? visibleGpxList : allGpxList)
                for gpx in gpxListToShow {
                    let gpxRow = tracksSection.createNewRow()
                    gpxRow.cellType = OASimpleTableViewCell.getIdentifier()
                    gpxRow.title = gpx.gpxFileNameWithoutExtension
                    gpxRow.setObj(gpx, forKey: "gpx")
                    gpxRow.iconName = "ic_custom_trip"
                    gpxRow.iconTintColor = visibleGpxFilePaths.contains(gpx.gpxFilePath) ? .iconColorActive : .iconColorDisabled
                }
            }
            if isShowingVisibleTracks && !recentlyVisibleGpxList.isEmpty && !isSearchActive {
                let recentlyVisibleSection = tableData.createNewSection()
                recentlyVisibleSection.headerText = String(format: localizedString("recently_visible"), "(\(recentlyVisibleGpxList.count))")
                for gpx in recentlyVisibleGpxList {
                    let gpxRow = recentlyVisibleSection.createNewRow()
                    gpxRow.cellType = OASimpleTableViewCell.getIdentifier()
                    gpxRow.title = gpx.gpxFileNameWithoutExtension
                    gpxRow.setObj(gpx, forKey: "gpx")
                    gpxRow.iconName = "ic_custom_trip"
                    gpxRow.iconTintColor = .iconColorDisabled
                }
            }
        } else {
            let noTracksSection = tableData.createNewSection()
            let noTracksRow = noTracksSection.createNewRow()
            noTracksRow.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            noTracksRow.key = "noTracks"
            noTracksRow.title = localizedString("no_track_files")
            noTracksRow.descr = localizedString("import_create_track_files")
            noTracksRow.iconName = "ic_custom_folder_open"
            noTracksRow.iconTintColor = .iconColorDefault
            noTracksRow.setObj(localizedString("shared_string_import"), forKey: "buttonTitle")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier(), for: indexPath) as! OASimpleTableViewCell
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = UIColor.groupBg
            cell.titleLabel.text = item.title
            if let gpx = item.obj(forKey: "gpx") as? GpxDataItem {
                cell.descriptionLabel.attributedText = TracksSortModeHelper.getTrackDescription(track: gpx, sortMode: currentSortType, includeFolderInfo: true)
            }
            
            let iconName = item.iconName ?? "ic_custom_trip"
            let iconImage = UIImage(named: iconName) ?? UIImage()
            cell.leftIconView.image = iconImage.withRenderingMode(.alwaysTemplate)
            cell.leftIconView.tintColor = item.iconTintColor
            return cell
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier(), for: indexPath) as! OALargeImageTitleDescrTableViewCell
            cell.selectionStyle = .none
            cell.titleLabel?.text = item.title
            cell.titleLabel?.accessibilityLabel = item.title
            cell.descriptionLabel?.text = item.descr
            cell.descriptionLabel?.accessibilityLabel = item.descr
            cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
            cell.cellImageView?.contentMode = .scaleAspectFill
            cell.cellImageView?.clipsToBounds = true
            cell.cellImageView?.tintColor = item.iconTintColor
            cell.button?.setTitle(item.obj(forKey: "buttonTitle") as? String, for: .normal)
            cell.button?.accessibilityLabel = item.obj(forKey: "buttonTitle") as? String
            cell.button?.removeTarget(nil, action: nil, for: .allEvents)
            cell.button?.tag = indexPath.section << 10 | indexPath.row
            cell.button?.addTarget(self, action: #selector(onCellButtonClicked(sender:)), for: .touchUpInside)
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath, let gpx = getGpxForSelectedRow(at: indexPath) else { return }
        if !selectedGpxTracks.contains(where: { $0.gpxFilePath == gpx.gpxFilePath }) {
            selectedGpxTracks.append(gpx)
        }
        
        updateBottomButtons()
    }
    
    override func onRowDeselected(_ indexPath: IndexPath?) {
        guard let indexPath, let gpx = getGpxForSelectedRow(at: indexPath) else { return }
        if let index = selectedGpxTracks.firstIndex(where: { $0.gpxFilePath == gpx.gpxFilePath }) {
            selectedGpxTracks.remove(at: index)
        }
        
        updateBottomButtons()
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = tableData.item(for: indexPath)
        return !(item.key == "noVisibleTracks" || item.key == "noTracks")
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        let gpx = item.obj(forKey: "gpx") as! GpxDataItem
        let trackItem = TrackItem(file: gpx.file)
        trackItem.dataItem = gpx
        
        let menuProvider: UIContextMenuActionProvider = { _ in
            let openAction = UIAction(title: localizedString("shared_string_open"), image: UIImage.icCustomOverview) { [weak self] _ in
                self?.onTrackOpenClicked(track: trackItem)
            }
            let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { [weak self] _ in
                self?.onTrackAppearenceClicked(track: trackItem)
            }
            let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: UIImage.icCustomNavigationOutlined) { [weak self] _ in
                self?.onTrackNavigationClicked(track: trackItem)
            }
            let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [openAction, appearenceAction, navigationAction])
            
            let analyzeAction = UIAction(title: localizedString("gpx_analyze"), image: UIImage.icCustomGraph) { [weak self] _ in
                self?.onTrackAnalyzeClicked(track: trackItem)
            }
            let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [analyzeAction])
            
            let shareAction = UIAction(title: localizedString("shared_string_share"), image: UIImage.icCustomExportOutlined) { [weak self] _ in
                guard let self else { return }
                let cellScreenArea = self.view.convert(self.tableView.rectForRow(at: indexPath), from: self.tableView)
                self.onTrackShareClicked(track: trackItem, touchPointArea: cellScreenArea)
            }
            let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm_short"), image: UIImage.icCustomUploadToOpenstreetmapOutlined) { [weak self] _ in
                self?.onTrackUploadToOsmClicked(track: trackItem)
            }
            let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [shareAction, uploadToOsmAction])
            
            let editAction = UIAction(title: localizedString("shared_string_edit"), image: UIImage.icCustomTrackEdit) { [weak self] _ in
                self?.onTrackEditClicked(track: trackItem)
            }
            let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: UIImage.icCustomCopy) { [weak self] _ in
                self?.onTrackDuplicateClicked(track: trackItem)
            }
            let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { [weak self] _ in
                self?.onTrackRenameClicked(track: trackItem)
            }
            let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined) { [weak self] _ in
                self?.onTrackMoveClicked(track: trackItem)
            }
            let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction, duplicateAction, renameAction, moveAction])
            
            let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                self?.onTrackDeleteClicked(track: trackItem)
            }
            let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
            return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection])
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
    }
    
    override func onLeftNavbarButtonPressed() {
        if hasSelectionChanged() {
            showActionSheet()
        } else {
            dismiss()
        }
    }
    
    override func onTopButtonPressed() {
        handleSelectDeselectAllTracks()
        updateBottomButtons()
    }
    
    override func onBottomButtonPressed() {
        onDoneButtonPressed()
        dismiss()
    }
    
    private func handleSelectDeselectAllTracks() {
        guard isTracksAvailable else { return }
        let isSelectAll = !areAllTracksSelected()
        let gpxListToShow: [GpxDataItem]
        if isSearchActive {
            gpxListToShow = filteredGpxList
        } else if isShowingVisibleTracks {
            gpxListToShow = isVisibleTracksAvailable ? visibleGpxList : recentlyVisibleGpxList
        } else {
            gpxListToShow = allGpxList
        }
        
        if isSelectAll {
            for gpx in gpxListToShow where !selectedGpxTracks.contains(where: { $0.gpxFilePath == gpx.gpxFilePath }) {
                selectedGpxTracks.append(gpx)
            }
        } else {
            selectedGpxTracks.removeAll(where: { gpx in
                gpxListToShow.contains(where: { $0.gpxFilePath == gpx.gpxFilePath })
            })
        }
        
        tableView.reloadData()
        updateSelectedRows()
    }
    
    private func onDoneButtonPressed() {
        if hasSelectionChanged() {
            let currentVisibleTrackPaths = visibleGpxList.map { $0.gpxFilePath }
            let selectedTrackPaths = getSelectedTrackPaths()
            let tracksToShow = selectedTrackPaths.compactMap { $0 }.filter { !currentVisibleTrackPaths.contains($0) }
            let tracksToHide = currentVisibleTrackPaths.compactMap { $0 }.filter { !selectedTrackPaths.contains($0) }
            if !tracksToHide.isEmpty {
                recentlyVisibleGpxList = recentlyVisibleGpxList.filter {
                    !tracksToShow.contains($0.gpxFilePath) && tracksToHide.contains($0.gpxFilePath)
                }
                
                for trackPath in tracksToHide {
                    if let track = allGpxList.first(where: { $0.gpxFilePath == trackPath }),
                       !recentlyVisibleGpxList.contains(where: { $0.gpxFilePath == trackPath }) {
                        recentlyVisibleGpxList.append(track)
                    }
                }
            }
            
            let hiddenTracksPaths = recentlyVisibleGpxList.map { $0.gpxFilePath }
            UserDefaults.standard.set(hiddenTracksPaths, forKey: previouslyVisibleTracksKey)
            settings?.showGpx(tracksToShow)
            settings?.hideGpx(tracksToHide)
            
            if let delegate {
                delegate.onVisibleTracksUpdate()
            }
        }
    }
    
    private func onTrackOpenClicked(track: TrackItem) {
        guard let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty else { return }
        rootVC?.mapPanel.openTargetViewWithGPX(fromTracksList: track, navControllerHistory: newCurrentHistory, fromTrackMenu: false, selectedTab: .overviewTab)
    }
    
    private func onTrackAppearenceClicked(track: TrackItem) {
        guard let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty else { return }
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        state.gpxFilePath = track.gpxFilePath
        state.navControllerHistory = newCurrentHistory
        rootVC?.mapPanel.openTargetView(withGPX: track, trackHudMode: .appearanceHudMode, state: state)
    }
    
    private func onTrackNavigationClicked(track: TrackItem) {
        if track.totalTracks > 1 {
            if let vc = OATrackSegmentsViewController(filepath: track.dataItem?.file.absolutePath(), isCurrentTrack: false) {
                vc.startNavigationOnSelect = true
                rootVC?.mapPanel.closeDashboardLastScreen()
                navigationController?.popToRootViewController(animated: true)
                rootVC?.present(vc, animated: true)
            }
        } else {
            if let isFollowing = routingHelper?.isFollowingMode(), isFollowing {
                rootVC?.mapPanel.mapActions.stopNavigationActionConfirm()
            }
            
            rootVC?.mapPanel.mapActions.enterRoutePlanningMode(givenGpx: track, useIntermediatePointsByDefault: true, showDialog: true)
            rootVC?.mapPanel.closeDashboardLastScreen()
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func onTrackAnalyzeClicked(track: TrackItem) {
        guard let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty else { return }
        let state = OATrackMenuViewControllerState()
        state.navControllerHistory = newCurrentHistory
        state.openedFromTracksList = true
        state.selectedStatisticsTab = .overviewTab
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        rootVC?.mapPanel.openNewTargetViewFromTracksList(withRouteDetailsGraph: track, state: state)
    }
    
    private func onTrackShareClicked(track: TrackItem, touchPointArea: CGRect) {
        gpxHelper?.openExport(forTrack: track.dataItem, gpxDoc: nil, isCurrentTrack: false, in: self, hostViewControllerDelegate: self, touchPointArea: touchPointArea)
    }
    
    private func onTrackUploadToOsmClicked(track: TrackItem) {
        show(OAOsmUploadGPXViewConroller(gpxItems: [track]))
    }
    
    private func onTrackEditClicked(track: TrackItem) {
        guard let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty else { return }
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        state.gpxFilePath = track.gpxFilePath
        state.navControllerHistory = newCurrentHistory
        if let vc = OARoutePlanningHudViewController(fileName: track.gpxFilePath, targetMenuState: state, adjustMapPosition: true) {
            rootVC?.mapPanel.closeDashboardLastScreen()
            rootVC?.mapPanel.showScrollableHudViewController(vc)
        }
    }
    
    private func onTrackDuplicateClicked(track: TrackItem) {
        gpxHelper?.copyGPX(toNewFolder: track.gpxFolderName,
                           renameToNewName: track.gpxFileName,
                           deleteOriginalFile: false,
                           openTrack: false,
                           trackItem: track)
        updateContent()
        updateBottomButtons()
        delegate?.onVisibleTracksUpdate()
    }
    
    private func updateContent() {
        loadGpxTracks()
        loadVisibleTracks()
        loadRecentlyVisibleTracks()
        sortTracks()
        updateData()
    }
    
    private func onTrackRenameClicked(track: TrackItem) {
        let gpxFilename = track.gpxFilePath.lastPathComponent().deletingPathExtension()
        let message = localizedString("gpx_enter_new_name") + " " + gpxFilename
        let alert = UIAlertController(title: localizedString("rename_track"), message: message, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = gpxFilename
        }

        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default) { [weak self] _ in
            guard let self else { return }
            guard let text = alert.textFields?.first?.text else { return }
            let newName = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if !newName.isEmpty {
                let fileExtension = ".gpx"
                let newNameToChange = newName.hasSuffix(fileExtension)
                ? String(newName.dropLast(fileExtension.count))
                : newName
                gpxHelper?.renameTrack(track.dataItem, newName: newNameToChange, hostVC: self)
                updateContent()
                delegate?.onVisibleTracksUpdate()
            } else {
                gpxHelper?.renameTrack(nil, doc: nil, newName: nil, hostVC: self)
            }
        })

        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func onTrackMoveClicked(track: TrackItem) {
        selectedTrack = track.dataItem
        if let vc = OASelectTrackFolderViewController(gpx: track) {
            vc.delegate = self
            present(UINavigationController(rootViewController: vc), animated: true)
        }
    }
    
    private func onTrackDeleteClicked(track: TrackItem) {
        let message = localizedString("gpx_remove")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_yes"), style: .default) { [weak self] _ in
            guard let self else { return }
            guard let dataItem = track.dataItem else { return }
            let isVisible = settings?.mapSettingVisibleGpx.contains(track.gpxFilePath) ?? false
            if isVisible {
                settings?.hideGpx([track.gpxFilePath])
            }

            self.gpxDB?.removeGpxItem(dataItem, withLocalRemove: true)
            updateContent()
            delegate?.onVisibleTracksUpdate()
        })

        alert.addAction(UIAlertAction(title: localizedString("shared_string_no"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateData() {
        generateData()
        tableView.reloadData()
        updateSelectedRows()
    }
    
    private func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let destructiveAction = UIAlertAction(title: localizedString("shared_string_discard_changes"), style: .destructive) { [weak self] _ in
            self?.dismiss()
        }
        
        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel, handler: nil)
        actionSheet.addAction(destructiveAction)
        actionSheet.addAction(cancelAction)
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.leftBarButtonItem
            popoverController.permittedArrowDirections = .any
        }
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func loadGpxTracks() {
        allGpxList = OAGPXDatabase.sharedDb().getDataItems()
            .sorted { $0.fileLastUploadedTime > $1.fileLastUploadedTime }
        isTracksAvailable = !allGpxList.isEmpty
    }
    
    private func loadVisibleTracks() {
        guard let visibleGpxFilePaths = settings?.mapSettingVisibleGpx.get() else { return }
        visibleGpxList = allGpxList.filter { visibleGpxFilePaths.contains($0.gpxFilePath) }
        isVisibleTracksAvailable = !visibleGpxList.isEmpty
        selectedGpxTracks = visibleGpxList
    }
    
    private func loadRecentlyVisibleTracks() {
        guard !allGpxList.isEmpty else {
            UserDefaults.standard.removeObject(forKey: previouslyVisibleTracksKey)
            recentlyVisibleGpxList.removeAll()
            return
        }
        
        guard let visibleGpxFilePaths = settings?.mapSettingVisibleGpx.get() else { return }
        let previouslyHiddenTrackPaths = UserDefaults.standard.stringArray(forKey: previouslyVisibleTracksKey) ?? []
        let recentlyVisibleTracks = allGpxList.filter {
            previouslyHiddenTrackPaths.contains($0.gpxFilePath) && !visibleGpxFilePaths.contains($0.gpxFilePath)
        }
        
        recentlyVisibleGpxList = recentlyVisibleTracks
    }
    
    private func shouldUseInactiveColorScheme() -> Bool {
        !isTracksAvailable || (isShowingVisibleTracks && !isVisibleTracksAvailable && recentlyVisibleGpxList.isEmpty)
    }
    
    private func getGpxForSelectedRow(at indexPath: IndexPath) -> GpxDataItem? {
        if isSearchActive {
            return filteredGpxList[indexPath.row]
        } else {
            switch indexPath.section {
            case 0:
                return isShowingVisibleTracks ? visibleGpxList[indexPath.row] : allGpxList[indexPath.row]
            case 1 where isShowingVisibleTracks:
                return recentlyVisibleGpxList[indexPath.row]
            default:
                return nil
            }
        }
    }
    
    private func getSelectedTrackPaths() -> [String] {
        selectedGpxTracks.map { $0.gpxFilePath }
    }
    
    private func updateSelectedRows() {
        let gpxListToShow = isSearchActive ? filteredGpxList : (isShowingVisibleTracks ? visibleGpxList : allGpxList)
        let recentlyVisibleTracks = isShowingVisibleTracks ? recentlyVisibleGpxList : []
        for (sectionIndex, section) in [gpxListToShow, recentlyVisibleTracks].enumerated() {
            for (rowIndex, gpx) in section.enumerated() {
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                if selectedGpxTracks.contains(where: { $0.gpxFilePath == gpx.gpxFilePath }) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
        }
    }
    
    private func hasSelectionChanged() -> Bool {
        let currentVisibleTrackPaths = visibleGpxList.map { $0.gpxFilePath }
        let selectedTrackPaths = getSelectedTrackPaths()
        return Set(currentVisibleTrackPaths) != Set(selectedTrackPaths)
    }
    
    private func areAllTracksSelected() -> Bool {
        let selectedTrackPaths = Set(getSelectedTrackPaths())
        if isSearchActive {
            let gpxListToShow = filteredGpxList
            return gpxListToShow.allSatisfy { selectedTrackPaths.contains($0.gpxFilePath) }
        } else if isShowingVisibleTracks {
            if isVisibleTracksAvailable {
                return visibleGpxList.allSatisfy { selectedTrackPaths.contains($0.gpxFilePath) }
            } else {
                return recentlyVisibleGpxList.allSatisfy { selectedTrackPaths.contains($0.gpxFilePath) }
            }
        } else {
            let allTracks = allGpxList + recentlyVisibleGpxList
            return allTracks.allSatisfy { selectedTrackPaths.contains($0.gpxFilePath) }
        }
    }
    
    private func setupHeaderView() -> UIView? {
        let headerView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.width, height: 44))
        headerView.backgroundColor = .groupBg
        headerView.addSubview(sortButton)
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sortButton.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            sortButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            sortButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        return headerView
    }
    
    private func createSortMenu() -> UIMenu {
        let sortingOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .nearest),
            createAction(for: .lastModified)
        ])
        let alphabeticalOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .nameAZ),
            createAction(for: .nameZA)
        ])
        let dateOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .newestDateFirst),
            createAction(for: .oldestDateFirst)
        ])
        let distanceOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .longestDistanceFirst),
            createAction(for: .shortestDistanceFirst)
        ])
        let durationOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .longestDurationFirst),
            createAction(for: .shorterDurationFirst)
        ])
        
        return UIMenu(title: "", children: [sortingOptions, alphabeticalOptions, dateOptions, distanceOptions, durationOptions])
    }
    
    private func createAction(for sortType: TracksSortMode) -> UIAction {
        let isCurrentSortType: Bool
        if isSearchActive {
            isCurrentSortType = sortType == sortTypeForSearch
        } else if isShowingVisibleTracks {
            isCurrentSortType = sortType == sortTypeForVisibleTracks
        } else {
            isCurrentSortType = sortType == sortTypeForAllTracks
        }
        
        let actionState: UIMenuElement.State = isCurrentSortType ? .on : .off
        return UIAction(title: sortType.title, image: sortType.image, state: actionState) { [weak self] _ in
            guard let self else { return }
            if self.isSearchActive {
                self.sortTypeForSearch = sortType
            } else if self.isShowingVisibleTracks {
                self.sortTypeForVisibleTracks = sortType
            } else {
                self.sortTypeForAllTracks = sortType
            }
            
            self.currentSortType = sortType
            self.sortButton.setImage(self.currentSortType.image, for: .normal)
            self.sortTracks()
            self.updateData()
        }
    }
    
    private func updateSortButtonAndMenu() {
        sortButton.setImage(currentSortType.image, for: .normal)
        sortButton.menu = createSortMenu()
    }
    
    private func sortTracks() {
        if isSearchActive {
            filteredGpxList = TracksSortModeHelper.sortTracksWithMode(filteredGpxList, mode: sortTypeForSearch)
        } else if isShowingVisibleTracks {
            visibleGpxList = TracksSortModeHelper.sortTracksWithMode(visibleGpxList, mode: sortTypeForVisibleTracks)
            recentlyVisibleGpxList = TracksSortModeHelper.sortTracksWithMode(recentlyVisibleGpxList, mode: sortTypeForVisibleTracks)
        } else {
            allGpxList = TracksSortModeHelper.sortTracksWithMode(allGpxList, mode: sortTypeForAllTracks)
        }
    }
    
    func updateDistanceAndDirection(_ forceUpdate: Bool) {
        lock.lock()
        
        guard isTracksAvailable, currentSortType == .nearest, forceUpdate 
                || Date.now.timeIntervalSince1970 - (lastUpdate ?? 0) >= 0.5
        else {
            lock.unlock()
            return
        }

        lastUpdate = Date.now.timeIntervalSince1970
        sortTracks()
        generateData()
        DispatchQueue.main.async {
            if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                self.tableView.reloadRows(at: visibleIndexPaths, with: .none)
                self.updateSelectedRows()
            }
        }

        lock.unlock()
    }
    
    @objc private func segmentChanged(_ control: UISegmentedControl) {
        isShowingVisibleTracks = control.selectedSegmentIndex == 0
        currentSortType = isShowingVisibleTracks ? sortTypeForVisibleTracks : sortTypeForAllTracks
        updateSortButtonAndMenu()
        sortTracks()
        generateData()
        tableView.reloadData()
        if isTracksAvailable {
            updateSelectedRows()
            updateBottomButtons()
        }
    }
    
    @objc private func onSearchButtonClicked() {
        isSearchActive = true
        isShowingVisibleTracks = false
        previousSelectedSegmentIndex = segmentedControl?.selectedSegmentIndex ?? 0
        currentSortType = .nameAZ
        sortTypeForSearch = .nameAZ
        filteredGpxList = allGpxList
        sortTracks()
        DispatchQueue.main.async {
            self.updateSortButtonAndMenu()
            self.updateNavbar()
            self.updateBottomButtons()
            self.navigationItem.searchController = self.navigationItem.searchController ?? self.searchController
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.searchController?.isActive = true
            self.updateData()
        }
    }
    
    @objc private func onImportButtonClicked() {
        importHelper?.onImportClicked()
    }
    
    @objc private func didFinishImport() {
        loadGpxTracks()
        updateData()
        updateBottomButtons()
    }
    
    @objc private func onCellButtonClicked(sender: UIButton) {
        let indexPath: IndexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item: OATableRowData = tableData.item(for: indexPath)
        if item.key == "noTracks" {
            onImportButtonClicked()
        } else {
            guard let segmentedControl = segmentedControl else { return }
            segmentedControl.selectedSegmentIndex = 1
            segmentChanged(segmentedControl)
        }
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
            self.buttonsBottomOffsetConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let contentInsets = UIEdgeInsets.zero
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
            self.buttonsBottomOffsetConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func updateDistanceAndDirection() {
        updateDistanceAndDirection(false)
    }
}

extension MapSettingsGpxViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController?.isActive = false
        navigationItem.searchController = nil
        isSearchActive = false
        isSearchFilteringActive = false
        filteredGpxList.removeAll()
        currentSortType = segmentedControl?.selectedSegmentIndex == 0 ? sortTypeForVisibleTracks : sortTypeForAllTracks
        updateNavbar()
        guard let segmentedControl else { return }
        segmentedControl.selectedSegmentIndex = previousSelectedSegmentIndex
        segmentChanged(segmentedControl)
        updateData()
        updateBottomButtons()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearchFilteringActive = !searchText.isEmpty
        filteredGpxList = searchText.isEmpty ? allGpxList : allGpxList.filter {
            $0.gpxFileNameWithoutExtension.localizedCaseInsensitiveContains(searchText)
        }
        
        sortTracks()
        updateData()
        updateBottomButtons()
    }
}

extension MapSettingsGpxViewController: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        // The delay is introduced to allow UISearchController to fully initialize and become ready for interaction.
        // Sometimes, immediate attempts to make the searchBar the first responder can fail due to ongoing animations or the controller's initialization process.
        let searchBarActivationDelay = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + searchBarActivationDelay) {
            if !searchController.searchBar.isFirstResponder {
                searchController.searchBar.becomeFirstResponder()
            }
        }
    }
}

extension MapSettingsGpxViewController: OATrackSavingHelperUpdatableDelegate {
    func onNeedUpdateHostData() {
        updateData()
    }
}

extension MapSettingsGpxViewController: OASelectTrackFolderDelegate {
    func onFolderSelected(_ selectedFolderName: String?) {
        if let selectedFolderName {
            if let selectedTrack {
                let trackItem = TrackItem(file: selectedTrack.file)
                trackItem.dataItem = selectedTrack
                
                gpxHelper?.copyGPX(toNewFolder: selectedFolderName, renameToNewName: nil, deleteOriginalFile: true, openTrack: false, trackItem: trackItem)
                updateContent()
                delegate?.onVisibleTracksUpdate()
            }
        }
        
        onFolderSelectCancelled()
    }
    
    func onFolderAdded(_ addedFolderName: String) {
        if let newFolderPath = app?.gpxPath.appendingPathComponent(addedFolderName), !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                updateData()
                delegate?.onVisibleTracksUpdate()
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func onFolderSelectCancelled() {
        selectedTrack = nil
    }
}
