//
//  TracksViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 11/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

private class GpxFolder {
    var subfolders: [String: GpxFolder] = [:]
    var files: [String: OAGPX] = [:]
    
    func allTrackCount() -> Int {
        return calculateFolderTracksCount(self)
    }
    
    private func calculateFolderTracksCount(_ folder: GpxFolder) -> Int {
        var count = folder.files.count
        for subfolder in folder.subfolders.values {
            count += calculateFolderTracksCount(subfolder)
        }
        return count
    }
}

private enum SortingOptions {
    case name
    case lastModified
    case nearest
    case newestDateFirst
    case longestDistanceFirst
    case longestDurationFirst
}

private enum ButtonActionNumberTag : Int {
    case startRecording = 0
    case pause = 1
    case save = 2
}

class TracksViewController: OACompoundViewController, UITableViewDelegate, UITableViewDataSource, OAUpdatableDelegate, OASaveTrackViewControllerDelegate, OASelectTrackFolderDelegate {
    
    private let visibleTracksKey = "visibleTracksKey"
    private let tracksFolderKey = "tracksFolderKey"
    private let trackKey = "trackKey"
    private let tracksCountKey = "tracksCountKey"
    private let pathKey = "pathKey"
    private let filenameKey = "filenameKey"
    private let colorKey = "colorKey"
    private let buttonTitleKey = "buttonTitleKey"
    private let buttonIconKey = "buttonIconKey"
    private let buttonActionNumberTagKey = "buttonActionNumberTagKey"
    private let secondButtonIconKey = "secondButtonIconKey"
    private let secondButtonActionNumberTagKey = "button2ActionNumberTagKey"
    private let isVisibleKey = "isVisibleKey"
    
    @IBOutlet private weak var tableView: UITableView!
    
    var hostVCDelegate: OAUpdatableDelegate?
    private var tableData = OATableDataModel()
    private var visibleTracksFolderContent = GpxFolder()
    fileprivate var currentTracksFolderContent = GpxFolder()
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var folderName = ""
    fileprivate var currentSubfolderPath = ""   // in format: "rec/new folder"
    private var currentTrack: OAGPX?
    private var recCell: OATwoButtonsTableViewCell?
    private var trackRecordingObserver: OAAutoObserverProxy?
    
    private var app: OsmAndAppProtocol
    private var settings: OAAppSettings
    private var savingHelper: OASavingTrackHelper
    private var iapHelper: OAIAPHelper
    private var routingHelper: OARoutingHelper
    private var gpxDB: OAGPXDatabase
    private var rootVC: OARootViewController
    
    required init?(coder: NSCoder) {
        app = OsmAndApp.swiftInstance()
        settings = OAAppSettings.sharedManager()
        savingHelper = OASavingTrackHelper.sharedInstance()
        iapHelper = OAIAPHelper.sharedInstance()
        rootVC = OARootViewController.instance()
        routingHelper = OARoutingHelper.sharedInstance()
        gpxDB = OAGPXDatabase.sharedDb()
        super.init(coder: coder)
    }
    
