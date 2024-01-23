//
//  MapSettingsGpxViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

@objc(OAMapSettingsGpxViewController)
@objcMembers
final class MapSettingsGpxViewController: OABaseNavbarSubviewViewController {
    private let previouslyVisibleTracksKey = "PreviouslyVisibleGpxFilePaths"
    private var searchController: UISearchController?
    private var segmentedControl: UISegmentedControl?
    private var allGpxList: [OAGPX] = []
    private var visibleGpxList: [OAGPX] = []
    private var recentlyVisibleGpxList: [OAGPX] = []
    private var filteredGpxList: [OAGPX] = []
    private var selectedGpxTracks: [OAGPX] = []
    private var previousSelectedSegmentIndex: Int = 0
    private var isShowingVisibleTracks = true
    private var isSearchActive = false
    private var isSearchFilteringActive = false
    private var isTracksAvailable = false
    private var isVisibleTracksAvailable = false
    
    override func commonInit() {
        loadGpxTracks()
        loadVisibleTracks()
        loadRecentlyVisibleTracks()
    }
    
    override func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: OASimpleTableViewCell.getIdentifier(), bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.getIdentifier())
        tableView.register(UINib(nibName: OALargeImageTitleDescrTableViewCell.getIdentifier(), bundle: nil), forCellReuseIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier())
        tableView.setEditing(true, animated: false)
        tableView.allowsMultipleSelectionDuringEditing = true
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        updateSelectedRows()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let searchController, searchController.isActive {
            searchController.isActive = false
            navigationItem.searchController = nil
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
                let visibleGpxFilePaths = OAAppSettings.sharedManager()?.mapSettingVisibleGpx.get() ?? []
                let gpxListToShow = isSearchActive ? filteredGpxList : (isShowingVisibleTracks ? visibleGpxList : allGpxList)
                for gpx in gpxListToShow {
                    let title = gpx.getNiceTitle()
                    let distance = OAOsmAndFormatter.getFormattedDistance(gpx.totalDistance) ?? "N/A"
                    let time = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(gpx.timeSpan), shortFormat: true) ?? "N/A"
                    let waypointCount = "\(gpx.wptPoints)"
                    let gpxRow = tracksSection.createNewRow()
                    gpxRow.cellType = OASimpleTableViewCell.getIdentifier()
                    gpxRow.title = title
                    gpxRow.setObj(distance, forKey: "distance")
                    gpxRow.setObj(time, forKey: "time")
                    gpxRow.setObj(waypointCount, forKey: "waypointCount")
                    gpxRow.iconName = "ic_custom_trip"
                    gpxRow.iconTintColor = visibleGpxFilePaths.contains(gpx.gpxFilePath) ? .iconColorActive : .iconColorDisabled
                }
            }
            if isShowingVisibleTracks && !recentlyVisibleGpxList.isEmpty && !isSearchActive {
                let recentlyVisibleSection = tableData.createNewSection()
                recentlyVisibleSection.headerText = localizedString("recently_visible") + " (\(recentlyVisibleGpxList.count))"
                for gpx in recentlyVisibleGpxList {
                    let title = gpx.getNiceTitle()
                    let distance = OAOsmAndFormatter.getFormattedDistance(gpx.totalDistance) ?? "N/A"
                    let time = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(gpx.timeSpan), shortFormat: true) ?? "N/A"
                    let waypointCount = "\(gpx.wptPoints)"
                    let gpxRow = recentlyVisibleSection.createNewRow()
                    gpxRow.cellType = OASimpleTableViewCell.getIdentifier()
                    gpxRow.title = title
                    gpxRow.setObj(distance, forKey: "distance")
                    gpxRow.setObj(time, forKey: "time")
                    gpxRow.setObj(waypointCount, forKey: "waypointCount")
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
            let distance = item.obj(forKey: "distance") as? String ?? ""
            let time = item.obj(forKey: "time") as? String ?? ""
            let waypointCount = item.obj(forKey: "waypointCount") as? String ?? ""
            cell.titleLabel.text = item.title
            cell.descriptionLabel.text = [distance, time, waypointCount].filter { !$0.isEmpty }.joined(separator: " · ")
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
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
           let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
                self.tableView.contentInset = contentInsets
                self.tableView.scrollIndicatorInsets = contentInsets
                self.buttonsBottomOffsetConstraint.constant = keyboardHeight
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
           let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            let contentInsets = UIEdgeInsets.zero
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
                self.tableView.contentInset = contentInsets
                self.tableView.scrollIndicatorInsets = contentInsets
                self.buttonsBottomOffsetConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    private func handleSelectDeselectAllTracks() {
        guard isTracksAvailable else { return }
        let isSelectAll = !areAllTracksSelected()
        let gpxListToShow = isSearchActive ? filteredGpxList : (isShowingVisibleTracks ? visibleGpxList : allGpxList)
        let recentlyVisibleTracks = isShowingVisibleTracks ? recentlyVisibleGpxList : []
        let isFiltering = isSearchActive && !filteredGpxList.isEmpty
        
        if isSelectAll {
            if isFiltering {
                for gpx in gpxListToShow where !selectedGpxTracks.contains(where: { $0.gpxFilePath == gpx.gpxFilePath }) {
                    selectedGpxTracks.append(gpx)
                }
            } else {
                selectedGpxTracks = gpxListToShow + recentlyVisibleTracks
            }
        } else {
            if isFiltering {
                selectedGpxTracks.removeAll(where: { gpx in
                    filteredGpxList.contains(where: { $0.gpxFilePath == gpx.gpxFilePath })
                })
            } else {
                selectedGpxTracks.removeAll()
            }
        }
        
        tableView.reloadData()
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                let trackList = (section == 0 ? gpxListToShow : recentlyVisibleTracks)
                if row < trackList.count {
                    if isSelectAll {
                        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    } else {
                        tableView.deselectRow(at: indexPath, animated: false)
                    }
                }
            }
        }
    }
    
    private func onDoneButtonPressed() {
        if hasSelectionChanged() {
            let currentVisibleTrackPaths = visibleGpxList.map { $0.gpxFilePath }
            let selectedTrackPaths = getSelectedTrackPaths()
            let tracksToShow = selectedTrackPaths.compactMap { $0 }.filter { !currentVisibleTrackPaths.contains($0) }
            let tracksToHide = currentVisibleTrackPaths.compactMap { $0 }.filter { !selectedTrackPaths.contains($0) }
            for trackPath in tracksToHide {
                if let track = allGpxList.first(where: { $0.gpxFilePath == trackPath }) {
                    if !recentlyVisibleGpxList.contains(where: { $0.gpxFilePath == trackPath }) {
                        recentlyVisibleGpxList.append(track)
                    }
                }
            }
            
            recentlyVisibleGpxList.removeAll { tracksToShow.contains($0.gpxFilePath) }
            let hiddenTracksPaths = recentlyVisibleGpxList.map { $0.gpxFilePath }
            UserDefaults.standard.set(hiddenTracksPaths, forKey: previouslyVisibleTracksKey)
            OAAppSettings.sharedManager()?.showGpx(tracksToShow)
            OAAppSettings.sharedManager()?.hideGpx(tracksToHide)
        }
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
        if let gpxDatabase = OAGPXDatabase.sharedDb() {
            allGpxList = gpxDatabase.gpxList.compactMap { $0 as? OAGPX }
                .sorted {
                    guard let date1 = $0.importDate, let date2 = $1.importDate else { return false }
                    return date1 > date2
                }
            isTracksAvailable = !allGpxList.isEmpty
        } else {
            isTracksAvailable = false
        }
    }
    
    private func loadVisibleTracks() {
        guard let visibleGpxFilePaths = OAAppSettings.sharedManager()?.mapSettingVisibleGpx.get() else { return }
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
        
        guard let visibleGpxFilePaths = OAAppSettings.sharedManager()?.mapSettingVisibleGpx.get() else { return }
        let previouslyHiddenTrackPaths = UserDefaults.standard.stringArray(forKey: previouslyVisibleTracksKey) ?? []
        let recentlyVisibleTracks = allGpxList.filter {
            previouslyHiddenTrackPaths.contains($0.gpxFilePath) && !visibleGpxFilePaths.contains($0.gpxFilePath)
        }
        
        recentlyVisibleGpxList = recentlyVisibleTracks
    }
    
    private func shouldUseInactiveColorScheme() -> Bool {
        !isTracksAvailable || (isShowingVisibleTracks && !isVisibleTracksAvailable && recentlyVisibleGpxList.isEmpty)
    }
    
    private func getGpxForSelectedRow(at indexPath: IndexPath) -> OAGPX? {
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
        guard let visibleGpxFilePaths = OAAppSettings.sharedManager()?.mapSettingVisibleGpx.get() else { return }
        let gpxListToShow = isSearchActive ? filteredGpxList : (isShowingVisibleTracks ? visibleGpxList : allGpxList)
        if !isSearchFilteringActive {
            selectedGpxTracks.removeAll()
            for gpx in gpxListToShow where visibleGpxFilePaths.contains(gpx.gpxFilePath) {
                selectedGpxTracks.append(gpx)
            }
        }
        
        for (index, gpx) in gpxListToShow.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            if selectedGpxTracks.contains(where: { $0.gpxFilePath == gpx.gpxFilePath }) {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }
    
    private func hasSelectionChanged() -> Bool {
        let currentVisibleTrackPaths = visibleGpxList.map { $0.gpxFilePath }
        let selectedTrackPaths = getSelectedTrackPaths()
        return Set(currentVisibleTrackPaths) != Set(selectedTrackPaths)
    }
    
    private func areAllTracksSelected() -> Bool {
        let gpxListToShow = isSearchActive ? filteredGpxList : (isShowingVisibleTracks ? visibleGpxList : allGpxList)
        let selectedTrackPaths = Set(getSelectedTrackPaths())
        if isSearchActive {
            return gpxListToShow.allSatisfy { selectedTrackPaths.contains($0.gpxFilePath) }
        } else {
            let recentlyVisibleTracks = isShowingVisibleTracks ? recentlyVisibleGpxList : []
            let allTracks = gpxListToShow + recentlyVisibleTracks
            return allTracks.allSatisfy { selectedTrackPaths.contains($0.gpxFilePath) }
        }
    }
    
    @objc private func segmentChanged(_ control: UISegmentedControl) {
        isShowingVisibleTracks = control.selectedSegmentIndex == 0
        generateData()
        tableView.reloadData()
        if isTracksAvailable {
            updateSelectedRows()
            updateBottomButtons()
        }
    }
    
    @objc private func onSearchButtonClicked() {
        if searchController == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchBar.delegate = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = localizedString("shared_string_search")
            navigationItem.searchController = searchController
            searchController?.isActive = true
        }
        
        isSearchActive = true
        isShowingVisibleTracks = false
        previousSelectedSegmentIndex = segmentedControl?.selectedSegmentIndex ?? 0
        filteredGpxList = allGpxList
        DispatchQueue.main.async {
            self.updateNavbar()
            self.updateBottomButtons()
            self.searchController?.searchBar.becomeFirstResponder()
            self.generateData()
            self.tableView.reloadData()
            self.updateSelectedRows()
        }
    }
    
    @objc private func onImportButtonClicked() {
        let contentTypes: [UTType] = [UTType(filenameExtension: "gpx") ?? .item,
                                      UTType(filenameExtension: "kmz") ?? .item,
                                      UTType(filenameExtension: "kml") ?? .item]
        let documentPickerVC = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        documentPickerVC.allowsMultipleSelection = false
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true, completion: nil)
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
}

