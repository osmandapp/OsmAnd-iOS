//
//  TracksViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 11/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

fileprivate class GpxFolder {
    var subfolders: [String : GpxFolder] = [:]
    var files: [String : OAGPX] = [:]
}

fileprivate enum SortingOptions {
    case name
    case lastModified
    case nearest
    case newestDateFirst
    case longestDistanceFirst
    case longestDurationFirst
}

class TracksViewController : OACompoundViewController, UITableViewDelegate, UITableViewDataSource {
    
    let visibleTracksKey = "visibleTracksKey"
    let tracksFolderKey = "tracksFolderKey"
    let trackKey = "trackKey"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var tableData = OATableDataModel()
    private var visibleTracksFolder = GpxFolder()
    fileprivate var allTracksFolder = GpxFolder()
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var folderName = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let title = folderName.length > 0 ? folderName : localizedString("menu_my_trips")
        tabBarController?.navigationItem.title = title
        navigationItem.title = title
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.navigationItem.searchController = nil
        let optionsButton = UIBarButtonItem(image: UIImage(named: "ic_navbar_overflow_menu_stroke.png"), style: .plain, target: self, action: #selector(onNavbarOptionsButtonClicked))
        optionsButton.accessibilityLabel = localizedString("shared_string_menu")
        navigationController?.navigationBar.topItem?.setRightBarButtonItems([optionsButton], animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        if (allTracksFolder.files.count == 0 && allTracksFolder.subfolders.count == 0) {
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
            visibleTracksRow.setObj(UIColor.iconColorActive, forKey: "color")
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
                folderRow.setObj(UIColor.iconColorSelected, forKey: "color")
                let tracksCount = calculateFolderTracksCount(folder)
                var descr = String(format: localizedString("folder_tracks_count"), tracksCount)
                folderRow.descr = descr
            }
        }
        
        var fileNames = Array(allTracksFolder.files.keys)
        fileNames = sortWithOptions(fileNames, options: .name)
        for fileName in fileNames {
            if let track = allTracksFolder.files[fileName] {
                var trackRow = section.createNewRow()
                trackRow.cellType = OARightIconTableViewCell.getIdentifier()
                trackRow.key = trackKey
                trackRow.title = fileName
                trackRow.iconName = "ic_custom_trip"
                trackRow.setObj(UIColor.iconColorDefault, forKey: "color")
                //trackRow.descr = descr
            }
        }
    }
    
    private func sortWithOptions(_ list: [String], options: SortingOptions) -> [String] {
        return list.sorted {$0 < $1}
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
                //add to track to root folder
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
                //add track file to last subfolder
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
    
    @objc func onNavbarOptionsButtonClicked() {
        print("onNavbarOptionsButtonClicked")
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
                if let color = item.obj(forKey: "color") as? UIColor {
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
    
}
