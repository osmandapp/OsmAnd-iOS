//
//  TracksViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 11/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

private protocol TrackListUpdatableDelegate: AnyObject {
    func updateHostVCWith(rootFolder: TrackFolder, visibleTracksFolder: TrackFolder)
}

private enum SortingOptions {
    case name
    case lastModified
    case nearest
    case newestDateFirst
    case longestDistanceFirst
    case longestDurationFirst
}

private enum ButtonActionNumberTag: Int {
    case startRecording
    case pause = 1
    case save = 2
}

final class TracksViewController: OACompoundViewController, UITableViewDelegate, UITableViewDataSource, OATrackSavingHelperUpdatableDelegate, TrackListUpdatableDelegate, OASelectTrackFolderDelegate, OAGPXImportUIHelperDelegate, MapSettingsGpxViewControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, FilterChangedListener {
    
    @IBOutlet private weak var tableView: UITableView!
    
    fileprivate var shouldReload = false
    
    fileprivate var rootFolder: TrackFolder!
    fileprivate var visibleTracksFolder: TrackFolder!
    fileprivate var currentFolder: TrackFolder!
    
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var currentFolderPath = ""   // in format: "rec/new folder"
    
    fileprivate weak var hostVCDelegate: TrackListUpdatableDelegate?
    
    private let visibleTracksKey = "visibleTracksKey"
    private let tracksFolderKey = "tracksFolderKey"
    private let trackKey = "trackKey"
    private let recordingTrackKey = "recordingTrackKey"
    private let tracksCountKey = "tracksCountKey"
    private let pathKey = "pathKey"
    private let fileNameKey = "filenameKey"
    private let colorKey = "colorKey"
    private let buttonTitleKey = "buttonTitleKey"
    private let buttonIconKey = "buttonIconKey"
    private let buttonActionNumberTagKey = "buttonActionNumberTagKey"
    private let secondButtonIconKey = "secondButtonIconKey"
    private let secondButtonActionNumberTagKey = "button2ActionNumberTagKey"
    private let isVisibleKey = "isVisibleKey"
    private let isFullWidthSeparatorKey = "isFullWidthSeparatorKey"
    
    private var tableData = OATableDataModel()
    private var asyncLoader: TrackFolderLoaderTask?
    
    private var recCell: OATwoButtonsTableViewCell?
    private var baseFilters: TracksSearchFilter?
    private var baseFiltersResult: FilterResults?
    private var searchController = UISearchController()
    private var isSearchActive = false
    private var isNameFiltered = false
    private var isSearchTextFilterChanged = false
    
    private var selectedTrack: GpxDataItem?
    private var selectedFolderPath: String?
    private var selectedTracks: [GpxDataItem] = []
    private var selectedFolders: [String] = []
    
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
    
    private lazy var filterButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 16
        config.imagePlacement = .trailing
        config.baseForegroundColor = .iconColorActive
        config.title = localizedString("filter_current_poiButton")
        let button = UIButton(configuration: config, primaryAction: nil)
        button.setImage(.icCustomFilter, for: .normal)
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
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
    
    private func onLoadFinished(folder: TrackFolder) {
        self.rootFolder = folder
        self.currentFolder = getTrackFolderByPath(currentFolderPath) ?? rootFolder
        onRefreshEnd()
        updateNavigationBarTitle()
        generateData()
        tableView.reloadData()
        setupTableFooter()
    }
    
    // MARK: - Base UI settings
    
