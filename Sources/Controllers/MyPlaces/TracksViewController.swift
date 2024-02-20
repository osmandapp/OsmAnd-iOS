//
//  TracksViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 11/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

private protocol TrackListUpdatableDelegate {
    func updateHostVCWith(newFilesTree: GpxFolder, visibleFiles: GpxFolder)
}

private class GpxFolder {
    var files: [String: OAGPX] = [:]
    var subfolders: [String: GpxFolder] = [:]
    var flattenedSubfolders: [String: GpxFolder] = [:]
    var flatenedTracks: Set<OAGPX> = []
    var tracksCount: Int = 0
    var parentFolder: GpxFolder?
    var path: String = ""
    
    func performForEach(action: (_ gpx: OAGPX) -> Void) {
        for file in files.values {
            action(file)
        }
        for subfolder in subfolders.values {
            subfolder.performForEach(action: action)
        }
    }
    
    func performForSelfAndEachParents(action: (_ folder: GpxFolder) -> Void) {
        action(self)
        if let parentFolder {
            parentFolder.performForSelfAndEachParents(action: action)
        }
    }
    
    func insertFile(key: String, file: OAGPX) {
        files[key] = file
        performForSelfAndEachParents { folder in
            folder.flatenedTracks.insert(file)
            folder.tracksCount += 1
        }
    }
    
    func insertToFlattenedFolders(key: String, subfolder: GpxFolder) {
        performForSelfAndEachParents { folder in
            folder.flattenedSubfolders[key] = subfolder
        }
    }
    
    func collectFolderInfo(_ folderPath: URL) {
        do {
            let allFolderContentUrls = try FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil, options: [])
            let subfoldersUrls = allFolderContentUrls.filter{ $0.hasDirectoryPath }
            
            for subfolderUrl in subfoldersUrls {
                let newSubfolderNode = GpxFolder()
                newSubfolderNode.parentFolder = self
                let subfolderName = subfolderUrl.lastPathComponent
                subfolders[subfolderName] = newSubfolderNode
                
                let relativeSubfolderPath = subfolderUrl.relativePath.replacingOccurrences(of: OsmAndApp.swiftInstance().gpxPath + "/", with: "")
                newSubfolderNode.path = relativeSubfolderPath
                insertToFlattenedFolders(key: relativeSubfolderPath, subfolder: newSubfolderNode)
                
                newSubfolderNode.collectFolderInfo(subfolderUrl)
            }
        } catch let error {
            debugPrint(error)
        }
    }
    
    func collectTracks() -> [OAGPX] {
        var tracks = [OAGPX]()
        performForEach { gpx in
            tracks.append(gpx)
        }
        return tracks
    }
    
    func collectFilepathes() -> [String] {
        var filePathes = [String]()
        performForEach { gpx in
            let absolutePath = OsmAndApp.swiftInstance().gpxPath.appendingPathComponent(gpx.gpxFilePath)
            filePathes.append(absolutePath)
        }
        return filePathes
    }
    
    func getGpxFolderByPath(_ path: String) -> GpxFolder? {
        let trimmedPath = path.hasPrefix("/") ? path.substring(from: 1) : path
        return trimmedPath.isEmpty ? self : flattenedSubfolders[trimmedPath]
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
    case startRecording
    case pause = 1
    case save = 2
}

class TracksViewController: OACompoundViewController, UITableViewDelegate, UITableViewDataSource, OATrackSavingHelperUpdatableDelegate, TrackListUpdatableDelegate, OASaveTrackViewControllerDelegate, OASelectTrackFolderDelegate, OAGPXImportUIHelperDelegate {
    
    private let visibleTracksKey = "visibleTracksKey"
    private let tracksFolderKey = "tracksFolderKey"
    private let trackKey = "trackKey"
    private let recordingTrackKey = "recordingTrackKey"
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
    
    fileprivate var hostVCDelegate: TrackListUpdatableDelegate?
    private var tableData = OATableDataModel()
    private var visibleTracksFolderContent = GpxFolder()
    fileprivate var rootTracksFolderContent = GpxFolder()
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var shouldReload = false
    fileprivate var currentFolderPath = ""   // in format: "rec/new folder"
    fileprivate var currentFolder = GpxFolder()
    private var recCell: OATwoButtonsTableViewCell?
    private var trackRecordingObserver: OAAutoObserverProxy?
    private var trackStartStopObserver: OAAutoObserverProxy?
    
    private var trackFromOpenedContextMenu: OAGPX?
    private var folderPathFromOpenedContextMenu: String?
    