    // MARK: - Base UI settings
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let title = folderName.length > 0 ? folderName : localizedString("menu_my_trips")
        tabBarController?.navigationItem.title = title
        navigationItem.title = title
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.navigationItem.searchController = nil
        setupNavBarMenuButton()
        trackRecordingObserver = OAAutoObserverProxy.init(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackRecordingObservable)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        if isRootFolder && currentTracksFolderContent.files.isEmpty && currentTracksFolderContent.subfolders.isEmpty {
            buildFilesTree()
        }
        generateData()
    }
    
    private func updateData() {
        DispatchQueue.main.async { [weak self] in
            self?.generateData()
            self?.tableView.reloadData()
        }
    }
    
    private func hardUpdateData() {
        buildFilesTree()
        updateData()
        if let hostVCDelegate {
            hostVCDelegate.onNeedUpdateHostData()
        }
    }
    
    private func generateData() {
        tableData.clearAllData()
        var section = tableData.createNewSection()
        
        if isRootFolder && iapHelper.trackRecording.isActive() {
            if settings.mapSettingTrackRecording {
                let currentRecordingTrackRow = section.createNewRow()
                currentRecordingTrackRow.cellType = OATwoButtonsTableViewCell.getIdentifier()
                currentRecordingTrackRow.title = localizedString("recorded_track")
                let trackDistance = OAOsmAndFormatter.getFormattedDistance(savingHelper.distance) ?? ""
                let trackDuration = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(savingHelper.getCurrentGPX().timeSpan), shortFormat: true) ?? ""
                let waypointsCount = String(savingHelper.points)
                currentRecordingTrackRow.descr = trackDistance + " • " + trackDuration + " • " + waypointsCount
                currentRecordingTrackRow.iconName = "ic_custom_track_recordable"
                currentRecordingTrackRow.iconTintColor = UIColor.iconColorActive
                currentRecordingTrackRow.setObj(localizedString("ic_custom_pause"), forKey: buttonIconKey)
                currentRecordingTrackRow.setObj(ButtonActionNumberTag.pause.rawValue, forKey: buttonActionNumberTagKey)
                currentRecordingTrackRow.setObj(localizedString("ic_custom_download"), forKey: secondButtonIconKey)
                currentRecordingTrackRow.setObj(ButtonActionNumberTag.save.rawValue, forKey: secondButtonActionNumberTagKey)
            } else {
                let recordNewTrackRow = section.createNewRow()
                recordNewTrackRow.cellType = OAButtonTableViewCell.getIdentifier()
                recordNewTrackRow.title = localizedString("new_track")
                recordNewTrackRow.descr = localizedString("not_recorded")
                recordNewTrackRow.iconName = "ic_custom_trip"
                recordNewTrackRow.iconTintColor = UIColor.iconColorDefault
                recordNewTrackRow.setObj(localizedString("start_recording"), forKey: buttonTitleKey)
                recordNewTrackRow.setObj(localizedString("ic_custom_play"), forKey: buttonIconKey)
                recordNewTrackRow.setObj(ButtonActionNumberTag.startRecording.rawValue, forKey: buttonActionNumberTagKey)
            }
        }
        
        if currentTracksFolderContent.subfolders.isEmpty && currentTracksFolderContent.files.isEmpty {
            var emptyFolderBannerRow = section.createNewRow()
            emptyFolderBannerRow.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            emptyFolderBannerRow.title = localizedString(isRootFolder ? "my_places_no_tracks_title_root" : "my_places_no_tracks_title")
            emptyFolderBannerRow.descr = localizedString(isRootFolder ? "my_places_no_tracks_descr_root" : "my_places_no_tracks_descr_root")
            emptyFolderBannerRow.iconName = "ic_custom_folder_open"
            emptyFolderBannerRow.iconTintColor = UIColor.iconColorSecondary
            emptyFolderBannerRow.setObj(localizedString("shared_string_import"), forKey: buttonTitleKey)
        } else {
        
            if isRootFolder {
                var visibleTracksFolderRow = section.createNewRow()
                visibleTracksFolderRow.cellType = OARightIconTableViewCell.getIdentifier()
                visibleTracksFolderRow.key = visibleTracksKey
                visibleTracksFolderRow.title = localizedString("tracks_on_map")
                visibleTracksFolderRow.iconName = "ic_custom_map_pin"
                visibleTracksFolderRow.setObj(UIColor.iconColorActive, forKey: colorKey)
                var descr = String(format: localizedString("folder_tracks_count"), visibleTracksFolderContent.files.count)
                visibleTracksFolderRow.descr = descr
            }
            
            var foldersNames = Array(currentTracksFolderContent.subfolders.keys)
            foldersNames = sortWithOptions(foldersNames, options: .name)
            for folderName in foldersNames {
                if let folder = currentTracksFolderContent.subfolders[folderName] {
                    var folderRow = section.createNewRow()
                    folderRow.cellType = OARightIconTableViewCell.getIdentifier()
                    folderRow.key = tracksFolderKey
                    folderRow.title = folderName
                    folderRow.iconName = "ic_custom_folder"
                    folderRow.setObj(UIColor.iconColorSelected, forKey: colorKey)
                    let tracksCount = folder.allTrackCount()
                    folderRow.setObj(tracksCount, forKey: tracksCountKey)
                    var descr = String(format: localizedString("folder_tracks_count"), tracksCount)
                    folderRow.descr = descr
                    if let lastModifiedDate = OAUtilities.getFileLastModificationDate(currentSubfolderPath + "/" + folderName) {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd.MM.yyyy"
                        let lastModified = dateFormatter.string(from: lastModifiedDate)
                        folderRow.descr = lastModified + " • " + descr
                    }
                }
            }
            
            var fileNames = Array(currentTracksFolderContent.files.keys)
            fileNames = sortWithOptions(fileNames, options: .name)
            for fileName in fileNames {
                if let track = currentTracksFolderContent.files[fileName] {
                    let trackRow = section.createNewRow()
                    trackRow.cellType = OARightIconTableViewCell.getIdentifier()
                    trackRow.key = trackKey
                    trackRow.title = (fileName as NSString).deletingPathExtension
                    trackRow.setObj(track.gpxFilePath, forKey: pathKey)
                    trackRow.setObj(fileName, forKey: filenameKey)
                    trackRow.iconName = "ic_custom_trip"
                    let isVisible = settings.mapSettingVisibleGpx.contains(track.gpxFilePath)
                    trackRow.setObj(isVisible, forKey: isVisibleKey)
                    trackRow.setObj(isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault, forKey: colorKey)
                    
                    let waypointsCount = String(track.wptPoints)
                    if let distance = OAOsmAndFormatter.getFormattedDistance(track.totalDistance) {
                        if let time = OAOsmAndFormatter.getFormattedTimeInterval(Double(track.timeSpan), shortFormat: true) {
                            if let lastModifiedDate = OAUtilities.getFileLastModificationDate(track.gpxFilePath) {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "dd.MM.yyyy"
                                let lastModified = dateFormatter.string(from: lastModifiedDate)
                                trackRow.descr = lastModified + " | " + distance + " • " + time + " • " + waypointsCount
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupNavBarMenuButton() {
        let selectAction = UIAction(title: localizedString("shared_string_select"), image: UIImage.icCustomSelectOutlined) { _ in
            self.onNavbarSelectButtonClicked()
        }
        let addFolderAction = UIAction(title: localizedString("add_folder"), image: UIImage.icCustomFolderAddOutlined) { _ in
            self.onNavbarAddFolderButtonClicked()
        }
        let importAction = UIAction(title: localizedString("shared_string_import"), image: UIImage.icCustomImportOutlined) { _ in
            self.onNavbarImportButtonClicked()
        }
        let selectActionWithDivider = UIMenu(title: "", options: .displayInline, children: [selectAction])
        let addFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: [addFolderAction])
        let importActionWithDivider = UIMenu(title: "", options: .displayInline, children: [importAction])
        let menu = UIMenu(title: "", image: nil, children: [selectActionWithDivider, addFolderActionWithDivider, importActionWithDivider])
        
        if let navBarButtontem = OABaseNavbarViewController.createRightNavbarButton("", icon: UIImage.templateImageNamed("ic_navbar_overflow_menu_stroke.png"), color: UIColor.navBarTextColorPrimary, action: nil, menu: menu) {
            navigationController?.navigationBar.topItem?.setRightBarButtonItems([navBarButtontem], animated: false)
        }
    }
    
    private func sortWithOptions(_ list: [String], options: SortingOptions) -> [String] {
        // TODO: implement sorting in next task   https://github.com/osmandapp/OsmAnd-Issues/issues/2348
        return list.sorted { $0 < $1 }
    }
    
    private func showErrorAlert(_ text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Data
    
    private func buildFilesTree() {
        guard let allTracks = gpxDB.gpxList as? [OAGPX] else {return}
        guard let visibleTrackPatches = settings.mapSettingVisibleGpx else {return}
        
        currentTracksFolderContent = GpxFolder()
        visibleTracksFolderContent = GpxFolder()
        
        // create all needed folders
        
        var rootFolderPath = app.gpxPath ?? ""
        if !currentSubfolderPath.isEmpty {
            rootFolderPath = (rootFolderPath as NSString).appendingPathComponent(currentSubfolderPath)
        }
        if let rootGpxFolderUrl = URL(string: rootFolderPath) {
            recursiveFillFolderInfo(rootGpxFolderUrl, currentFolderNode: currentTracksFolderContent)
        }
        
        // add tracks to existing folders
        for track in allTracks {
            if visibleTrackPatches.contains(track.gpxFilePath) {
                visibleTracksFolderContent.files[track.gpxFilePath] = track
            }
            
            // find track subfolder
            var currentFolder = currentTracksFolderContent
            var relativeFilePath = track.gpxFilePath ?? ""
            var trimmedSubfolderPath = currentSubfolderPath.hasPrefix("/") ? currentSubfolderPath.substring(from: 1) : currentSubfolderPath
            if relativeFilePath.hasPrefix(trimmedSubfolderPath) {
                relativeFilePath = relativeFilePath.substring(from: trimmedSubfolderPath.count)
                let pathComponents = relativeFilePath.split(separator: "/")
                for i in 0..<pathComponents.count - 1 {
                    let folderName = String(pathComponents[i])
                    if let nextSubfolder = currentFolder.subfolders[folderName] {
                        currentFolder = nextSubfolder
                    }
                }
                
                // add track file to last founded subfolder
                if let filename = pathComponents.last {
                    currentFolder.files[String(filename)] = track
                }
            }
        }
    }
    
    private func recursiveFillFolderInfo(_ folderPath: URL, currentFolderNode: GpxFolder) {
        do {
            let allFolderContentUrls = try FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil, options: [])
            let subfoldersUrls = allFolderContentUrls.filter{ $0.hasDirectoryPath }
            
            for subfolderUrl in subfoldersUrls {
                let newSubfolderNode = GpxFolder()
                let subfolderName = subfolderUrl.lastPathComponent
                currentFolderNode.subfolders[subfolderName] = newSubfolderNode
                recursiveFillFolderInfo(subfolderUrl, currentFolderNode: newSubfolderNode)
            }
        } catch {
        }
    }
        
    // MARK: - Navbar Actions
    
    private func onNavbarSelectButtonClicked() {
        print("onNavbarSelectButtonClicked")
    }
    
    private func onNavbarAddFolderButtonClicked() {
        let alert = UIAlertController(title: localizedString("add_folder"), message: localizedString("access_hint_enter_name"), preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: localizedString("shared_string_add"), style: .default) { [weak self] _ in
            guard let self else { return }
            if let folderName = alert.textFields?.first?.text {
                if OAUtilities.isValidFileName(folderName) {
                    self.addFolder(folderName)
                } else {
                    self.showErrorAlert(localizedString("incorrect_symbols"))
                }
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func onNavbarImportButtonClicked() {
        print("onNavbarImportButtonClicked")
    }
    
    // MARK: - Folders Actions
    
    private func onFolderDetailsButtonClicked() {
        print("onFolderDetailsButtonClicked")
    }
    
    private func onFolderRenameButtonClicked(_ oldFolderName: String) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self] _ in
            guard let self else { return }
            if let newFolderName = alert.textFields?.first?.text {
                if OAUtilities.isValidFileName(newFolderName) {
                    self.renameFolder(oldName: oldFolderName, newName: newFolderName)
                } else {
                    self.showErrorAlert(localizedString("incorrect_symbols"))
                }
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func onFolderAppearenceButtonClicked() {
        print("onFolderAppearenceButtonClicked")
    }
    
    private func onFolderExportButtonClicked() {
        print("onFolderExportButtonClicked")
    }
    
    private func onFolderMoveButtonClicked() {
        print("onFolderMoveButtonClicked")
    }
        
    private func onFolderDeleteButtonClicked(folderName: String, tracksCount: Int) {
        let message = String(format: localizedString("remove_folder_with_files_descr"), arguments: [folderName, tracksCount])
        let alert = UIAlertController(title: localizedString("delete_folder"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.deleteFolder(folderName)
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Tracks Actions
    
    private func onTrackShowOnMapClicked(_ filePath: String) {
        if settings.mapSettingVisibleGpx.get().contains(filePath) {
            settings.hideGpx([filePath], update: true)
        } else {
            settings.showGpx([filePath], update: true)
        }
        updateData()
    }
    
    private func onTrackAppearenceClicked(track: OAGPX, filePath: String) {
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        state.gpxFilePath = filePath
        rootVC.mapPanel.openTargetView(with: track, trackHudMode: .appearanceHudMode, state: state)
        dismiss()
    }
    
    private func onTrackNavigationClicked(_ track: OAGPX) {
        if track.totalTracks > 1 {
            let absolutePath = getAbsolutePath(track.gpxFilePath)
            if let vc = OATrackSegmentsViewController(filepath: absolutePath) {
                vc.startNavigationOnSelect = true
                rootVC.present(vc, animated: true)
                dismiss()
            }
        } else {
            if routingHelper.isFollowingMode() {
                rootVC.mapPanel.mapActions.stopNavigationActionConfirm()
            }
            rootVC.mapPanel.mapActions.enterRoutePlanningMode(given: track, useIntermediatePointsByDefault: true, showDialog: true)
            dismiss()
        }
    }
    
    private func onTrackAnalyzeClicked(_ track: OAGPX) {
        let absolutePath = getAbsolutePath(track.gpxFilePath)
        rootVC.mapPanel.openTargetViewWithRouteDetailsGraph(forFilepath: absolutePath, isCurrentTrack: false)
        dismiss()
    }
    
    private func onTrackShareClicked(_ track: OAGPX) {
        let absolutePath = getAbsolutePath(track.gpxFilePath)
        savingHelper.openExport(forTrack: track, gpxDoc: nil, isCurrentTrack: false, in: self, hostViewControllerDelegate: self)
    }
    
    private func onTrackUploadToOsmClicked(_ track: OAGPX) {
        let vc = OAOsmUploadGPXViewConroller(gpxItems: [track])
        show(vc)
    }
    
    private func onTrackEditClicked(_ track: OAGPX) {
        rootVC.mapPanel.mapViewController.hideContextPinMarker()
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        state.gpxFilePath = track.gpxFilePath
        let vc = OARoutePlanningHudViewController(fileName: track.gpxFilePath, targetMenuState: state, adjustMapPosition: false)
        rootVC.mapPanel.showScrollableHudViewController(vc)
        dismiss()
    }
    
    private func onTrackDuplicateClicked(track: OAGPX, fileName: String) {
        guard let track = currentTracksFolderContent.files[fileName] else { return }
        currentTrack = track
        let trimmedFilename = (track.gpxFileName as NSString).deletingPathExtension
        if let vc = OASaveTrackViewController(fileName: trimmedFilename, filePath: track.gpxFilePath, showOnMap: true, simplifiedTrack: false, duplicate: true) {
            vc.delegate = self
            present(vc, animated: true)
        }
    }
    
    private func onTrackRenameClicked(_ track: OAGPX) {
        let message = localizedString("gpx_enter_new_name") + " " + track.gpxTitle
        let alert = UIAlertController(title: localizedString("rename_track"), message: message, preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default) { [weak self] _ in
            guard let self else { return }
            if let newName = alert.textFields?.first?.text {
                savingHelper.renameTrack(track, newName: newName, hostVC: self)
                hardUpdateData()
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func onTrackMoveClicked(_ track: OAGPX) {
        currentTrack = track
        if let vc = OASelectTrackFolderViewController(gpx: track) {
            vc.delegate = self
            present(vc, animated: true)
        }
    }
    
    private func onTrackDeleteClicked(track: OAGPX, isCurrentTrack: Bool) {
        let message = isCurrentTrack ? localizedString("track_clear_q") : localizedString("gpx_remove")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_yes"), style: .default) { [weak self] _ in
            guard let self else { return }
            if isCurrentTrack {
                settings.mapSettingTrackRecording = false
                savingHelper.clearData()
                DispatchQueue.main.async { [weak self] in
                    self?.rootVC.mapPanel.mapViewController.hideRecGpxTrack()
                }
                updateData()
            } else {
                let isVisible = settings.mapSettingVisibleGpx.contains(track.gpxFilePath)
                if isVisible {
                    settings.hideGpx([track.gpxFilePath])
                }
                OAGPXDatabase.sharedDb().removeGpxItem(track.gpxFilePath)
                hardUpdateData()
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_no"), style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Recording track Actions
    
    @objc private func onCurrentTrackButtonClicked(_ sender: UIButton) {
        guard !tableView.isEditing else { return }
        if sender.tag == ButtonActionNumberTag.startRecording.rawValue {
            startRecordingClicked()
        } else if sender.tag == ButtonActionNumberTag.pause.rawValue {
            stopRecordingClicked()
        } else if sender.tag == ButtonActionNumberTag.save.rawValue {
            saveRecordingClicked()
        }
    }
    
    private func startRecordingClicked() {
        if !settings.mapSettingSaveTrackIntervalApproved.get() && savingHelper.hasData() {
            let bottomSheet = OARecordSettingsBottomSheetViewController { [weak self] recordingInterval, rememberChoice, showOnMap in
                if let interval = self?.settings.trackIntervalArray[0] as? Int32 {
                    self?.settings.mapSettingSaveTrackIntervalGlobal.set(interval)
                }
                if rememberChoice {
                    self?.settings.mapSettingSaveTrackIntervalApproved.set(true)
                }
                self?.settings.mapSettingShowRecordingTrack.set(showOnMap)
                self?.settings.mapSettingTrackRecording = true
                self?.updateData()
            }
            bottomSheet?.present(in: rootVC)
        } else {
            settings.mapSettingTrackRecording = true
            updateData()
        }
    }
    
    private func stopRecordingClicked() {
        settings.mapSettingTrackRecording = false
        updateData()
    }
    
    private func saveRecordingClicked() {
        if savingHelper.hasDataToSave() && savingHelper.distance < 10 {
            OAAlertBottomSheetViewController.showAlert(withTitle: nil, 
                                                       titleIcon: nil,
                                                       message: localizedString("track_save_short_q"),
                                                       cancelTitle: localizedString("shared_string_no"),
                                                       doneTitle: localizedString("shared_string_yes")) { [weak self] in
                self?.doSaveTrack()
            }
        } else {
            doSaveTrack()
        }
    }
    
    private func doSaveTrack() {
        let wasRecording = settings.mapSettingTrackRecording
        settings.mapSettingTrackRecording = false
        if savingHelper.hasDataToSave() {
            savingHelper.saveDataToGpx()
        }
        updateData()
        
        if wasRecording {
            OAAlertBottomSheetViewController.showAlert(withTitle: nil,
                                                       titleIcon: nil,
                                                       message: localizedString("track_continue_rec_q"),
                                                       cancelTitle: localizedString("shared_string_no"),
                                                       doneTitle: localizedString("shared_string_yes")) { [weak self] in
                self?.settings.mapSettingTrackRecording = true
                self?.updateData()
            }
        }
    }
    
    @objc func onObservedRecordedTrackChanged() {
        if isRootFolder {
            generateData()
            DispatchQueue.main.async { [weak self] in
                let recordingTrackRowIndexPath = IndexPath(row: 0, section: 0)
                self?.tableView.reloadRows(at: [recordingTrackRowIndexPath], with: .none)
            }
        }
    }
    
    // MARK: - Files operations
    
    private func getAbsolutePath(_ relativeFilepath: String) -> String {
        return (app.gpxPath as NSString).appendingPathComponent(relativeFilepath)
    }
    
    private func currentFolderAbsolutePath() -> String {
        var path = app.gpxPath ?? ""
        if !currentSubfolderPath.isEmpty {
            path = path + "/" + currentSubfolderPath
        }
        return path
    }
    
    private func addFolder(_ name: String) {
        let newFolderPath = currentFolderAbsolutePath() + "/" + name
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                currentTracksFolderContent.subfolders[name] = GpxFolder()
                updateData()
            } catch {
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func renameFolder(oldName: String, newName: String) {
        let oldFolderPath = currentFolderAbsolutePath() + "/" + oldName
        let newFolderPath = currentFolderAbsolutePath() + "/" + newName
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.moveItem(atPath: oldFolderPath, toPath: newFolderPath)
                currentTracksFolderContent.subfolders[newName] = currentTracksFolderContent.subfolders[oldName]
                currentTracksFolderContent.subfolders[oldName] = nil
                updateData()
            } catch {
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func deleteFolder(_ folderName: String) {
        let folderPath = currentFolderAbsolutePath() + "/" + folderName
        do {
            try FileManager.default.removeItem(atPath: folderPath)
            currentTracksFolderContent.subfolders[folderName] = nil
            updateData()
        } catch {
        }
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(tableData.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell?
        
        if item.cellType == OAButtonTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.getIdentifier()) as? OAButtonTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAButtonTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAButtonTableViewCell
                cell?.leftIconView.contentMode = .center
                cell?.button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
                cell?.button.layer.cornerRadius = 9
                cell?.setCustomLeftSeparatorInset(true)
                cell?.separatorInset = .zero
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named:iconName)
                    cell.leftIconView.tintColor = UIColor.iconColorDefault
                }
                cell.button.backgroundColor = UIColor.contextMenuButtonBg
                if let buttonTitle = item.string(forKey: buttonTitleKey) {
                    cell.button.setTitle(buttonTitle, for: .normal)
                    cell.button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
                }
                if let buttonIconName = item.string(forKey: buttonIconKey) {
                    cell.button.setImage(UIImage.templateImageNamed(buttonIconName), for: .normal)
                    cell.button.tintColor = UIColor.iconColorActive
                }
                cell.button.removeTarget(nil, action: nil, for: .allEvents)
                cell.button.addTarget(self, action: #selector(onCurrentTrackButtonClicked(_:)), for: .touchUpInside)
                cell.button.tag = item.integer(forKey: buttonActionNumberTagKey)
                outCell = cell
            }
        } else if item.cellType == OATwoButtonsTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OATwoButtonsTableViewCell.getIdentifier()) as? OATwoButtonsTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OATwoButtonsTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OATwoButtonsTableViewCell
                cell?.leftIconView.contentMode = .center
                cell?.leftButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
                cell?.rightButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
                cell?.leftButton.layer.cornerRadius = 9
                cell?.rightButton.layer.cornerRadius = 9
                cell?.setCustomLeftSeparatorInset(true)
                cell?.separatorInset = .zero
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named:iconName)
                    cell.leftIconView.tintColor = UIColor.iconColorDefault
                }
                
                cell.leftButton.setTitle("", for: .normal)
                cell.leftButton.backgroundColor = UIColor.contextMenuButtonBg
                if let buttonIconName = item.string(forKey: buttonIconKey) {
                    cell.leftButton.setImage(UIImage.templateImageNamed(buttonIconName), for: .normal)
                    cell.leftButton.tintColor = UIColor.iconColorActive
                }
                cell.leftButton.removeTarget(nil, action: nil, for: .allEvents)
                cell.leftButton.addTarget(self, action: #selector(onCurrentTrackButtonClicked(_:)), for: .touchUpInside)
                cell.leftButton.tag = item.integer(forKey: buttonActionNumberTagKey)
                
                cell.rightButton.setTitle("", for: .normal)
                cell.rightButton.backgroundColor = UIColor.contextMenuButtonBg
                if let buttonIconName = item.string(forKey: secondButtonIconKey) {
                    cell.rightButton.setImage(UIImage.templateImageNamed(buttonIconName), for: .normal)
                    cell.rightButton.tintColor = UIColor.iconColorActive
                }
                cell.rightButton.removeTarget(nil, action: nil, for: .allEvents)
                cell.rightButton.addTarget(self, action: #selector(onCurrentTrackButtonClicked(_:)), for: .touchUpInside)
                cell.rightButton.tag = item.integer(forKey: secondButtonActionNumberTagKey)
                recCell = cell
                outCell = cell
            }
        } else if item.cellType == OARightIconTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.getIdentifier()) as? OARightIconTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OARightIconTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OARightIconTableViewCell
                cell?.selectionStyle = .none
                cell?.titleLabel.textColor = UIColor.textColorPrimary
                cell?.descriptionLabel.textColor = UIColor.textColorSecondary
                cell?.rightIconView.tintColor = UIColor.iconColorDefault
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                cell.rightIconView.image = UIImage.templateImageNamed("ic_custom_arrow_right")
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                if let color = item.obj(forKey: colorKey) as? UIColor {
                    cell.leftIconView.tintColor = color
                }
                outCell = cell
            }
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier()) as? OALargeImageTitleDescrTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OALargeImageTitleDescrTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OALargeImageTitleDescrTableViewCell
                cell?.selectionStyle = .none
                cell?.imageWidthConstraint.constant = 60
                cell?.imageHeightConstraint.constant = 60
                cell?.cellImageView?.contentMode = .scaleAspectFit
            }
            if let cell = cell {
                cell.titleLabel?.text = item.title
                cell.descriptionLabel?.text = item.descr
                cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
                cell.cellImageView?.tintColor = item.iconTintColor
                cell.button?.setTitle(item.obj(forKey: buttonTitleKey) as? String, for: .normal)
                cell.button?.removeTarget(nil, action: nil, for: .allEvents)
                cell.button?.addTarget(self, action: #selector(onNavbarImportButtonClicked), for: .touchUpInside)
            }
            outCell = cell

            let update: Bool = outCell?.needsUpdateConstraints() ?? false
            if update {
                outCell?.setNeedsUpdateConstraints()
            }
        }
        
        return outCell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == visibleTracksKey {
            let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
                vc.currentTracksFolderContent = visibleTracksFolderContent
                vc.folderName = localizedString("tracks_on_map")
                vc.isRootFolder = false
                vc.isVisibleOnMapFolder = true
                show(vc)
            }
        } else if item.key == tracksFolderKey {
            if let subfolderName = item.title {
                if let subfolder = currentTracksFolderContent.subfolders[subfolderName] {
                    let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
                        vc.currentTracksFolderContent = subfolder
                        vc.folderName = subfolderName
                        vc.currentSubfolderPath = currentSubfolderPath + "/" + subfolderName
                        vc.isRootFolder = false
                        vc.hostVCDelegate = self
                        show(vc)
                    }
                }
            }
        } else if item.key == trackKey {
            if let filename = item.string(forKey: filenameKey) {
                if let track = currentTracksFolderContent.files[filename] {
                    rootVC.mapPanel.openTargetView(with: track)
                    rootVC.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.key == tracksFolderKey {
            
            let selectedFolderName = item.title ?? ""
            
            let menuProvider: UIContextMenuActionProvider = { _ in
                
                let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { _ in
                    self.onFolderDetailsButtonClicked()
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [detailsAction])
                
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { _ in
                    self.onFolderRenameButtonClicked(selectedFolderName)
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { _ in
                    self.onFolderAppearenceButtonClicked()
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction, appearenceAction])
                
                let exportAction = UIAction(title: localizedString("shared_string_export"), image: UIImage.icCustomExportOutlined) { _ in
                    self.onFolderExportButtonClicked()
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined) { _ in
                    self.onFolderMoveButtonClicked()
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [exportAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { _ in
                    let folderTracksCount = item.integer(forKey: self.tracksCountKey)
                    self.onFolderDeleteButtonClicked(folderName: selectedFolderName, tracksCount: folderTracksCount)
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        } else if item.key == trackKey {
            
            let selectedTrackPath = item.string(forKey: self.pathKey) ?? ""
            let selectedTrackFilename = item.string(forKey: self.filenameKey) ?? ""
            let isTrackVisible = item.bool(forKey: isVisibleKey)
            let isCurrentTrack = false
            guard let track = currentTracksFolderContent.files[selectedTrackFilename] else { return nil}
           
            let menuProvider: UIContextMenuActionProvider = { _ in
               
                let showOnMapAction = UIAction(title: localizedString(isTrackVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: UIImage.icCustomMapPinOutlined) { _ in
                    self.onTrackShowOnMapClicked(selectedTrackPath)
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { _ in
                    self.onTrackAppearenceClicked(track: track, filePath: selectedTrackFilename)
                }
                let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: UIImage.icCustomNavigationOutlined) { _ in
                    self.onTrackNavigationClicked(track)
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, appearenceAction, navigationAction])
                
                let analyzeAction = UIAction(title: localizedString("gpx_analyze"), image: UIImage.icCustomGraph) { _ in
                    self.onTrackAnalyzeClicked(track)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [analyzeAction])
                
                let shareAction = UIAction(title: localizedString("shared_string_share"), image: UIImage.icCustomExportOutlined) { _ in
                    self.onTrackShareClicked(track)
                }
                let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm"), image: UIImage.icCustomUploadToOpenstreetmapOutlined) { _ in
                    self.onTrackUploadToOsmClicked(track)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [shareAction, uploadToOsmAction])
                
                let editAction = UIAction(title: localizedString("shared_string_edit"), image: UIImage.icCustomTrackEdit) { _ in
                    self.onTrackEditClicked(track)
                }
                let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: UIImage.icCustomCopy) { _ in
                    self.onTrackDuplicateClicked(track: track, fileName: selectedTrackFilename)
                }
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { _ in
                    self.onTrackRenameClicked(track)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined) { _ in
                    self.onTrackMoveClicked(track)
                }
                let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction, duplicateAction, renameAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { _ in
                    self.onTrackDeleteClicked(track: track, isCurrentTrack: isCurrentTrack)
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        }
        return nil
    }
    
    // MARK: - OAUpdatableDelegate
    
    func onNeedUpdateHostData() {
        hardUpdateData()
    }
    
    // MARK: - OASaveTrackViewControllerDelegate
    
    func onSave(asNewTrack fileName: String!, showOnMap: Bool, simplifiedTrack: Bool, openTrack: Bool) {
        let newFolderName = (fileName as NSString).deletingLastPathComponent
        let newFileName = ((fileName as NSString).lastPathComponent as NSString).appendingPathExtension("gpx")
        if currentTrack != nil {
            savingHelper.copyGPX(toNewFolder: newFolderName, renameToNewName: newFileName, deleteOriginalFile: false, openTrack: false, gpx: currentTrack)
            currentTrack = nil
            hardUpdateData()
        }
    }
    
    // MARK: - OASelectTrackFolderDelegate
    
    func onFolderSelected(_ selectedFolderName: String!) {
        if currentTrack != nil {
            savingHelper.copyGPX(toNewFolder: selectedFolderName, renameToNewName: nil, deleteOriginalFile: true, openTrack: false, gpx: currentTrack)
            currentTrack = nil
            hardUpdateData()
        }
    }
    
    func onFolderAdded(_ addedFolderName: String!) {
        let newFolderPath = getAbsolutePath(addedFolderName)
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                hardUpdateData()
            } catch {
            }
        }
    }
}