    override func registerObservers() {
        addObserver(OAAutoObserverProxy(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackRecordingObservable))
        addObserver(OAAutoObserverProxy(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackStartStopRecObservable))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
        setupSearchController()
        if shouldReload {
            if let hostVCDelegate {
                hostVCDelegate.updateHostVCWith(rootFolder: rootFolder, visibleTracksFolder: visibleTracksFolder)
            }
            reloadTracks(forceLoad: true)
            shouldReload = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        addRefreshControl()
        reloadTracks(forceLoad: true)
        
        if isRootFolder && rootFolder.getTrackItems().isEmpty && rootFolder.getSubFolders().isEmpty {
            configureFolders()
        }
        
        tableView.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OATwoButtonsTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATwoButtonsTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OALargeImageTitleDescrTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.searchController = nil
    }
    
    private func reloadTracks(forceLoad: Bool = false) {
        if let asyncLoader {
            asyncLoader.cancel()
        }
        let file = KFile(filePath: OsmAndApp.swiftInstance().gpxPath)
        rootFolder = OsmAndShared.TrackFolder(dirFile: file, parentFolder: nil)
        
        let kotlinEmptyArray: KotlinArray<KotlinUnit> = [].toKotlinArray()
        
        asyncLoader = TrackFolderLoaderTask(folder: rootFolder, listener: self, forceLoad: forceLoad)
        asyncLoader?.execute(params: kotlinEmptyArray)
    }
    
    private func updateData() {
        generateData()
        tableView.reloadData()
        setupTableFooter()
    }
    
    private func updateAllFoldersVCData(forceLoad: Bool = false) {
        reloadTracks(forceLoad: forceLoad)

        if let hostVCDelegate {
            hostVCDelegate.updateHostVCWith(rootFolder: rootFolder, visibleTracksFolder: visibleTracksFolder)
        }
    }
    
    private func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        if isSearchActive {
            if var allTracks = baseFiltersResult?.values {
                allTracks.sort { $0.name.lastPathComponent() < $1.name.lastPathComponent() }
                allTracks.compactMap { $0.dataItem }.forEach { createRowFor(track: $0, section: section) }
            }
        } else {
            if !tableView.isEditing {
                if isRootFolder && iapHelper.trackRecording.isActive() {
                    if settings.mapSettingTrackRecording {
                        let currentRecordingTrackRow = section.createNewRow()
                        currentRecordingTrackRow.cellType = OATwoButtonsTableViewCell.reuseIdentifier
                        currentRecordingTrackRow.key = recordingTrackKey
                        currentRecordingTrackRow.title = localizedString("recorded_track")
                        currentRecordingTrackRow.descr = getTrackDescription(distance: savingHelper.distance, timeSpan: Int(savingHelper.currentTrack.getAnalysis(fileTimestamp: 0).timeSpan), waypoints: savingHelper.points, showDate: false, filepath: nil)
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
                            currentPausedTrackRow.descr = getTrackDescription(distance: savingHelper.distance, timeSpan: Int(savingHelper.currentTrack.getAnalysis(fileTimestamp: 0).timeSpan), waypoints: savingHelper.points, showDate: false, filepath: nil)
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
            }
            
            guard let currentTrackFolder = (isVisibleOnMapFolder ? visibleTracksFolder : getTrackFolderByPath(currentFolderPath)) else { return }
            
            if currentTrackFolder.getSubFolders().isEmpty && currentTrackFolder.getTrackItems().isEmpty && !tableView.isEditing {
                let emptyFolderBannerRow = section.createNewRow()
                emptyFolderBannerRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
                emptyFolderBannerRow.title = localizedString(isRootFolder ? "my_places_no_tracks_title_root" : "my_places_no_tracks_title")
                emptyFolderBannerRow.descr = localizedString(isRootFolder ? "my_places_no_tracks_descr_root" : "my_places_no_tracks_descr_root")
                emptyFolderBannerRow.iconName = "ic_custom_folder_open"
                emptyFolderBannerRow.iconTintColor = UIColor.iconColorSecondary
                emptyFolderBannerRow.setObj(localizedString("shared_string_import"), forKey: buttonTitleKey)
            } else {
                if isRootFolder && !tableView.isEditing {
                    let visibleTracksFolderRow = section.createNewRow()
                    visibleTracksFolderRow.cellType = OASimpleTableViewCell.reuseIdentifier
                    visibleTracksFolderRow.key = visibleTracksKey
                    visibleTracksFolderRow.title = localizedString("tracks_on_map")
                    visibleTracksFolderRow.iconName = "ic_custom_map_pin"
                    visibleTracksFolderRow.setObj(UIColor.iconColorActive, forKey: colorKey)
                    visibleTracksFolderRow.descr = String(format: localizedString("folder_tracks_count"), settings.mapSettingVisibleGpx.get().count)
                }
                
                var foldersNames: [String] = currentTrackFolder.getSubFolders().compactMap({ $0.getDirName() })
                foldersNames = sortWithOptions(foldersNames, options: .name)
                for folderName in foldersNames {
                    if let folder = currentTrackFolder.getSubFolders().first(where: { $0.getDirName() == folderName }) {
                        createRowFor(folder: folder, section: section)
                    }
                }
                
                var fileNames = currentTrackFolder.getTrackItems().compactMap({ $0.name })
                fileNames = sortWithOptions(fileNames, options: .name)
                for fileName in fileNames {
                    if let track = currentTrackFolder.getTrackItems().first(where: { $0.name == fileName }),
                       let trackItem = track.dataItem {
                        createRowFor(track: trackItem, section: section)
                    }
                }
            }
        }
        
        if section.rowCount() > 0 {
            let lastRow = section.getRow(section.rowCount() - 1)
            lastRow.setObj(true, forKey: isFullWidthSeparatorKey)
        }
    }
    
    fileprivate func createRowFor(folder: TrackFolder, section: OATableSectionData) {
        let folderRow = section.createNewRow()
        let folderName = folder.getDirName()
        folderRow.cellType = OASimpleTableViewCell.reuseIdentifier
        folderRow.key = tracksFolderKey
        folderRow.title = folderName
        folderRow.iconName = "ic_custom_folder"
        folderRow.setObj(UIColor.iconColorSelected, forKey: colorKey)
        folderRow.setObj(folder.relativePath, forKey: pathKey)
        let tracksCount = folder.totalTracksCount
        folderRow.setObj(tracksCount, forKey: tracksCountKey)
        let descr = String(format: localizedString("folder_tracks_count"), tracksCount)
        folderRow.descr = descr
        if let lastModifiedDate = OAUtilities.getFileLastModificationDate(currentFolderPath.appendingPathComponent(folderName)) {
            let lastModified = dateFormatter.string(from: lastModifiedDate)
            folderRow.descr = lastModified + " • " + descr
        }
    }
    
    fileprivate func createRowFor(track: GpxDataItem, section: OATableSectionData) {
        let trackRow = section.createNewRow()
        let fileName = track.gpxFileName
        trackRow.cellType = OASimpleTableViewCell.reuseIdentifier
        trackRow.key = trackKey
        trackRow.title = fileName.lastPathComponent().deletingPathExtension()
        trackRow.setObj(track.gpxFilePath as Any, forKey: pathKey)
        trackRow.setObj(fileName, forKey: fileNameKey)
        trackRow.iconName = "ic_custom_trip"

        let isVisible = settings.mapSettingVisibleGpx.contains(track.gpxFilePath)
        trackRow.setObj(isVisible, forKey: isVisibleKey)
        trackRow.setObj(isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault, forKey: colorKey)
        trackRow.descr = getTrackDescription(distance: track.totalDistance, timeSpan: track.timeSpan, waypoints: track.wptPoints, showDate: true, filepath: track.gpxFilePath)
    }
    
    private func getTrackDescription(distance: Float, timeSpan: Int, waypoints: Int32, showDate: Bool, filepath: String?) -> String {
        var result = ""
        if showDate {
            // TODO: can use fileLastModifiedTime from gpx object
            if let lastModifiedDate = OAUtilities.getFileLastModificationDate(filepath) {
                let lastModified = dateFormatter.string(from: lastModifiedDate)
                result += lastModified + " | "
            }
        }
        if let trackDistance = OAOsmAndFormatter.getFormattedDistance(distance) {
            result += trackDistance + " • "
        }
        if let trackDuration = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(timeSpan / 1000), shortFormat: true) {
            result += trackDuration + " • "
        }
        let waypointsCount = String(waypoints)
        result += waypointsCount
        return result
    }
    
    private func setupNavbar() {
        if tableView.isEditing {
            tabBarController?.navigationItem.hidesBackButton = true
            navigationItem.hidesBackButton = true
            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
            cancelButton.setImage(nil, for: .normal)
            cancelButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cancelButton.addTarget(self, action: #selector(onNavbarCancelButtonClicked), for: .touchUpInside)
            tabBarController?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        } else {
            tabBarController?.navigationItem.hidesBackButton = false
            tabBarController?.navigationItem.leftBarButtonItem = nil
            navigationItem.hidesBackButton = false
            navigationItem.leftBarButtonItem = nil
        }
        
        configureNavigationBarAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.navigationItem.searchController = nil
        navigationItem.searchController = nil
        setupNavBarMenuButton()
    }
    
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.navBarBgColorPrimary
        appearance.shadowColor = UIColor.navBarBgColorPrimary
        appearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.navBarTextColorPrimary]
        
        let blurAppearance = UINavigationBarAppearance()
        blurAppearance.backgroundEffect = UIBlurEffect(style: .regular)
        blurAppearance.backgroundColor = UIColor.navBarBgColorPrimary
        blurAppearance.shadowColor = UIColor.navBarBgColorPrimary
        blurAppearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.navBarTextColorPrimary]
        
        navigationController?.navigationBar.standardAppearance = blurAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor.navBarTextColorPrimary
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func updateNavigationBarTitle() {
        var title: String = currentFolder.getDirName()
        if tableView.isEditing {
            let totalSelectedTracks = selectedTracks.count
            let totalSelectedFolders = selectedFolders.count
            let totalSelectedItems = totalSelectedTracks + totalSelectedFolders
            if totalSelectedItems == 0 {
                title = localizedString("select_items")
            } else {
                let tracksInSelectedFolders = selectedFolders.reduce(0) { result, folderName -> Int in
                    if let folder = currentFolder.getFlattenedSubFolders().first(where: { $0.getDirName() == folderName }) {
                        return result + Int(folder.totalTracksCount)
                    }
                    return result
                }
                
                let totalTracks = totalSelectedTracks + tracksInSelectedFolders
                let itemText = localizedString("shared_string_item").lowercased()
                title = "\(totalSelectedItems) \(itemText)"
                if totalTracks > 0 {
                    title += " (\(String(format: localizedString("folder_tracks_count"), totalTracks)))"
                }
            }
        } else if isRootFolder {
            title = localizedString("menu_my_trips")
        } else if isVisibleOnMapFolder {
            title = localizedString("tracks_on_map")
        }
        
        tabBarController?.navigationItem.title = title
        navigationItem.title = title
    }
    
