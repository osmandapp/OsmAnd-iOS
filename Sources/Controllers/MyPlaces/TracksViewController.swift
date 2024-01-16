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

class TracksViewController: OACompoundViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let visibleTracksKey = "visibleTracksKey"
    private let tracksFolderKey = "tracksFolderKey"
    private let trackKey = "trackKey"
    private let tracksCountKey = "tracksCountKey"
    private let colorKey = "colorKey"
    private let buttonTitleKey = "buttonTitleKey"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var tableData = OATableDataModel()
    private var visibleTracksFolderContent = GpxFolder()
    fileprivate var currentTracksFolderContent = GpxFolder()
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var folderName = ""
    fileprivate var currentSubfolderPath = ""   // in format: "rec/new folder"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let title = folderName.length > 0 ? folderName : localizedString("menu_my_trips")
        tabBarController?.navigationItem.title = title
        navigationItem.title = title
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.navigationItem.searchController = nil
        setupNavBarMenuButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        if isRootFolder && currentTracksFolderContent.files.isEmpty && currentTracksFolderContent.subfolders.isEmpty {
            buildFilesTree()
        }
        generateData()
    }
    
    private func generateData() {
        tableData.clearAllData()
        var section = tableData.createNewSection()
        
        if currentTracksFolderContent.subfolders.isEmpty && currentTracksFolderContent.files.isEmpty {
            var emptyFolderRow = section.createNewRow()
            emptyFolderRow.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            emptyFolderRow.title = localizedString(isRootFolder ? "my_places_no_tracks_title_root" : "my_places_no_tracks_title")
            emptyFolderRow.descr = localizedString(isRootFolder ? "my_places_no_tracks_descr_root" : "my_places_no_tracks_descr_root")
            emptyFolderRow.iconName = "ic_custom_folder_open"
            emptyFolderRow.iconTintColor = UIColor.iconColorSecondary
            emptyFolderRow.setObj(localizedString("shared_string_import"), forKey: buttonTitleKey)
        } else {
        
            if isRootFolder {
                var visibleTracksRow = section.createNewRow()
                visibleTracksRow.cellType = OARightIconTableViewCell.getIdentifier()
                visibleTracksRow.key = visibleTracksKey
                visibleTracksRow.title = localizedString("tracks_on_map")
                visibleTracksRow.iconName = "ic_custom_map_pin"
                visibleTracksRow.setObj(UIColor.iconColorActive, forKey: colorKey)
                var descr = String(format: localizedString("folder_tracks_count"), visibleTracksFolderContent.files.count)
                visibleTracksRow.descr = descr
            }
            
            var folderNames = Array(currentTracksFolderContent.subfolders.keys)
            folderNames = sortWithOptions(folderNames, options: .name)
            for folderName in folderNames {
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
                    var trackRow = section.createNewRow()
                    trackRow.cellType = OARightIconTableViewCell.getIdentifier()
                    trackRow.key = trackKey
                    trackRow.title = (fileName as NSString).deletingPathExtension
                    trackRow.iconName = "ic_custom_trip"
                    trackRow.setObj(UIColor.iconColorDefault, forKey: colorKey)
                    
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
        
        if let navBarButtontem = OABaseNavbarViewController.createRightNavbarButton("", icon: UIImage.templateImageNamed("ic_navbar_overflow_menu_stroke.png"), color: UIColor.navBarTextColorPrimary, action: #selector(onNavbarOptionsButtonClicked), menu: menu) {
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
        guard let db = OAGPXDatabase.sharedDb() else {return}
        guard let allTracks = db.gpxList as? [OAGPX] else {return}
        guard let visibleTrackPatches = OAAppSettings.sharedManager().mapSettingVisibleGpx else {return}
        
        currentTracksFolderContent = GpxFolder()
        visibleTracksFolderContent = GpxFolder()
        
        // create all needed folders
        if let rootGpxFolderUrl = URL(string: OsmAndApp.swiftInstance().gpxPath) {
            recursiveFillFolderInfo(rootGpxFolderUrl, currentFolderNode: currentTracksFolderContent)
        }
        
        // add tracks to existing folders
        for track in allTracks {
            if visibleTrackPatches.contains(track.gpxFilePath) {
                visibleTracksFolderContent.files[track.gpxFilePath] = track
            }
            
            // find track subfolder
            var currentFolder = currentTracksFolderContent
            let pathComponents = track.gpxFilePath.split(separator: "/")
            for i in 0..<pathComponents.count - 1 {
                var folderName = String(pathComponents[i])
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
    
    private func recursiveFillFolderInfo(_ folderPath: URL, currentFolderNode: GpxFolder) {
        do {
            let allFolderContentUrls = try FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil, options: [])
            let subfoldersUrls = allFolderContentUrls.filter{ $0.hasDirectoryPath }
            
            for subfolderUrl in subfoldersUrls {
                var newSubfolderNode = GpxFolder()
                let subfolderName = subfolderUrl.lastPathComponent
                currentFolderNode.subfolders[subfolderName] = newSubfolderNode
                recursiveFillFolderInfo(subfolderUrl, currentFolderNode: newSubfolderNode)
            }
        } catch {
        }
    }
    
    // MARK: - Actions
    
    @objc private func onNavbarOptionsButtonClicked() {
        // Do nothing
    }
    
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
    
    private func onTrackShowOnMapClicked() {
        print("onTrackShowOnMapClicked")
    }
    
    private func onTrackAppearenceClicked() {
        print("onTrackAppearenceClicked")
    }
    
    private func onTrackNavigationClicked() {
        print("onTrackNavigationClicked")
    }
    
    private func onTrackAnalyzeClicked() {
        print("onTrackAnalyzeClicked")
    }
    
    private func onTrackShareClicked() {
        print("onTrackShareClicked")
    }
    
    private func onTrackUploadToOsmClicked() {
        print("onTrackUploadToOsmClicked")
    }
    
    private func onTrackEditClicked() {
        print("onTrackEditClicked")
    }
    
    private func onTrackDuplicateClicked() {
        print("onTrackDuplicateClicked")
    }
    
    private func onTrackRenameClicked() {
        print("onTrackRenameClicked")
    }
    
    private func onTrackMoveClicked() {
        print("onTrackMoveClicked")
    }
    
    private func onTrackDeleteClicked() {
        print("onTrackDeleteClicked")
    }
    
    // MARK: - Files operations
    
    private func currentFolderAbsolutePath() -> String {
        var path = OsmAndApp.swiftInstance().gpxPath ?? ""
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
                generateData()
                tableView.reloadData()
            } catch {
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func renameFolder(oldName: String, newName: String) {
        let oldFolderPath = currentFolderAbsolutePath() + "/" + oldName
        let newFolderPath = currentFolderAbsolutePath() + "/" + newName
        if let newFolderUrl = URL(string: newFolderPath) {
            if !FileManager.default.fileExists(atPath: newFolderPath) {
                do {
                    try FileManager.default.moveItem(atPath: oldFolderPath, toPath: newFolderPath)
                    currentTracksFolderContent.subfolders[newName] = currentTracksFolderContent.subfolders[oldName]
                    currentTracksFolderContent.subfolders[oldName] = nil
                    generateData()
                    tableView.reloadData()
                } catch {
                }
            } else {
                showErrorAlert(localizedString("folder_already_exsists"))
            }
        }
    }
    
    private func deleteFolder(_ folderName: String) {
        let folderPath = currentFolderAbsolutePath() + "/" + folderName
        do {
            try FileManager.default.removeItem(atPath: folderPath)
            currentTracksFolderContent.subfolders[folderName] = nil
            generateData()
            tableView.reloadData()
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
        var outCell: UITableViewCell? = nil
        
        if item.cellType == OARightIconTableViewCell.getIdentifier() {
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
                        show(vc)
                    }
                }
            }
        } else if item.key == trackKey {
            if let filename = item.title {
                if let track = currentTracksFolderContent.files[filename] {
                    OARootViewController.instance().mapPanel.openTargetView(with: track)
                    OARootViewController.instance().navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.key == tracksFolderKey {
            let menuProvider: UIContextMenuActionProvider = { _ in
                let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { _ in
                    self.onFolderDetailsButtonClicked()
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [detailsAction])
                
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { _ in
                    if let selectedFolderName = item.title {
                        self.onFolderRenameButtonClicked(selectedFolderName)
                    }
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
                    if let selectedFolderName = item.title {
                        let folderTracksCount = item.integer(forKey: self.tracksCountKey)
                        self.onFolderDeleteButtonClicked(folderName: selectedFolderName, tracksCount: folderTracksCount)
                    }
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        } else if item.key == trackKey {
            let menuProvider: UIContextMenuActionProvider = { _ in
                let showOnMapAction = UIAction(title: localizedString("shared_string_show_on_map"), image: UIImage.icCustomMapPinOutlined) { _ in
                    self.onTrackShowOnMapClicked()
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { _ in
                    self.onTrackAppearenceClicked()
                }
                let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: UIImage.icCustomNavigationOutlined) { _ in
                    self.onTrackNavigationClicked()
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, appearenceAction, navigationAction])
                
                let analyzeAction = UIAction(title: localizedString("gpx_analyze"), image: UIImage.icCustomGraph) { _ in
                    self.onTrackAnalyzeClicked()
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [analyzeAction])
                
                let shareAction = UIAction(title: localizedString("shared_string_share"), image: UIImage.icCustomExportOutlined) { _ in
                    self.onTrackShareClicked()
                }
                let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm"), image: UIImage.icCustomUploadToOpenstreetmapOutlined) { _ in
                    self.onTrackUploadToOsmClicked()
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [shareAction, uploadToOsmAction])
                
                let editAction = UIAction(title: localizedString("shared_string_edit"), image: UIImage.icCustomTrackEdit) { _ in
                    self.onTrackEditClicked()
                }
                let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: UIImage.icCustomCopy) { _ in
                    self.onTrackDuplicateClicked()
                }
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { _ in
                    self.onTrackRenameClicked()
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined) { _ in
                    self.onTrackMoveClicked()
                }
                let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction, duplicateAction, renameAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { _ in
                    self.onTrackDeleteClicked()
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        }
        return nil
    }
}
