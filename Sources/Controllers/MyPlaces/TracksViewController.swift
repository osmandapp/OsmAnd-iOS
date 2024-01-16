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
    private let colorKey = "colorKey"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var tableData = OATableDataModel()
    private var visibleTracksFolder = GpxFolder()
    fileprivate var allTracksFolder = GpxFolder()
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var folderName = ""
    fileprivate var currentSubfolderPath = ""   // in format: "rec/new folder/"
    
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
        if allTracksFolder.files.count == 0 && allTracksFolder.subfolders.count == 0 {
            buildFilesTree()
        }
        generateData()
    }
    
    private func generateData() {
        tableData.clearAllData()
        var section = tableData.createNewSection()
        
        if isRootFolder {
            var visibleTracksRow = section.createNewRow()
            visibleTracksRow.cellType = OARightIconTableViewCell.getIdentifier()
            visibleTracksRow.key = visibleTracksKey
            visibleTracksRow.title = localizedString("tracks_on_map")
            visibleTracksRow.iconName = "ic_custom_map_pin"
            visibleTracksRow.setObj(UIColor.iconColorActive, forKey: colorKey)
            var descr = String(format: localizedString("folder_tracks_count"), visibleTracksFolder.files.count)
            visibleTracksRow.descr = descr
        }
        
        var folderNames = Array(allTracksFolder.subfolders.keys)
        folderNames = sortWithOptions(folderNames, options: .name)
        for folderName in folderNames {
            if let folder = allTracksFolder.subfolders[folderName] {
                var folderRow = section.createNewRow()
                folderRow.cellType = OARightIconTableViewCell.getIdentifier()
                folderRow.key = tracksFolderKey
                folderRow.title = folderName
                folderRow.iconName = "ic_custom_folder"
                folderRow.setObj(UIColor.iconColorSelected, forKey: colorKey)
                let tracksCount = calculateFolderTracksCount(folder)
                var descr = String(format: localizedString("folder_tracks_count"), tracksCount)
                folderRow.descr = descr
                if let lastModifiedDate = OAUtilities.getFileLastModificationDate(currentSubfolderPath + folderName) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy"
                    let lastModified = dateFormatter.string(from: lastModifiedDate)
                    folderRow.descr = lastModified + " • " + descr
                }
            }
        }
        
        var fileNames = Array(allTracksFolder.files.keys)
        fileNames = sortWithOptions(fileNames, options: .name)
        for fileName in fileNames {
            if let track = allTracksFolder.files[fileName] {
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
    
    // MARK: - Data
    
    private func buildFilesTree() {
        guard let db = OAGPXDatabase.sharedDb() else {return}
        guard let allTracks = db.gpxList as? [OAGPX] else {return}
        guard let visibleTrackPatches = OAAppSettings.sharedManager().mapSettingVisibleGpx else {return}
        
        visibleTracksFolder = GpxFolder()
        allTracksFolder = GpxFolder()
        
        for track in allTracks {
            if visibleTrackPatches.contains(track.gpxFilePath) {
                visibleTracksFolder.files[track.gpxFilePath] = track
            }
            
            let pathComponents = track.gpxFilePath.split(separator: "/")
            if pathComponents.count == 1 {
                // add to track to root folder
                allTracksFolder.files[track.gpxFilePath] = track
            } else {
                // create all needed subfolders
                var i = 0
                var currentFolder = allTracksFolder
                while i < pathComponents.count - 1 {
                    var folderName = String(pathComponents[i])
                    if currentFolder.subfolders[folderName] == nil {
                        currentFolder.subfolders[folderName] = GpxFolder()
                    }
                    if let nextSubfolder = currentFolder.subfolders[folderName] {
                        currentFolder = nextSubfolder
                    }
                    i += 1
                }
                // add track file to last subfolder
                if let filename = pathComponents.last {
                    currentFolder.files[String(filename)] = track
                }
            }
        }
    }
    
    private func calculateFolderTracksCount(_ folder: GpxFolder) -> Int {
        var count = folder.files.count
        for subfolder in folder.subfolders.values {
            count += calculateFolderTracksCount(subfolder)
        }
        return count
    }
    
    // MARK: - Actions
    
    @objc private func onNavbarOptionsButtonClicked() {
        // Do nothing
    }
    
    private func onNavbarSelectButtonClicked() {
        print("onNavbarOptionsButtonClicked")
    }
    
    private func onNavbarAddFolderButtonClicked() {
        print("onNavbarAddFolderButtonClicked")
    }
    
    private func onNavbarImportButtonClicked() {
        print("onNavbarImportButtonClicked")
    }
    
    private func onFolderDetailsButtonClicked() {
        print("onFolderDetailsButtonClicked")
    }
    
    private func onFolderRenameButtonClicked() {
        print("onFolderRenameButtonClicked")
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
    
    private func onFolderDeleteButtonClicked() {
        print("onFolderDeleteButtonClicked")
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
        }
        
        return outCell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == visibleTracksKey {
            let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
                vc.allTracksFolder = visibleTracksFolder
                vc.folderName = localizedString("tracks_on_map")
                vc.isRootFolder = false
                vc.isVisibleOnMapFolder = true
                show(vc)
            }
        } else if item.key == tracksFolderKey {
            if let subfolderName = item.title {
                if let subfolder = allTracksFolder.subfolders[subfolderName] {
                    let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
                        vc.allTracksFolder = subfolder
                        vc.folderName = subfolderName
                        vc.currentSubfolderPath = currentSubfolderPath + subfolderName + "/"
                        vc.isRootFolder = false
                        show(vc)
                    }
                }
            }
        } else if item.key == trackKey {
            if let filename = item.title {
                if let track = allTracksFolder.files[filename] {
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
                    self.onFolderRenameButtonClicked()
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
                    self.onFolderDeleteButtonClicked()
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