    private func setupNavBarMenuButton() {
        var menuActions: [UIMenuElement] = []
        if !tableView.isEditing {
            let selectAction = UIAction(title: localizedString("shared_string_select"), image: .icCustomSelectOutlined) { [weak self] _ in
                self?.onNavbarSelectButtonClicked()
            }
            let addFolderAction = UIAction(title: localizedString("add_folder"), image: .icCustomFolderAddOutlined) { [weak self] _ in
                self?.onNavbarAddFolderButtonClicked()
            }
            let importAction = UIAction(title: localizedString("shared_string_import"), image: .icCustomImportOutlined) { [weak self] _ in
                self?.onNavbarImportButtonClicked()
            }
            
            let selectActionWithDivider = UIMenu(title: "", options: .displayInline, children: [selectAction])
            let addFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: [addFolderAction])
            let importActionWithDivider = UIMenu(title: "", options: .displayInline, children: [importAction])
            menuActions.append(contentsOf: [selectActionWithDivider, addFolderActionWithDivider, importActionWithDivider])
        } else {
            let showOnMapAction = UIAction(title: localizedString("shared_string_show_on_map"), image: UIImage.icCustomMapPinOutlined) { [weak self] _ in
                self?.onNavbarShowOnMapButtonClicked()
            }
            let exportAction = UIAction(title: localizedString("shared_string_export"), image: UIImage.icCustomExportOutlined) { [weak self] _ in
                self?.onNavbarExportButtonClicked()
            }
            let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm_short"), image: UIImage.icCustomUploadToOpenstreetmapOutlined) { [weak self] _ in
                self?.onNavbarUploadToOsmButtonClicked()
            }
            let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                self?.onNavbarDeleteButtonClicked()
            }
            
            let mapTrackOptionsActions = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, exportAction, uploadToOsmAction])
            let deleteItemsActions = UIMenu(title: "", options: .displayInline, children: [deleteAction])
            menuActions.append(contentsOf: [mapTrackOptionsActions, deleteItemsActions])
        }
        
        let menu = UIMenu(title: "", image: nil, children: menuActions)
        if let navBarButton = OABaseNavbarViewController.createRightNavbarButton("", icon: UIImage.templateImageNamed("ic_navbar_overflow_menu_stroke.png"), color: UIColor.navBarTextColorPrimary, action: nil, target: self, menu: menu) {
            navigationController?.navigationBar.topItem?.setRightBarButtonItems([navBarButton], animated: false)
            navigationItem.setRightBarButtonItems([navBarButton], animated: false)
        }
    }
    
    private func setupHeaderView() -> UIView? {
        let headerView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.width, height: 44))
        headerView.backgroundColor = .groupBg
        headerView.addSubview(filterButton)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterButton.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor),
            filterButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            filterButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        return headerView
    }
    
    private func updateHeaderViewVisibility(searchIsActive: Bool) {
        tableView.tableHeaderView = searchIsActive ? setupHeaderView() : nil
    }
    
    private func updateFilterButtonTitle() {
        var baseTitle = localizedString("filter_current_poiButton")
        if let count = baseFilters?.getAppliedFiltersCount(), count > 0 {
            baseTitle += " (\(count))"
        }
        
        var currentConfig = filterButton.configuration ?? UIButton.Configuration.plain()
        currentConfig.title = baseTitle
        filterButton.configuration = currentConfig
    }
    
    private func setupTableFooter() {
        guard !currentFolder.getFlattenedTrackItems().isEmpty, !isSearchActive, !tableView.isEditing else {
            tableView.tableFooterView = nil
            return
        }
        
        if let footer = OAUtilities.setupTableHeaderView(withText: getTotalTracksStatistics(), font: UIFont.preferredFont(forTextStyle: .footnote), textColor: UIColor.textColorSecondary, isBigTitle: false, parentViewWidth: view.frame.width) {
            footer.backgroundColor = .groupBg
            for subview in footer.subviews {
                if let label = subview as? UILabel {
                    label.textAlignment = .center
                    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
            }
            
            tableView.tableFooterView = footer
        }
    }
    
    @objc private func filterButtonTapped() {
        guard let baseFilters, let baseFiltersResult else { return }
        let navigationController = UINavigationController(rootViewController: TracksFiltersViewController(baseFilters: baseFilters, baseFiltersResult: baseFiltersResult))
        navigationController.modalPresentationStyle = .custom
        present(navigationController, animated: true, completion: nil)
    }
    
    private func getTotalTracksStatistics() -> String {
        guard let folderAnalysis = getTrackFolderByPath(currentFolderPath)?.getFolderAnalysis() else {
            return ""
        }
        
        let totalDistance = folderAnalysis.totalDistance
        let totalUphill = folderAnalysis.diffElevationUp
        let totalDownhill = folderAnalysis.diffElevationDown
        let totalTime = folderAnalysis.timeSpan
        let totalSizeBytes = folderAnalysis.fileSize
        
        var statistics = "\(localizedString("shared_string_gpx_tracks")) – \(folderAnalysis.tracksCount)"
        if let distance = OAOsmAndFormatter.getFormattedDistance(totalDistance) {
            statistics += ", \(localizedString("shared_string_distance").lowercased()) – \(distance)"
        }
        if let uphill = OAOsmAndFormatter.getFormattedAlt(totalUphill) {
            statistics += ", \(localizedString("map_widget_trip_recording_uphill").lowercased()) – \(uphill)"
        }
        if let downhill = OAOsmAndFormatter.getFormattedAlt(totalDownhill) {
            statistics += ", \(localizedString("map_widget_trip_recording_downhill").lowercased()) – \(downhill)"
        }
        if let duration = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(totalTime), shortFormat: true) {
            statistics += ", \(localizedString("map_widget_trip_recording_duration").lowercased()) – \(duration)."
        }
        let size = ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
        statistics += "\n\n\(localizedString("shared_string_total_size")) – \(size)"
        return statistics
    }
    
    private func configureToolbar() {
        let buttonTitle = localizedString(areAllItemsSelected() ? "shared_string_deselect_all" : "shared_string_select_all")
        let selectDeselectButton = UIBarButtonItem(title: buttonTitle, style: .plain, target: self, action: #selector(onSelectDeselectAllButtonClicked))
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.iconColorActive]
        selectDeselectButton.setTitleTextAttributes(attributes, for: .normal)
        tabBarController?.toolbarItems = [selectDeselectButton]
        toolbarItems = [selectDeselectButton]
    }
    
    // #warning("implement sorting in next task")  // See: https://github.com/osmandapp/OsmAnd-Issues/issues/2348
    private func sortWithOptions(_ list: [String], options: SortingOptions) -> [String] {
        list.sorted { $0 < $1 }
    }
    
    private func showErrorAlert(_ text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func onRefreshEnd() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        tabBarController?.navigationItem.searchController = searchController
        navigationItem.searchController = searchController
        updateSearchController()
    }
    
    private func updateSearchController() {
        if isNameFiltered {
            searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("search_activity"), attributes: [NSAttributedString.Key.foregroundColor: UIColor.textColorTertiary])
            searchController.searchBar.searchTextField.backgroundColor = UIColor.groupBg
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor.textColorTertiary
        } else if isSearchActive {
            searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("search_activity"), attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1, alpha: 0.5)])
            searchController.searchBar.searchTextField.backgroundColor = UIColor(white: 1, alpha: 0.3)
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor(white: 1, alpha: 0.5)
        } else {
            searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("search_activity"), attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1, alpha: 0.5)])
            searchController.searchBar.searchTextField.backgroundColor = UIColor(white: 1, alpha: 0.3)
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor(white: 1, alpha: 0.5)
        }
    }
    
    @objc private func onRefresh() {
        reloadTracks(forceLoad: true)
    }
    
    // MARK: - Data
    
    private func configureFolders() {
        visibleTracksFolder = TrackFolder(trackFolder: rootFolder)
        currentFolder = getTrackFolderByPath(currentFolderPath) ?? rootFolder
    }
    
    private func getTrackFolderByPath(_ path: String) -> TrackFolder? {
        guard !path.isEmpty else {
            return rootFolder
        }
        return rootFolder.getFlattenedSubFolders().first(where: { $0.getDirFile().path().hasSuffix(path) }) ?? rootFolder
    }
    
    // MARK: - Navbar Toolbar Actions
    
    private func onNavbarSelectButtonClicked() {
        removeRefreshControl()
        tableView.setEditing(true, animated: false)
        tableView.allowsMultipleSelectionDuringEditing = true
        updateData()
        setupNavbar()
        tabBarController?.tabBar.isHidden = true
        tabBarController?.navigationController?.setToolbarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        configureToolbar()
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
    
    @objc private func onNavbarShowOnMapButtonClicked() {
        if hasSelectedItems() {
            var tracksToShow: [String] = []
            tracksToShow.append(contentsOf: selectedTracks.compactMap {
                settings.mapSettingVisibleGpx.contains($0.gpxFilePath) ? nil : $0.gpxFilePath
            })
            
            for folderName in selectedFolders {
                if let folder = currentFolder.getSubFolders().first(where: { $0.getName() == folderName }) {
                    let folderTracksToShow = folder.getTrackItems()
                        .compactMap {
                        settings.mapSettingVisibleGpx.contains($0.gpxFilePath) ? nil : $0.gpxFilePath
                    }
                    tracksToShow.append(contentsOf: folderTracksToShow)
                }
            }
            
            if !tracksToShow.isEmpty {
                settings.showGpx(tracksToShow, update: true)
            }
            
            updateAllFoldersVCData(forceLoad: true)
            onNavbarCancelButtonClicked()
        }
    }
    
    @objc private func onNavbarExportButtonClicked() {
        if hasSelectedItems() {
            var allExportFilePaths: [String] = []
            for folderName in selectedFolders {
                if let folder = currentFolder.getSubFolders().first(where: { $0.getDirName() == folderName }) {
                    let allTracksFilePaths = folder.getTrackItems()
                        .compactMap({ $0.gpxFilePath })
                        .map { OsmAndApp.swiftInstance().gpxPath.appendingPathComponent($0)
                    }
                    allExportFilePaths.append(contentsOf: allTracksFilePaths)
                }
            }
            
            allExportFilePaths.append(contentsOf: selectedTracks.map { OsmAndApp.swiftInstance().gpxPath.appendingPathComponent($0.gpxFilePath) })
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            onNavbarCancelButtonClicked()
            let exportVC = OAExportItemsViewController(tracks: allExportFilePaths)
            navigationController?.pushViewController(exportVC, animated: true)
        }
    }
    
    @objc private func onNavbarUploadToOsmButtonClicked() {
        if hasSelectedItems() {
            var allTracks: [GpxDataItem] = []
            allTracks.append(contentsOf: selectedTracks)
            for folderName in selectedFolders {
                if let folder = currentFolder.getSubFolders().first(where: { $0.getDirName() == folderName }) {
                    let tracks = folder.getTrackItems().compactMap({ $0.dataItem })
                    allTracks.append(contentsOf: tracks)
                }
            }
            
            onNavbarCancelButtonClicked()
            if !allTracks.isEmpty {
                let trackItems = allTracks.toTrackItems()
                show(OAOsmUploadGPXViewConroller(gpxItems: trackItems))
            }
        }
    }
    
    @objc private func onNavbarDeleteButtonClicked() {
        if hasSelectedItems() {
            let tracksInSelectedFolders = selectedFolders.reduce(0) { (result, folderName) -> Int in
                if let folder = currentFolder.getFlattenedSubFolders().first(where: { $0.getDirName() == folderName }) {
                    return result + Int(folder.totalTracksCount)
                }
                return result
            }
            
            let totalTracksToDelete = selectedTracks.count + tracksInSelectedFolders
            let tracksMessagePart = String(format: localizedString("folder_tracks_count"), totalTracksToDelete)
            let message = localizedString("delete_tracks_bottom_sheet_description_regular_part") + tracksMessagePart + "?"
            let alert = UIAlertController(title: localizedString("delete_tracks_bottom_sheet_title"), message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
                guard let self else { return }
                for folderName in self.selectedFolders {
                    self.deleteFolder(folderName)
                }
                
                for track in self.selectedTracks {
                    let isVisible = self.settings.mapSettingVisibleGpx.contains(track.gpxFilePath)
                    if isVisible {
                        self.settings.hideGpx([track.gpxFilePath])
                    }
                    self.gpxDB.removeGpxItem(track, withLocalRemove: true)
                }
                
                updateAllFoldersVCData(forceLoad: true)
                onNavbarCancelButtonClicked()
            })
            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            let popPresenter = alert.popoverPresentationController
            popPresenter?.barButtonItem = navigationItem.rightBarButtonItem
            popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any
            present(alert, animated: true)
        }
    }
    
    @objc private func onNavbarCancelButtonClicked() {
        selectedTracks.removeAll()
        selectedFolders.removeAll()
        addRefreshControl()
        tableView.setEditing(false, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = false
        updateData()
        setupNavbar()
        setupSearchController()
        tabBarController?.navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func onSelectDeselectAllButtonClicked() {
        if areAllItemsSelected() {
            selectedTracks.removeAll()
            selectedFolders.removeAll()
            for row in 0..<tableView.numberOfRows(inSection: 0) {
                tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
            }
        } else {
            guard let currentFolder = getTrackFolderByPath(currentFolderPath) else { return }
            let allFolders = currentFolder.getSubFolders()
            selectedFolders = allFolders.map { $0.getDirName() }
            selectedTracks = currentFolder.getTrackItems().compactMap({ $0.dataItem }).filter { track in
                !selectedFolders.contains(where: { folderName in
                    track.gpxFilePath.contains(folderName)
                })
            }
            
            for row in 0..<tableView.numberOfRows(inSection: 0) {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
            }
        }
        
        updateNavigationBarTitle()
        configureToolbar()
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
                    renameFolder(newName: newFolderName, oldName: oldFolderName)
                } else {
                    showErrorAlert(localizedString("incorrect_symbols"))
                }
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func onFolderExportButtonClicked(_ selectedFolderName: String) {
        guard let selectedFolder = currentFolder.getSubFolders().first(where: { $0.getDirName() == selectedFolderName }) else { return }
        let exportFilePaths = selectedFolder.getTrackItems().compactMap({ $0.path })
        let state = OATrackMenuViewControllerState()
        state.openedFromTracksList = true
        let vc = OAExportItemsViewController(tracks: exportFilePaths)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func onFolderMoveButtonClicked(_ destinationFolderName: String) {
        var trimmedPath = currentFolderPath.hasPrefix("/") ? currentFolderPath.substring(from: 1) : currentFolderPath
        trimmedPath = trimmedPath.appendingPathComponent(destinationFolderName)
        selectedFolderPath = trimmedPath
        let selectedFolderName = trimmedPath.deletingLastPathComponent()
        // hide from this screen moving folder and all it's subfolders, to deny move folder inside itself
        if let vc = OASelectTrackFolderViewController(selectedFolderName: selectedFolderName, excludedSubfolderPath: trimmedPath) {
            vc.delegate = self
            let navController = UINavigationController(rootViewController: vc)
            present(navController, animated: true)
        }
    }
    
    private func onFolderDeleteButtonClicked(folderName: String, tracksCount: Int) {
        let message = String(format: localizedString("remove_folder_with_files_descr"), arguments: [folderName, tracksCount])
        let alert = UIAlertController(title: localizedString("delete_folder"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            self?.deleteFolder(folderName)
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
        updateAllFoldersVCData(forceLoad: true)
    }
    
    private func onTrackAppearenceClicked(track: TrackItem?, isCurrentTrack: Bool) {
        var trackItem = track
        if trackItem == nil, let gpxFile = savingHelper.currentTrack {
            trackItem = TrackItem(gpxFile: gpxFile)
        }
        guard let trackItem else { return }
        
        if let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty {
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            state.gpxFilePath = trackItem.dataItem?.gpxFilePath
            state.navControllerHistory = newCurrentHistory
            rootVC.mapPanel.openTargetView(withGPX: trackItem, trackHudMode: .appearanceHudMode, state: state)
            shouldReload = true
        }
    }
    
    private func onTrackNavigationClicked(_ track: TrackItem?, isCurrentTrack: Bool) {
        var trackItem = track
        if trackItem == nil, let gpxFile = savingHelper.currentTrack {
            trackItem = TrackItem(gpxFile: gpxFile)
        }
        guard let trackItem else { return }
        
        var totalTracks = 0
        if trackItem.isShowCurrentTrack {
            let analysis = savingHelper.currentTrack.getAnalysis(fileTimestamp: 0)
            totalTracks = Int(analysis.totalTracks)
        } else {
            if let dataItem = trackItem.dataItem {
                totalTracks = dataItem.totalTracks
            }
        }
        if totalTracks > 1 {
            let absolutePath = getAbsolutePath(trackItem.gpxFilePath)
            if let vc = OATrackSegmentsViewController(filepath: absolutePath, isCurrentTrack: isCurrentTrack) {
                vc.startNavigationOnSelect = true
                rootVC.present(vc, animated: true)
                navigationController?.popToRootViewController(animated: true)
            }
        } else {
            if routingHelper.isFollowingMode() {
                rootVC.mapPanel.mapActions.stopNavigationActionConfirm()
            }
            rootVC.mapPanel.mapActions.enterRoutePlanningMode(givenGpx: trackItem, useIntermediatePointsByDefault: true, showDialog: true)
            navigationController?.popToRootViewController(animated: true)
        }
        shouldReload = true
    }
    
    private func onTrackAnalyzeClicked(_ track: TrackItem?, isCurrentTrack: Bool) {
        var trackItem = track
        if trackItem == nil, let gpxFile = savingHelper.currentTrack {
            trackItem = TrackItem(gpxFile: gpxFile)
        }
        guard let trackItem else { return }
        
        if let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty {
            let state = OATrackMenuViewControllerState()
            state.navControllerHistory = newCurrentHistory
            state.openedFromTracksList = true
            state.selectedStatisticsTab = .overviewTab
            navigationController?.setNavigationBarHidden(true, animated: true)
            rootVC.mapPanel.openNewTargetViewFromTracksList(withRouteDetailsGraph: trackItem, state: state)
        }
    }
    
    private func onTrackShareClicked(_ track: TrackItem?, isCurrentTrack: Bool, touchPointArea: CGRect) {
        var trackItem = track
        if trackItem == nil, let gpxFile = savingHelper.currentTrack {
            trackItem = TrackItem(gpxFile: gpxFile)
        }
        guard let trackItem else { return }
        
        gpxHelper.openExport(forTrack: trackItem.dataItem, gpxDoc: nil, isCurrentTrack: isCurrentTrack, in: self, hostViewControllerDelegate: self, touchPointArea: touchPointArea)
    }
    
    private func onTrackUploadToOsmClicked(_ track: TrackItem?) {
        var trackItem = track
        if trackItem == nil, let gpxFile = savingHelper.currentTrack {
            trackItem = TrackItem(gpxFile: gpxFile)
        }
        guard let trackItem else { return }
        
        show(OAOsmUploadGPXViewConroller(gpxItems: [trackItem]))
    }
    
    private func onTrackEditClicked(_ track: TrackItem?) {
        guard let track else { return }
        
        if let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty {
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            state.gpxFilePath = track.gpxFilePath
            state.navControllerHistory = newCurrentHistory
            if let vc = OARoutePlanningHudViewController(fileName: track.gpxFilePath, targetMenuState: state, adjustMapPosition: false) {
                rootVC.mapPanel.showScrollableHudViewController(vc)
            }
        }
    }
    
    private func onTrackDuplicateClicked(track: TrackItem?) {
        guard let track else { return }
        gpxHelper.copyGPX(toNewFolder: currentFolderPath,
                          renameToNewName: track.gpxFileName,
                          deleteOriginalFile: false,
                          openTrack: false,
                          trackItem: track)
        selectedTrack = nil
        updateAllFoldersVCData(forceLoad: true)
    }
    
    private func onTrackRenameClicked(_ track: TrackItem?) {
        var trackItem = track
        if trackItem == nil, let gpxFile = savingHelper.currentTrack {
            trackItem = TrackItem(gpxFile: gpxFile)
        }
        guard let trackItem else { return }
        let gpxFilename = trackItem.gpxFileName.lastPathComponent().deletingPathExtension()
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
                gpxHelper.renameTrack(trackItem.dataItem, newName: newNameToChange, hostVC: self)
                self.updateAllFoldersVCData(forceLoad: true)
            } else {
                gpxHelper.renameTrack(nil, doc: nil, newName: nil, hostVC: self)
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func onTrackMoveClicked(_ trackItem: TrackItem?, isCurrentTrack: Bool) {
        guard let trackItem else { return }
        
        selectedTrack = trackItem.dataItem
        if let vc = OASelectTrackFolderViewController(selectedFolderName: trackItem.gpxFolderName) {
            vc.delegate = self
            let navController = UINavigationController(rootViewController: vc)
            present(navController, animated: true)
        }
    }
    
    private func onTrackDeleteClicked(trackItem: TrackItem?) {
        guard let trackItem else { return }
        let message = trackItem.isShowCurrentTrack ? localizedString("track_clear_q") : localizedString("gpx_remove")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_yes"), style: .default) { [weak self] _ in
            guard let self else { return }
            if trackItem.isShowCurrentTrack {
                settings.mapSettingTrackRecording = false
                savingHelper.clearData()
                DispatchQueue.main.async { [weak self] in
                    self?.rootVC.mapPanel.mapViewController.hideRecGpxTrack()
                }
                updateData()
            } else {
                guard let dataItem = trackItem.dataItem else { return }
                let isVisible = settings.mapSettingVisibleGpx.contains(trackItem.gpxFilePath)
                if isVisible {
                    settings.hideGpx([trackItem.gpxFilePath])
                }
                gpxDB.removeGpxItem(dataItem, withLocalRemove: true)
                updateAllFoldersVCData(forceLoad: true)
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
            let bottomSheet = OARecordSettingsBottomSheetViewController { [weak self] _, rememberChoice, showOnMap in
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
                updateAllFoldersVCData(forceLoad: true)
            } catch let error {
                debugPrint(error)
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func updateMovedGpxFiles(files: [KFile], srcDir: KFile, destDir: KFile) {
        for srcFile in files {
            let path = srcFile.absolutePath()
            let newPath = path.replacingOccurrences(of: srcDir.absolutePath(), with: destDir.absolutePath())
            
            let destFile = KFile(filePath: newPath)
            if destFile.exists() {
                updateRenamedGpx(src: srcFile, dest: destFile)
            }
        }
    }
    
    private func updateRenamedGpx(src: KFile, dest: KFile) {
        GpxDbHelper.shared.rename(currentFile: src, newFile: dest)
        /*
         GpxSelectionHelper gpxSelectionHelper = app.getSelectedGpxHelper();
             SelectedGpxFile selectedGpxFile = gpxSelectionHelper.getSelectedFileByPath(src.getAbsolutePath());
             if (selectedGpxFile != null) {
                 gpxFile = selectedGpxFile.getGpxFile();
                 gpxFile.setPath(dest.getAbsolutePath());
                 gpxSelectionHelper.updateSelectedGpxFile(selectedGpxFile);
                 GpxDisplayHelper gpxDisplayHelper = app.getGpxDisplayHelper();
                 gpxDisplayHelper.updateDisplayGroupsNames(selectedGpxFile);
             }
             updateGpxMetadata(gpxFile, dest);
         */
    }
    
    private func renameFolder(newName: String, oldName: String) {
        guard let trackFolder = getTrackFolderByPath(oldName) else { return }
        let oldFolderPath = currentFolderAbsolutePath().appendingPathComponent(oldName)
        let newFolderPath = currentFolderAbsolutePath().appendingPathComponent(newName)
        
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            let oldDir = KFile(filePath: oldFolderPath)
            if let parentFile = oldDir.getParentFile() {
                let newDir = KFile(file: parentFile, fileName: newName)
                if oldDir.renameTo(toFile: newDir) {
                    trackFolder.setDirFile(dirFile: newDir)
                    trackFolder.resetCachedData()
                    
                    var files = [KFile]()

                    for trackItem in trackFolder.getFlattenedTrackItems() {
                        if let file = trackItem.getFile() {
                            files.append(file)
                        }
                    }
                    if !files.isEmpty {
                        updateMovedGpxFiles(files: files, srcDir: oldDir, destDir: newDir)
                        if let gpxPath = OsmAndApp.swiftInstance().gpxPath {
                            let gpxPathRemovePrefix = gpxPath + "/"
                            let oldPath = oldFolderPath.removePrefix(gpxPathRemovePrefix)
                            let newPath = newFolderPath.removePrefix(gpxPathRemovePrefix)
                            renameVisibleTracks(oldPath: oldPath, newPath: newPath)
                        }
                    }
                    updateAllFoldersVCData(forceLoad: true)
                }
            } else {
                NSLog("renameFolder -> parentFile is empty")
            }
        } else {
            showErrorAlert(localizedString("folder_already_exsists"))
        }
    }
    
    private func deleteFolder(_ folderName: String) {
        let folderPath = currentFolderAbsolutePath().appendingPathComponent(folderName)
        do {
            if let folderForDelete = currentFolder.getSubFolders().first(where: { $0.getDirName() == folderName }) {
                let tracksItems: [GpxDataItem] = folderForDelete.getFlattenedTrackItems().compactMap({ $0.dataItem })
                if !tracksItems.isEmpty {
                    tracksItems.forEach({
                        gpxDB.removeGpxItem($0, withLocalRemove: false)
                        let gpxFilePath = $0.gpxFilePath
                        let isVisible = settings.mapSettingVisibleGpx.contains(gpxFilePath)
                        if isVisible {
                            settings.hideGpx([gpxFilePath])
                        }
                    })
                }
            }
            // remove folders with tracks
            try FileManager.default.removeItem(atPath: folderPath)
            updateAllFoldersVCData(forceLoad: true)
        } catch let error {
            debugPrint(error)
        }
    }
    
    private func moveFile(selectedFolderName: String) {
        guard let selectedTrack else { return }
        let trackItem = TrackItem(file: selectedTrack.file)
        trackItem.dataItem = selectedTrack
        
        gpxHelper.copyGPX(toNewFolder: selectedFolderName,
                          renameToNewName: nil,
                          deleteOriginalFile: true,
                          openTrack: false,
                          trackItem: trackItem)
        updateAllFoldersVCData(forceLoad: true)
    }
    
    private func renameVisibleTracks(oldPath: String, newPath: String) {
        guard var visibleGpx = settings.mapSettingVisibleGpx.get() else { return }
        
        visibleGpx = visibleGpx.map { filePath in filePath.replacingOccurrences(of: oldPath, with: newPath) }
        settings.mapSettingVisibleGpx.set(visibleGpx)
    }
    
    private func moveFolder(folderPathForOpenedContextMenu: String, selectedFolderName: String) {
        let sourceFolderPath = getAbsolutePath(folderPathForOpenedContextMenu)
        let destinationShortFolderPath = (selectedFolderName == localizedString("shared_string_gpx_tracks") ? "" : selectedFolderName).appendingPathComponent(sourceFolderPath.lastPathComponent())
        let destinationFolderPath = getAbsolutePath(destinationShortFolderPath)
        
        guard let trackFolder = getTrackFolderByPath(folderPathForOpenedContextMenu) else { return }
        
        let src: KFile = KFile(filePath: sourceFolderPath)
        let dest: KFile = KFile(filePath: destinationFolderPath)
    
        if src.renameTo(toFilePath: dest.absolutePath()) {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: destinationFolderPath)
            let tracksItems = trackFolder.getFlattenedTrackItems()
            let files = tracksItems.compactMap { $0.getFile() }

            if !files.isEmpty {
                updateMovedGpxFiles(files: files, srcDir: src, destDir: dest)
                
                if let gpxPath = OsmAndApp.swiftInstance().gpxPath {
                    let gpxPathRemovePrefix = gpxPath + "/"
                    let oldPath = src.absolutePath().removePrefix(gpxPathRemovePrefix)
                    let newPath = dest.absolutePath().removePrefix(gpxPathRemovePrefix)
                    renameVisibleTracks(oldPath: oldPath, newPath: newPath)
                }
            }
        }
    
        updateAllFoldersVCData(forceLoad: true)
    }
   
    private func areAllItemsSelected() -> Bool {
        guard let currentFolder = getTrackFolderByPath(currentFolderPath) else { return false }
        let allDisplayedTracks = currentFolder.getTrackItems().compactMap { $0.dataItem }
        let allDisplayedFolders = currentFolder.getSubFolders()
        let allTracksSelected = allDisplayedTracks.allSatisfy { track in
            if selectedTracks.contains(track) {
                return true
            }
            
            return selectedFolders.contains { folderName -> Bool in
                let folderPath = currentFolder.relativePath.appendingPathComponent(folderName)
                let trackPath = track.gpxFilePath.deletingLastPathComponent()
                return trackPath.hasPrefix(folderPath)
            }
        }
        
        let allFoldersSelected = allDisplayedFolders.allSatisfy { folder in
            selectedFolders.contains(folder.relativePath.lastPathComponent())
        }
        
        return allTracksSelected && allFoldersSelected
    }
    
    private func hasSelectedItems() -> Bool {
        !selectedFolders.isEmpty || !selectedTracks.isEmpty
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
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as? OAButtonTableViewCell
            if let cell {
                cell.leftIconView.contentMode = .center
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = .zero
                
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named: iconName)
                    cell.leftIconView.tintColor = UIColor.iconColorDefault
                }
                
                cell.button.layer.cornerRadius = 9
                cell.button.configuration = getRecButtonConfig()
                cell.button.backgroundColor = UIColor.contextMenuButtonBg
                if let buttonTitle = item.string(forKey: buttonTitleKey) {
                    cell.button.setTitle(buttonTitle, for: .normal)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: OATwoButtonsTableViewCell.reuseIdentifier) as? OATwoButtonsTableViewCell
            if let cell {
                cell.leftIconView.contentMode = .center
                cell.leftButton.configuration = getRecButtonConfig()
                cell.rightButton.configuration = getRecButtonConfig()
                cell.leftButton.layer.cornerRadius = 9
                cell.rightButton.layer.cornerRadius = 9
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = .zero
                
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named: iconName)
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
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as? OASimpleTableViewCell
            if let cell {
                cell.selectionStyle = tableView.isEditing ? .default : .none
                cell.selectedBackgroundView = UIView()
                cell.selectedBackgroundView?.backgroundColor = .groupBg
                cell.titleLabel.textColor = UIColor.textColorPrimary
                cell.descriptionLabel.textColor = UIColor.textColorSecondary
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                cell.accessoryType = tableView.isEditing ? .none : .disclosureIndicator
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                if let color = item.obj(forKey: colorKey) as? UIColor {
                    cell.leftIconView.tintColor = color
                }
                
                cell.setCustomLeftSeparatorInset(false)
                if item.obj(forKey: isFullWidthSeparatorKey) as? Bool ?? false {
                    cell.setCustomLeftSeparatorInset(true)
                    cell.separatorInset = .zero
                }
                outCell = cell
            }
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier) as? OALargeImageTitleDescrTableViewCell
            if let cell = cell {
                cell.selectionStyle = .none
                cell.separatorInset = .zero
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
    
    private func getRecButtonConfig() -> UIButton.Configuration {
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7)
        buttonConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .footnote)
            return outgoing
        }
        return buttonConfig
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if tableView.isEditing {
            if item.key == trackKey {
                if let trackPath = item.obj(forKey: pathKey) as? String,
                   let track = rootFolder.getTrackItems().compactMap({ $0.dataItem }).first(where: { $0.gpxFilePath == trackPath }) {
                    if !selectedTracks.contains(track) {
                        selectedTracks.append(track)
                    }
                }
            } else if item.key == tracksFolderKey {
                let folderName = item.title ?? ""
                if !selectedFolders.contains(folderName) {
                    selectedFolders.append(folderName)
                }
            }
            updateNavigationBarTitle()
            configureToolbar()
        } else {
            if item.key == visibleTracksKey {
                if let vc = MapSettingsGpxViewController() {
                    vc.delegate = self
                    show(vc)
                }
            } else if item.key == tracksFolderKey {
                if let subfolderPath = item.obj(forKey: pathKey) as? String {
                    let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
                        if let subfolder = currentFolder.getSubFolders().first(where: {
                            $0.getDirFile().path().hasSuffix(subfolderPath)
                        }) {
                            vc.currentFolder = subfolder
                            vc.currentFolderPath = subfolderPath
                            vc.rootFolder = rootFolder
                            vc.visibleTracksFolder = visibleTracksFolder
                            vc.isRootFolder = false
                            vc.hostVCDelegate = self
                            show(vc)
                        }
                    }
                }
            } else if item.key == trackKey {
                if let trackPath = item.obj(forKey: pathKey) as? String,
                   let track = currentFolder.getTrackItems().first(where: { $0.gpxFilePath == trackPath }),
                   let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty {
                    OARootViewController.instance().mapPanel.openTargetViewWithGPX(fromTracksList: track,
                                                                                   navControllerHistory: newCurrentHistory,
                                                                                   fromTrackMenu: false,
                                                                                   selectedTab: .overviewTab)
                    shouldReload = true
                }
            } else if item.key == recordingTrackKey {
                if savingHelper.hasData() {
                    rootVC.mapPanel.openRecordingTrackTargetView()
                    rootVC.navigationController?.popToRootViewController(animated: true)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if tableView.isEditing {
            if item.key == trackKey {
                if let trackPath = item.obj(forKey: pathKey) as? String,
                   let track = currentFolder.getTrackItems().compactMap({ $0.dataItem }).first(where: { $0.gpxFilePath == trackPath }),
                   let index = selectedTracks.firstIndex(of: track) {
                    selectedTracks.remove(at: index)
                }
            } else if item.key == tracksFolderKey {
                let folderName = item.title ?? ""
                if let index = selectedFolders.firstIndex(of: folderName) {
                    selectedFolders.remove(at: index)
                }
            }
            updateNavigationBarTitle()
            configureToolbar()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.key == tracksFolderKey {
            
            let selectedFolderName = item.title ?? ""
            
            let menuProvider: UIContextMenuActionProvider = { _ in
                
                // TODO: implement Folder Details in next task   https://github.com/osmandapp/OsmAnd-Issues/issues/2348
                // let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { [weak self] _ in
                //     self?.onFolderDetailsButtonClicked()
                // }
                // let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [detailsAction])
                
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit) { [weak self] _ in
                    self?.onFolderRenameButtonClicked(selectedFolderName)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction])
                
                let exportAction = UIAction(title: localizedString("shared_string_export"), image: UIImage.icCustomExportOutlined) { [weak self] _ in
                    guard let self else { return }
                    self.onFolderExportButtonClicked(selectedFolderName)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined) { [weak self] _ in
                    self?.onFolderMoveButtonClicked(selectedFolderName)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [exportAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                    guard let self else { return }
                    
                    let folderTracksCount = item.integer(forKey: self.tracksCountKey)
                    self.onFolderDeleteButtonClicked(folderName: selectedFolderName, tracksCount: folderTracksCount)
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [secondButtonsSection, thirdButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        } else if item.key == trackKey || item.key == recordingTrackKey {
            let isCurrentTrack = item.key == recordingTrackKey
            if isCurrentTrack && !savingHelper.hasData() {
                return nil
            }
            let isTrackVisible = item.bool(forKey: isVisibleKey)
            let selectedTrackPath = item.string(forKey: self.pathKey) ?? ""
            let selectedTrackFilename = item.string(forKey: self.fileNameKey) ?? ""
            
            let track = getTrackFolderByPath(currentFolderPath)?
                .getTrackItems()
                .first(where: { $0.gpxFileName == selectedTrackFilename })
            
            let menuProvider: UIContextMenuActionProvider = { _ in
                
                let showOnMapAction = UIAction(title: localizedString(isTrackVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: UIImage.icCustomMapPinOutlined) { [weak self] _ in
                    self?.onTrackShowOnMapClicked(trackPath: selectedTrackPath, isVisible: isTrackVisible, isCurrentTrack: isCurrentTrack)
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: UIImage.icCustomAppearanceOutlined) { [weak self] _ in
                    self?.onTrackAppearenceClicked(track: track, isCurrentTrack: isCurrentTrack)
                }
                let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: UIImage.icCustomNavigationOutlined) { [weak self] _ in
                    self?.onTrackNavigationClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, appearenceAction, navigationAction])
                
                let analyzeAction = UIAction(title: localizedString("gpx_analyze"), image: UIImage.icCustomGraph) { [weak self] _ in
                    self?.onTrackAnalyzeClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [analyzeAction])
                
                let shareAction = UIAction(title: localizedString("shared_string_share"), image: UIImage.icCustomExportOutlined) { [weak self] _ in
                    guard let self else { return }
                    let cellScreenArea = self.view.convert(self.tableView.rectForRow(at: indexPath), from: self.tableView)
                    self.onTrackShareClicked(track, isCurrentTrack: isCurrentTrack, touchPointArea: cellScreenArea)
                }
                let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm_short"), image: UIImage.icCustomUploadToOpenstreetmapOutlined) { [weak self] _ in
                    self?.onTrackUploadToOsmClicked(track)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [shareAction, uploadToOsmAction])
                
                let editAction = UIAction(title: localizedString("shared_string_edit"), image: UIImage.icCustomTrackEdit, attributes: isCurrentTrack ? .disabled : []) { [weak self] _ in
                    self?.onTrackEditClicked(track)
                }
                let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: UIImage.icCustomCopy, attributes: isCurrentTrack ? .disabled : []) { [weak self] _ in
                    self?.onTrackDuplicateClicked(track: track)
                }
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: UIImage.icCustomEdit, attributes: isCurrentTrack ? .disabled : []) { [weak self] _ in
                    self?.onTrackRenameClicked(track)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: UIImage.icCustomFolderMoveOutlined, attributes: isCurrentTrack ? .disabled : []) { [weak self] _ in
                    self?.onTrackMoveClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction, duplicateAction, renameAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage.icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                    self?.onTrackDeleteClicked(trackItem: track)
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [firstButtonsSection, secondButtonsSection, thirdButtonsSection, fourthButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        }
        return nil
    }
    
    // MARK: - TrackListUpdatableDelegate
    
    fileprivate func updateHostVCWith(rootFolder: TrackFolder, visibleTracksFolder: TrackFolder) {
        self.rootFolder = rootFolder
        self.visibleTracksFolder = visibleTracksFolder
        shouldReload = true
        if let hostVCDelegate {
            hostVCDelegate.updateHostVCWith(rootFolder: rootFolder, visibleTracksFolder: visibleTracksFolder)
        }
    }
    
    // MARK: - OATrackSavingHelperUpdatableDelegate
    
    func onNeedUpdateHostData() {
        updateAllFoldersVCData(forceLoad: true)
    }
    
    // MARK: - OASelectTrackFolderDelegate
    
    func onFolderSelected(_ selectedFolderName: String?) {
        if let selectedFolderName {
            if selectedTrack != nil {
                moveFile(selectedFolderName: selectedFolderName)
            } else if let selectedFolderPath {
                moveFolder(folderPathForOpenedContextMenu: selectedFolderPath, selectedFolderName: selectedFolderName)
            }
        }
        selectedTrack = nil
        selectedFolderPath = nil
    }
    
    func onFolderAdded(_ addedFolderName: String) {
        let newFolderPath = getAbsolutePath(addedFolderName)
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                updateAllFoldersVCData(forceLoad: true)
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func onFolderSelectCancelled() {
        selectedFolderPath = nil
        selectedTrack = nil
    }
    
    // MARK: - FilterChangedListener
    
    func onFilterChanged() {
        DispatchQueue.main.async {
            if let baseFilters = self.baseFilters {
                self.baseFiltersResult?.values = baseFilters.getFilteredTrackItems()
                self.isSearchTextFilterChanged = true
                self.searchController.searchBar.text = (baseFilters.getFilterByType(.name) as? TextTrackFilter)?.value
                self.isNameFiltered = !(self.searchController.searchBar.text?.isEmpty ?? true)
                self.updateSearchController()
                self.generateData()
                self.tableView.reloadData()
                self.updateFilterButtonTitle()
            }
        }
    }
    
    // MARK: - OAGPXImportUIHelperDelegate
    
    func updateVCData() {
        updateAllFoldersVCData(forceLoad: true)
    }
    
    // MARK: - MapSettingsGpxViewControllerDelegate
    
    func onVisibleTracksUpdate() {
        updateAllFoldersVCData(forceLoad: true)
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        if isSearchTextFilterChanged {
            isSearchTextFilterChanged = false
            return
        }
        
        if searchController.isActive && searchController.searchBar.searchTextField.text?.length == 0 {
            isSearchActive = true
            isNameFiltered = false
            baseFilters = TracksSearchFilter(trackItems: rootFolder.getFlattenedTrackItems(), currentFolder: nil)
            baseFilters?.addFiltersChangedListener(self)
        } else if searchController.isActive && !(searchController.searchBar.searchTextField.text ?? "").isEmpty {
            isSearchActive = true
            isNameFiltered = true
            (baseFilters?.getFilterByType(.name) as? TextTrackFilter)?.value = searchController.searchBar.searchTextField.text ?? ""
        } else {
            isSearchActive = false
            isNameFiltered = false
        }
        updateSearchController()
        updateHeaderViewVisibility(searchIsActive: isSearchActive)
        baseFiltersResult = baseFilters?.performFiltering()
        updateData()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        isNameFiltered = false
        updateSearchController()
        updateHeaderViewVisibility(searchIsActive: isSearchActive)
    }
}

// MARK: - UIRefreshControl

extension TracksViewController {
    private func addRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
    }
    
    private func removeRefreshControl() {
        tableView.refreshControl = nil
    }
}

// MARK: - TrackFolderLoaderTaskLoadTracksListener

extension TracksViewController: TrackFolderLoaderTaskLoadTracksListener {
    func loadTracksProgress(items: KotlinArray<TrackItem>) {
        debugPrint("function: \(#function)")
    }
    
    func loadTracksStarted() {
        debugPrint("function: \(#function)")
    }
    
    func deferredLoadTracksFinished(folder: TrackFolder) {
        debugPrint("function: \(#function)")
        onLoadFinished(folder: folder)
    }
    
    func loadTracksFinished(folder: TrackFolder) {
        debugPrint("function: \(#function)")
        onLoadFinished(folder: folder)
    }
    
    func tracksLoaded(folder: TrackFolder) {
        debugPrint("function: \(#function)")
    }
}