extension MapSettingsGpxViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController = nil
        navigationItem.searchController = nil
        isSearchActive = false
        isSearchFilteringActive = false
        filteredGpxList.removeAll()
        updateNavbar()
        guard let segmentedControl else { return }
        segmentedControl.selectedSegmentIndex = previousSelectedSegmentIndex
        segmentChanged(segmentedControl)
        generateData()
        tableView.reloadData()
        updateSelectedRows()
        updateBottomButtons()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearchFilteringActive = !searchText.isEmpty
        filteredGpxList = searchText.isEmpty ? allGpxList : allGpxList.filter {
            $0.getNiceTitle().localizedCaseInsensitiveContains(searchText)
        }
        
        generateData()
        tableView.reloadData()
        updateSelectedRows()
        updateBottomButtons()
    }
}

extension MapSettingsGpxViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, ["gpx", "kml", "kmz"].contains(url.pathExtension.lowercased()) else { return }
        let gpxListViewController = OAGPXListViewController()
        gpxListViewController.prepareProcessUrl(url, showAlerts: true, openGpxView: false) { success in
            if success {
                DispatchQueue.main.async {
                    self.loadGpxTracks()
                    self.generateData()
                    self.tableView.reloadData()
                    self.updateSelectedRows()
                    self.updateBottomButtons()
                }
            } else {
                debugPrint("Error processing URL: \(url)")
            }
        }
    }
}