    private var app: OsmAndAppProtocol
    private var settings: OAAppSettings
    private var savingHelper: OASavingTrackHelper
    private var gpxHelper: OAGPXUIHelper
    private var iapHelper: OAIAPHelper
    private var routingHelper: OARoutingHelper
    private var gpxDB: OAGPXDatabase
    private var rootVC: OARootViewController
    private var importHelper: OAGPXImportUIHelper
    private var dateFormatter: DateFormatter
    
    required init?(coder: NSCoder) {
        app = OsmAndApp.swiftInstance()
        settings = OAAppSettings.sharedManager()
        savingHelper = OASavingTrackHelper.sharedInstance()
        gpxHelper = OAGPXUIHelper()
        iapHelper = OAIAPHelper.sharedInstance()
        rootVC = OARootViewController.instance()
        routingHelper = OARoutingHelper.sharedInstance()
        gpxDB = OAGPXDatabase.sharedDb()
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        importHelper = OAGPXImportUIHelper()
        super.init(coder: coder)
        importHelper = OAGPXImportUIHelper(hostViewController: self)
        importHelper.delegate = self
    }
    
    // MARK: - Base UI settings
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
        if shouldReload {
            updateData()
            shouldReload = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        if isRootFolder && rootTracksFolderContent.files.isEmpty && rootTracksFolderContent.subfolders.isEmpty {
            buildFilesTree()
        }
        generateData()
        
        trackRecordingObserver = OAAutoObserverProxy.init(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackRecordingObservable)
        trackStartStopObserver = OAAutoObserverProxy.init(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackStartStopRecObservable)
        
        tableView.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OATwoButtonsTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATwoButtonsTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OARightIconTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OARightIconTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OALargeImageTitleDescrTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier)
    }
    
    private func updateData() {
        generateData()
        tableView.reloadData()
    }
    
    private func updateAllFoldersVCData() {
        buildFilesTree()
        updateData()
        if let hostVCDelegate {
            hostVCDelegate.updateHostVCWith(newFilesTree: rootTracksFolderContent, visibleFiles: visibleTracksFolderContent)
        }
    }
    
    private func generateData() {
        tableData.clearAllData()
        var section = tableData.createNewSection()
        
        if isRootFolder && iapHelper.trackRecording.isActive() {
            if settings.mapSettingTrackRecording {
                let currentRecordingTrackRow = section.createNewRow()
                currentRecordingTrackRow.cellType = OATwoButtonsTableViewCell.reuseIdentifier
                currentRecordingTrackRow.key = recordingTrackKey
                currentRecordingTrackRow.title = localizedString("recorded_track")
                currentRecordingTrackRow.descr = getTrackDescription(distance: savingHelper.distance, timeSpan: savingHelper.getCurrentGPX().timeSpan, waypoints: savingHelper.points, showDate: false, filepath: nil)
                let isVisible = settings.mapSettingShowRecordingTrack.get()
                currentRecordingTrackRow.setObj(isVisible, forKey: isVisibleKey)
                currentRecordingTrackRow.iconName = "ic_custom_track_recordable"
                currentRecordingTrackRow.iconTintColor = isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault
                currentRecordingTrackRow.setObj(localizedString("ic_custom_stop"), forKey: buttonIconKey)
                currentRecordingTrackRow.setObj(ButtonActionNumberTag.pause.rawValue, forKey: buttonActionNumberTagKey)
                currentRecordingTrackRow.setObj(localizedString("ic_custom_download"), forKey: secondButtonIconKey)
                currentRecordingTrackRow.setObj(ButtonActionNumberTag.save.rawValue, forKey: secondButtonActionNumberTagKey)
            } else {
                if savingHelper.hasData() {
                    let currentPausedTrackRow = section.createNewRow()
                    currentPausedTrackRow.cellType = OATwoButtonsTableViewCell.reuseIdentifier
                    currentPausedTrackRow.key = recordingTrackKey
                    currentPausedTrackRow.title = localizedString("recorded_track")
                    currentPausedTrackRow.descr = getTrackDescription(distance: savingHelper.distance, timeSpan: savingHelper.getCurrentGPX().timeSpan, waypoints: savingHelper.points, showDate: false, filepath: nil)
                    let isVisible = settings.mapSettingShowRecordingTrack.get()
                    currentPausedTrackRow.setObj(isVisible, forKey: isVisibleKey)
                    currentPausedTrackRow.iconName = "ic_custom_track_recordable"
                    currentPausedTrackRow.iconTintColor = isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault
                    currentPausedTrackRow.setObj(localizedString("ic_custom_play"), forKey: buttonIconKey)
                    currentPausedTrackRow.setObj(ButtonActionNumberTag.startRecording.rawValue, forKey: buttonActionNumberTagKey)
                    currentPausedTrackRow.setObj(localizedString("ic_custom_download"), forKey: secondButtonIconKey)
                    currentPausedTrackRow.setObj(ButtonActionNumberTag.save.rawValue, forKey: secondButtonActionNumberTagKey)
                } else {
                    let recordNewTrackRow = section.createNewRow()
                    recordNewTrackRow.cellType = OAButtonTableViewCell.reuseIdentifier
                    recordNewTrackRow.key = recordingTrackKey
                    recordNewTrackRow.title = localizedString("new_track")
                    recordNewTrackRow.descr = localizedString("not_recorded")
                    recordNewTrackRow.iconName = "ic_custom_trip"
                    recordNewTrackRow.iconTintColor = UIColor.iconColorDefault
                    recordNewTrackRow.setObj(localizedString("start_recording"), forKey: buttonTitleKey)
                    recordNewTrackRow.setObj(localizedString("ic_custom_play"), forKey: buttonIconKey)
                    recordNewTrackRow.setObj(ButtonActionNumberTag.startRecording.rawValue, forKey: buttonActionNumberTagKey)
                    let isVisible = settings.mapSettingShowRecordingTrack.get()
                    recordNewTrackRow.setObj(isVisible, forKey: isVisibleKey)
                    recordNewTrackRow.setObj(isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault, forKey: colorKey)
                }
            }
        }
        
        guard var currentGpxFolder = (isVisibleOnMapFolder ? visibleTracksFolderContent : getGpxFolderByPath(currentFolderPath)) else { return }
        
        if currentGpxFolder.subfolders.isEmpty && currentGpxFolder.files.isEmpty {
            var emptyFolderBannerRow = section.createNewRow()
            emptyFolderBannerRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
            emptyFolderBannerRow.title = localizedString(isRootFolder ? "my_places_no_tracks_title_root" : "my_places_no_tracks_title")
            emptyFolderBannerRow.descr = localizedString(isRootFolder ? "my_places_no_tracks_descr_root" : "my_places_no_tracks_descr_root")
            emptyFolderBannerRow.iconName = "ic_custom_folder_open"
            emptyFolderBannerRow.iconTintColor = UIColor.iconColorSecondary
            emptyFolderBannerRow.setObj(localizedString("shared_string_import"), forKey: buttonTitleKey)
        } else {
        
            if isRootFolder {
                var visibleTracksFolderRow = section.createNewRow()
                visibleTracksFolderRow.cellType = OARightIconTableViewCell.reuseIdentifier
                visibleTracksFolderRow.key = visibleTracksKey
                visibleTracksFolderRow.title = localizedString("tracks_on_map")
                visibleTracksFolderRow.iconName = "ic_custom_map_pin"
                visibleTracksFolderRow.setObj(UIColor.iconColorActive, forKey: colorKey)
                var descr = String(format: localizedString("folder_tracks_count"), visibleTracksFolderContent.files.count)
                visibleTracksFolderRow.descr = descr
            }
            
            var foldersNames = Array(currentGpxFolder.subfolders.keys)
            foldersNames = sortWithOptions(foldersNames, options: .name)
            for folderName in foldersNames {
                if let folder = currentGpxFolder.subfolders[folderName] {
                    var folderRow = section.createNewRow()
                    folderRow.cellType = OARightIconTableViewCell.reuseIdentifier
                    folderRow.key = tracksFolderKey
                    folderRow.title = folderName
                    folderRow.iconName = "ic_custom_folder"
                    folderRow.setObj(UIColor.iconColorSelected, forKey: colorKey)
                    let tracksCount = folder.tracksCount
                    folderRow.setObj(tracksCount, forKey: tracksCountKey)
                    var descr = String(format: localizedString("folder_tracks_count"), tracksCount)
                    folderRow.descr = descr
                    if let lastModifiedDate = OAUtilities.getFileLastModificationDate(currentFolderPath.appendingPathComponent(folderName)) {
                        let lastModified = dateFormatter.string(from: lastModifiedDate)
                        folderRow.descr = lastModified + " • " + descr
                    }
                }
            }
            
            var fileNames = Array(currentGpxFolder.files.keys)
            fileNames = sortWithOptions(fileNames, options: .name)
            for fileName in fileNames {
                if let track = currentGpxFolder.files[fileName] {
                    let trackRow = section.createNewRow()
                    trackRow.cellType = OARightIconTableViewCell.reuseIdentifier
                    trackRow.key = trackKey
                    trackRow.title = fileName.lastPathComponent().deletingPathExtension()
                    trackRow.setObj(track.gpxFilePath, forKey: pathKey)
                    trackRow.setObj(fileName, forKey: filenameKey)
                    trackRow.iconName = "ic_custom_trip"
                    let isVisible = settings.mapSettingVisibleGpx.contains(track.gpxFilePath)
                    trackRow.setObj(isVisible, forKey: isVisibleKey)
                    trackRow.setObj(isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault, forKey: colorKey)
                    trackRow.descr = getTrackDescription(distance: track.totalDistance, timeSpan: track.timeSpan, waypoints: track.wptPoints, showDate: true, filepath: track.gpxFilePath)
                }
            }
        }
    }
    
    private func getTrackDescription(distance: Float, timeSpan: Int, waypoints: Int32, showDate: Bool, filepath: String?) -> String {
        var result = ""
        if showDate {
            if let lastModifiedDate = OAUtilities.getFileLastModificationDate(filepath) {
                let lastModified = dateFormatter.string(from: lastModifiedDate)
                result += lastModified + " | "
            }
        }
        if let trackDistance = OAOsmAndFormatter.getFormattedDistance(distance) {
            result += trackDistance + " • "
        }
        if let trackDuration = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(timeSpan), shortFormat: true) {
            result += trackDuration + " • "
        }
        let waypointsCount = String(waypoints)
        result += waypointsCount
        return result
    }
    
    private func setupNavbar() {
        var title = currentFolder.path.lastPathComponent()
        if isRootFolder {
            title = localizedString("menu_my_trips")
        } else if isVisibleOnMapFolder {
            title = localizedString("tracks_on_map")
        }
        
        tabBarController?.navigationItem.title = title
        navigationItem.title = title
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.navigationItem.searchController = nil
        setupNavBarMenuButton()
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
        // TODO: Implement Select navbar action in text task
        // let selectActionWithDivider = UIMenu(title: "", options: .displayInline, children: [selectAction])
        let addFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: [addFolderAction])
        let importActionWithDivider = UIMenu(title: "", options: .displayInline, children: [importAction])
        let menu = UIMenu(title: "", image: nil, children: [addFolderActionWithDivider, importActionWithDivider])
        // let menu = UIMenu(title: "", image: nil, children: [selectActionWithDivider, addFolderActionWithDivider, importActionWithDivider])
        
        if let navBarButtontem = OABaseNavbarViewController.createRightNavbarButton("", icon: UIImage.templateImageNamed("ic_navbar_overflow_menu_stroke.png"), color: UIColor.navBarTextColorPrimary, action: nil, target: self, menu: menu) {
            navigationController?.navigationBar.topItem?.setRightBarButtonItems([navBarButtontem], animated: false)
            navigationItem.setRightBarButtonItems([navBarButtontem], animated: false)
        }
    }
    
    private func sortWithOptions(_ list: [String], options: SortingOptions) -> [String] {
        // TODO: implement sorting in next task   https://github.com/osmandapp/OsmAnd-Issues/issues/2348
        list.sorted { $0 < $1 }
    }
    
    private func showErrorAlert(_ text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Data
    
    private func buildFilesTree() {
        guard let allTracks = gpxDB.gpxList as? [OAGPX] else {return}
        guard let visibleTrackPatches = settings.mapSettingVisibleGpx.get() else {return}
        
        rootTracksFolderContent = GpxFolder()
        visibleTracksFolderContent = GpxFolder()

        // create all needed folders
        if let rootGpxFolderUrl = URL(string: app.gpxPath) {
            rootTracksFolderContent.collectFolderInfo(rootGpxFolderUrl)
        }
        
        // add tracks to existing folders
        for track in allTracks {
            if visibleTrackPatches.contains(track.gpxFilePath) {
                visibleTracksFolderContent.insertFile(key: track.gpxFilePath, file: track)
            }
            
            let relativeFolderPath = track.gpxFilePath.deletingLastPathComponent()
            let filename = track.gpxFilePath.lastPathComponent()
            if let fillingFolder = getGpxFolderByPath(relativeFolderPath) {
                fillingFolder.insertFile(key: filename, file: track)
            }
        }
        
        currentFolder = getGpxFolderByPath(currentFolderPath) ?? rootTracksFolderContent
    }
    
    private func getGpxFolderByPath(_ path: String) -> GpxFolder? {
        return rootTracksFolderContent.getGpxFolderByPath(path)
    }
        
    // MARK: - Navbar Actions
    
    private func onNavbarSelectButtonClicked() {
        OAUtilities.showToast("", details: "This function is not implemented yet", duration: 4, in: self.view)
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
        importHelper.onImportClicked(withDestinationFolderPath: currentFolderPath)
    }
    
    // MARK: - Folders Actions
    
    private func onFolderDetailsButtonClicked() {
        OAUtilities.showToast("Folder Details", details: "This function is not implemented yet", duration: 4, in: self.view)
    }
    
    private func onFolderRenameButtonClicked(_ oldFolderName: String) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = oldFolderName
        }
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
    
    private func onFolderAppearenceButtonClicked(_ selectedFolderName: String) {
        guard let selectedFolder = currentFolder.subfolders[selectedFolderName] else { return }
        var subfolderTracks = Array(selectedFolder.flatenedTracks)
        if !subfolderTracks.isEmpty {
            let randomTrack = subfolderTracks[0]
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            rootVC.mapPanel.openTargetView(with: randomTrack, items: subfolderTracks, trackHudMode: .appearanceHudMode,  state: state)
            dismiss()
        } else {
            OAUtilities.showToast(localizedString("shared_string_error"), details: localizedString("my_places_no_tracks_title"), duration: 4, in: self.view)
        }
    }
    
    private func onFolderExportButtonClicked(_ selectedFolderName: String) {
        guard let selectedFolder = currentFolder.subfolders[selectedFolderName] else { return }
        let exportFilePathes = selectedFolder.collectFilepathes()
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        let vc = OAExportItemsViewController(tracks: exportFilePathes)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func onFolderMoveButtonClicked(_ selectedFolderName: String) {
        var trimmedPath = currentFolderPath.hasPrefix("/") ? currentFolderPath.substring(from: 1) : currentFolderPath
        trimmedPath = trimmedPath.appendingPathComponent(selectedFolderName)
        folderPathFromOpenedContextMenu = trimmedPath
        let selected = trimmedPath.deletingLastPathComponent()
        // hide from this screen moving folder and all it's subfolders, to deny move folder inside itself
        let movingSubfolderPath = (folderPathFromOpenedContextMenu ?? "") + "/"
        if let vc = OASelectTrackFolderViewController(selectedFolderName:selected, hidingSubfolderPath: movingSubfolderPath) {
            vc.delegate = self
            let navController = UINavigationController(rootViewController: vc)
            present(navController, animated: true)
        }
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
    
    private func onTrackShowOnMapClicked(trackPath: String, isVisible: Bool, isCurrentTrack: Bool) {
        if isCurrentTrack {
            if isVisible {
                settings.mapSettingShowRecordingTrack.set(false)
                rootVC.mapPanel.mapViewController.hideRecGpxTrack()
            } else {
                settings.mapSettingShowRecordingTrack.set(true)
                rootVC.mapPanel.mapViewController.showRecGpxTrack(true)
            }
        } else {
            if isVisible {
                settings.hideGpx([trackPath], update: true)
            } else {
                settings.showGpx([trackPath], update: true)
            }
        }
        updateAllFoldersVCData()
    }
    
    private func onTrackAppearenceClicked(track: OAGPX?, isCurrentTrack: Bool) {
        guard let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track else { return }
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        state.gpxFilePath = track?.gpxFilePath
        rootVC.mapPanel.openTargetView(with: gpx, trackHudMode: .appearanceHudMode, state: state)
        dismiss()
    }
    
    private func onTrackNavigationClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        guard let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track else { return }
        if gpx.totalTracks > 1 {
            let absolutePath = getAbsolutePath(gpx.gpxFilePath)
            if let vc = OATrackSegmentsViewController(filepath: absolutePath, isCurrentTrack: isCurrentTrack) {
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
    
    private func onTrackAnalyzeClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            let absolutePath = getAbsolutePath(gpx.gpxFilePath)
            rootVC.mapPanel.openTargetView(withRouteDetailsGraph: absolutePath, isCurrentTrack: isCurrentTrack)
            dismiss()
        }
    }
    
    private func onTrackShareClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            let absolutePath = getAbsolutePath(gpx.gpxFilePath)
            gpxHelper.openExport(forTrack: gpx, gpxDoc: nil, isCurrentTrack: isCurrentTrack, in: self, hostViewControllerDelegate: self)
        }
    }
    
    private func onTrackUploadToOsmClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            let vc = OAOsmUploadGPXViewConroller(gpxItems: [gpx])
            show(vc)
        }
    }
    
    private func onTrackEditClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            rootVC.mapPanel.mapViewController.hideContextPinMarker()
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            state.gpxFilePath = gpx.gpxFilePath
            let vc = OARoutePlanningHudViewController(fileName: gpx.gpxFilePath, targetMenuState: state, adjustMapPosition: false)
            rootVC.mapPanel.showScrollableHudViewController(vc)
            dismiss()
        }
    }
    
    private func onTrackDuplicateClicked(track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            trackFromOpenedContextMenu = track
            let trimmedFilename = gpx.gpxFileName.deletingPathExtension()
            if let vc = OASaveTrackViewController(fileName: trimmedFilename, filePath: gpx.gpxFilePath, showOnMap: true, simplifiedTrack: false, duplicate: true) {
                vc.delegate = self
                present(vc, animated: true)
            }
        }
    }
    
    private func onTrackRenameClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            let message = localizedString("gpx_enter_new_name") + " " + gpx.gpxTitle
            let alert = UIAlertController(title: localizedString("rename_track"), message: message, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = track?.gpxTitle
            }
            alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default) { [weak self] _ in
                guard let self else { return }
                if let newName = alert.textFields?.first?.text {
                    gpxHelper.renameTrack(gpx, newName: newName, hostVC: self)
                    updateAllFoldersVCData()
                }
            })
            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            present(alert, animated: true)
        }
    }
    
    private func onTrackMoveClicked(_ track: OAGPX?, isCurrentTrack: Bool) {
        if let gpx = isCurrentTrack ? savingHelper.getCurrentGPX() : track {
            trackFromOpenedContextMenu = gpx
            if let vc = OASelectTrackFolderViewController(gpx: gpx) {
                vc.delegate = self
                let navController = UINavigationController(rootViewController: vc)
                present(navController, animated: true)
            }
        }
    }
    
    private func onTrackDeleteClicked(track: OAGPX?, isCurrentTrack: Bool) {
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
                if let gpx = track {
                    let isVisible = settings.mapSettingVisibleGpx.contains(gpx.gpxFilePath)
                    if isVisible {
                        settings.hideGpx([gpx.gpxFilePath])
                    }
                    gpxDB.removeGpxItem(gpx.gpxFilePath)
                    updateAllFoldersVCData()
                }
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
        if !settings.mapSettingSaveTrackIntervalApproved.get() && !savingHelper.hasData() {
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
            DispatchQueue.main.async { [weak self] in
                self?.generateData()
                let recordingTrackRowIndexPath = IndexPath(row: 0, section: 0)
                self?.tableView.reloadRows(at: [recordingTrackRowIndexPath], with: .none)
            }
        }
    }
    
    // MARK: - Files operations
    
    private func getAbsolutePath(_ relativeFilepath: String) -> String {
        app.gpxPath.appendingPathComponent(relativeFilepath)
    }
    
    private func currentFolderAbsolutePath() -> String {
        
        var path = app.gpxPath ?? ""
        if !currentFolderPath.isEmpty {
            path = path.appendingPathComponent(currentFolderPath)
        }
        return path
    }
    
    private func addFolder(_ name: String) {
        let newFolderPath = currentFolderAbsolutePath().appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                currentFolder.subfolders[name] = GpxFolder()
                updateData()
            } catch let error {
                debugPrint(error)
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func renameFolder(oldName: String, newName: String) {
        
        let oldFolderPath = currentFolderAbsolutePath().appendingPathComponent(oldName)
        let newFolderPath = currentFolderAbsolutePath().appendingPathComponent(newName)
        let oldFolderShortPath = currentFolderPath.appendingPathComponent(oldName)
        let newFolderShortPath = currentFolderPath.appendingPathComponent(newName)
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.moveItem(atPath: oldFolderPath, toPath: newFolderPath)
                currentFolder.subfolders[newName] = rootTracksFolderContent.subfolders[oldName]
                currentFolder.subfolders[oldName] = nil
                guard let renamedFolder = currentFolder.subfolders[newName] else { return }
                changeGpxDBSubfolderTags(folderContent: renamedFolder, srcPath: oldFolderShortPath, destPath: newFolderShortPath)
                updateData()
            } catch let error {
                debugPrint(error)
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func deleteFolder(_ folderName: String) {
        let folderPath = currentFolderAbsolutePath().appendingPathComponent(folderName)
        do {
            currentFolder.subfolders[folderName]?.performForEach() { gpxDB.removeGpxItem($0.gpxFilePath) }
            currentFolder.subfolders[folderName] = nil
            try FileManager.default.removeItem(atPath: folderPath)
            updateData()
        } catch let error {
            debugPrint(error)
        }
    }
    
    private func moveFolder(folderPathForOpenedContextMenu: String, selectedFolderName: String) {
        let sourceFolderPath = getAbsolutePath(folderPathForOpenedContextMenu)
        let destinationShortFolderPath = selectedFolderName == localizedString("shared_string_gpx_tracks") ? "" : selectedFolderName
        let destinationFolderPath = getAbsolutePath(destinationShortFolderPath).appendingPathComponent(folderPathForOpenedContextMenu.lastPathComponent())
        do {
            try FileManager.default.moveItem(atPath: sourceFolderPath, toPath: destinationFolderPath)
            
            if let movingFolder = getGpxFolderByPath(folderPathForOpenedContextMenu) {
                changeGpxDBSubfolderTags(folderContent: movingFolder, srcPath: folderPathForOpenedContextMenu, destPath: destinationShortFolderPath)
            }
            
            updateAllFoldersVCData()
        } catch let error {
            debugPrint(error)
        }
    }
    
    fileprivate func changeGpxDBSubfolderTags(folderContent: GpxFolder, srcPath: String, destPath:String)
    {
        for gpxFile in folderContent.files.values {
            var path = gpxFile.gpxFilePath ?? ""
            let rootSrcPath = srcPath.deletingLastPathComponent()
            path = path.substring(from: rootSrcPath.length)
            path = destPath.appendingPathComponent(path)
            gpxFile.updateFolderName(path)
        }
        for folder in folderContent.subfolders.values {
            changeGpxDBSubfolderTags(folderContent: folder, srcPath: srcPath, destPath: destPath)
        }
        gpxDB.save()
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
        
        if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as? OAButtonTableViewCell
            if let cell {
                cell.leftIconView.contentMode = .center
                cell.button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
                cell.button.layer.cornerRadius = 9
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = .zero
                
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
        } else if item.cellType == OATwoButtonsTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: OATwoButtonsTableViewCell.reuseIdentifier) as? OATwoButtonsTableViewCell
            if let cell {
                cell.leftIconView.contentMode = .center
                cell.leftButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
                cell.rightButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
                cell.leftButton.layer.cornerRadius = 9
                cell.rightButton.layer.cornerRadius = 9
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = .zero
                
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named:iconName)
                }
                if let tintColor = item.iconTintColor {
                    cell.leftIconView.tintColor = tintColor
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
        } else if item.cellType == OARightIconTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.reuseIdentifier) as? OARightIconTableViewCell
            if let cell {
                cell.selectionStyle = .none
                cell.titleLabel.textColor = UIColor.textColorPrimary
                cell.descriptionLabel.textColor = UIColor.textColorSecondary
                cell.rightIconView.tintColor = UIColor.iconColorDefault
                
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                cell.rightIconView.image = UIImage.templateImageNamed("ic_custom_arrow_right")
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                if let color = item.obj(forKey: colorKey) as? UIColor {
                    cell.leftIconView.tintColor = color
                }
                outCell = cell
            }
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.reuseIdentifier {
            var cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier) as? OALargeImageTitleDescrTableViewCell
            if let cell = cell {
                cell.selectionStyle = .none
                cell.imageWidthConstraint.constant = 60
                cell.imageHeightConstraint.constant = 60
                cell.cellImageView?.contentMode = .scaleAspectFit
                
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
                vc.rootTracksFolderContent = rootTracksFolderContent
                vc.visibleTracksFolderContent = visibleTracksFolderContent
                vc.isRootFolder = false
                vc.isVisibleOnMapFolder = true
                show(vc)
            }
        } else if item.key == tracksFolderKey {
            if let subfolderName = item.title {
                let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
                    let subfolderPath = currentFolderPath.appendingPathComponent(subfolderName)
                    if let subfolder = rootTracksFolderContent.getGpxFolderByPath(subfolderPath) {
                        vc.currentFolder = subfolder
                        vc.currentFolderPath = subfolderPath
                        vc.rootTracksFolderContent = rootTracksFolderContent
                        vc.visibleTracksFolderContent = visibleTracksFolderContent
                        vc.isRootFolder = false
                        vc.hostVCDelegate = self
                        show(vc)
                    }
                }
            }
        } else if item.key == trackKey {
            if let filename = item.string(forKey: filenameKey) {
                if let track = currentFolder.files[filename] {
                    rootVC.mapPanel.openTargetView(with: track)
                    rootVC.navigationController?.popToRootViewController(animated: true)
                }
            }
        } else if item.key == recordingTrackKey {
            if savingHelper.hasData() {
                rootVC.mapPanel.openRecordingTrackTargetView()
                rootVC.navigationController?.popToRootViewController(animated: true)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.key == tracksFolderKey {
            
            let selectedFolderName = item.title ?? ""
            
            let menuProvider: UIContextMenuActionProvider = { _ in
                
                // TODO: implement Folder Details in next task
                // let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { _ in
                //     self.onFolderDetailsButtonClicked()
                // }
                // let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [detailsAction])
                
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { _ in
                    self.onFolderRenameButtonClicked(selectedFolderName)
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { _ in
                    self.onFolderAppearenceButtonClicked(selectedFolderName)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction, appearenceAction])
                
                let exportAction = UIAction(title: localizedString("shared_string_export"), image: UIImage.icCustomExportOutlined) { _ in
                    self.onFolderExportButtonClicked(selectedFolderName)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined) { _ in
                    self.onFolderMoveButtonClicked(selectedFolderName)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [exportAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { _ in
                    let folderTracksCount = item.integer(forKey: self.tracksCountKey)
                    self.onFolderDeleteButtonClicked(folderName: selectedFolderName, tracksCount: folderTracksCount)
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [secondButtonsSection, thirdButtonsSection, lastButtonsSection])
                // return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        } else if item.key == trackKey || item.key == recordingTrackKey {
            let isCurrentTrack = item.key == recordingTrackKey
            if isCurrentTrack && !savingHelper.hasData() {
                return nil
            }
            let isTrackVisible = item.bool(forKey: isVisibleKey)
            let selectedTrackPath = item.string(forKey: self.pathKey) ?? ""
            let selectedTrackFilename = item.string(forKey: self.filenameKey) ?? ""
            let track = currentFolder.files[selectedTrackFilename]
           
            let menuProvider: UIContextMenuActionProvider = { _ in
               
                let showOnMapAction = UIAction(title: localizedString(isTrackVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: UIImage.icCustomMapPinOutlined) { _ in
                    self.onTrackShowOnMapClicked(trackPath: selectedTrackPath, isVisible: isTrackVisible, isCurrentTrack: isCurrentTrack)
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { _ in
                    self.onTrackAppearenceClicked(track: track, isCurrentTrack: isCurrentTrack)
                }
                let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: UIImage.icCustomNavigationOutlined) { _ in
                    self.onTrackNavigationClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, appearenceAction, navigationAction])
                
                let analyzeAction = UIAction(title: localizedString("gpx_analyze"), image: UIImage.icCustomGraph) { _ in
                    self.onTrackAnalyzeClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [analyzeAction])
                
                let shareAction = UIAction(title: localizedString("shared_string_share"), image: UIImage.icCustomExportOutlined) { _ in
                    self.onTrackShareClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm"), image: UIImage.icCustomUploadToOpenstreetmapOutlined) { _ in
                    self.onTrackUploadToOsmClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [shareAction, uploadToOsmAction])
                
                let editAction = UIAction(title: localizedString("shared_string_edit"), image: UIImage.icCustomTrackEdit, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self.onTrackEditClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: UIImage.icCustomCopy, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self.onTrackDuplicateClicked(track: track, isCurrentTrack: isCurrentTrack)
                }
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self.onTrackRenameClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self.onTrackMoveClicked(track, isCurrentTrack: isCurrentTrack)
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
    
    // MARK: - TrackListUpdatableDelegate
    
    fileprivate func updateHostVCWith(newFilesTree: GpxFolder, visibleFiles: GpxFolder) {
        rootTracksFolderContent = newFilesTree
        visibleTracksFolderContent = visibleFiles
        shouldReload = true
        if let hostVCDelegate {
            hostVCDelegate.updateHostVCWith(newFilesTree: rootTracksFolderContent, visibleFiles: visibleFiles)
        }
    }
    
    // MARK: - OATrackSavingHelperUpdatableDelegate
    
    func onNeedUpdateHostData() {
        updateAllFoldersVCData()
    }
    
    // MARK: - OASaveTrackViewControllerDelegate
    
    func onSave(asNewTrack fileName: String!, showOnMap: Bool, simplifiedTrack: Bool, openTrack: Bool) {
        let newFolderName = fileName.deletingLastPathComponent()
        let newFileName = fileName.lastPathComponent().appendingPathExtension("gpx")
        if trackFromOpenedContextMenu != nil {
            gpxHelper.copyGPX(toNewFolder: newFolderName, renameToNewName: newFileName, deleteOriginalFile: false, openTrack: false, gpx: trackFromOpenedContextMenu)
            trackFromOpenedContextMenu = nil
            updateAllFoldersVCData()
        }
    }
    
    // MARK: - OASelectTrackFolderDelegate
    
    func onFolderSelected(_ selectedFolderName: String!) {
        if let selectedFolderName {
            if let trackFromOpenedContextMenu {
                gpxHelper.copyGPX(toNewFolder: selectedFolderName, renameToNewName: nil, deleteOriginalFile: true, openTrack: false, gpx: trackFromOpenedContextMenu)
                updateAllFoldersVCData()
            } else if let folderPathFromOpenedContextMenu {
                moveFolder(folderPathForOpenedContextMenu: folderPathFromOpenedContextMenu, selectedFolderName: selectedFolderName)
            }
        }
        trackFromOpenedContextMenu = nil
        folderPathFromOpenedContextMenu = nil
    }
    
    func onFolderAdded(_ addedFolderName: String!) {
        let newFolderPath = getAbsolutePath(addedFolderName)
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                updateAllFoldersVCData()
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func onFolderSelectCancelled() {
        folderPathFromOpenedContextMenu = nil
        trackFromOpenedContextMenu = nil
    }
    
    // MARK: - OAGPXImportUIHelperDelegate
    
    func updateVCData() {
        updateAllFoldersVCData()
    }
}
