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

private enum ButtonActionNumberTag: Int {
    case startRecording
    case pause = 1
    case save = 2
}

final class TracksViewController: OACompoundViewController, UITableViewDelegate, UITableViewDataSource, OATrackSavingHelperUpdatableDelegate, TrackListUpdatableDelegate, OASelectTrackFolderDelegate, MapSettingsGpxViewControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, FilterChangedListener {
    
    @IBOutlet private weak var tableView: UITableView!
    
    fileprivate var shouldReload = false
    
    fileprivate var rootFolder: TrackFolder!
    fileprivate var visibleTracksFolder: TrackFolder!
    fileprivate var currentFolder: TrackFolder!
    fileprivate var smartFolder: SmartFolder!
    
    fileprivate var isRootFolder = true
    fileprivate var isVisibleOnMapFolder = false
    fileprivate var isSmartFolder = false
    fileprivate var currentFolderPath = ""   // in format: "rec/new folder"
    
    fileprivate weak var hostVCDelegate: TrackListUpdatableDelegate?
    // TODO: Keys to enums
    private let visibleTracksKey = "visibleTracksKey"
    private let tracksFolderKey = "tracksFolderKey"
    private let tracksSmartFolderKey = "tracksSmartFolderKey"
    private let emptyFilterFolderKey = "emptyFilterFolderKey"
    private let emptySmartFolderKey = "emptySmartFolderKey"
    private let trackKey = "trackKey"
    private let recordingTrackKey = "recordingTrackKey"
    private let tracksCountKey = "tracksCountKey"
    private let pathKey = "pathKey"
    private let trackObjectKey = "trackObjectKey"
    private let fileNameKey = "filenameKey"
    private let colorKey = "colorKey"
    private let buttonTitleKey = "buttonTitleKey"
    private let buttonIconKey = "buttonIconKey"
    private let buttonActionNumberTagKey = "buttonActionNumberTagKey"
    private let secondButtonIconKey = "secondButtonIconKey"
    private let secondButtonActionNumberTagKey = "button2ActionNumberTagKey"
    private let isVisibleKey = "isVisibleKey"
    private let isFullWidthSeparatorKey = "isFullWidthSeparatorKey"
    private let trackSortDescrKey = "trackSortDescrKey"
    
    private var tableData = OATableDataModel()
    private var asyncLoader: TrackFolderLoaderTask?
    
    private var recCell: OATwoButtonsTableViewCell?
    private var baseFilters: TracksSearchFilter?
    private var baseFiltersResult: FilterResults?
    private var sortMode: TracksSortMode = .lastModified
    private var sortModeForSearch: TracksSortMode = .lastModified
    private var searchController = UISearchController()
    private var lastUpdate: TimeInterval?
    private var isSearchActive = false
    private var isNameFiltered = false
    private var isFiltersInitialized = false
    private var isSearchTextFilterChanged = false
    private var isSelectionModeInSearch = false
    private var isEditFilterActive = false
    private var shouldReloadTableView = false
    private var isContextMenuVisible = false
    
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
    private var smartFolderHelper: SmartFolderHelper
    
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
    
    private lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 16
        config.imagePlacement = .leading
        config.baseForegroundColor = .iconColorActive
        let button = UIButton(configuration: config, primaryAction: nil)
        button.setImage(sortMode.image, for: .normal)
        button.menu = createSortMenu(isSortingSubfolders: false)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.contentHorizontalAlignment = .left
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
        smartFolderHelper = SharedLibSmartFolderHelper.shared
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        importHelper = OAGPXImportUIHelper()
        super.init(coder: coder)
        importHelper = OAGPXImportUIHelper(hostViewController: self)
    }
    
    private func onLoadFinished(folder: TrackFolder) {
        rootFolder = folder
        currentFolder = getTrackFolderByPath(currentFolderPath) ?? rootFolder
        onRefreshEnd()
        updateSearchResultsWithFilteredTracks()
        updateData()
    }
    
    // MARK: - Base UI settings
    
    override func registerObservers() {
        addObserver(OAAutoObserverProxy(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackRecordingObservable))
        addObserver(OAAutoObserverProxy(self, withHandler: #selector(onObservedRecordedTrackChanged), andObserve: app.trackStartStopRecObservable))
        addNotification(NSNotification.Name.OAGPXImportUIHelperDidFinishImport, selector: #selector(didFinishImport))
        let updateDistanceAndDirectionSelector = #selector(updateDistanceAndDirection as () -> Void)
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateLocationObserver))
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateHeadingObserver))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
        updateNavigationBarTitle()
        tableView.tableHeaderView = setupHeaderView()
        filterButton.isHidden = true
        if shouldReload {
            updateAllFoldersVCData(forceLoad: true)
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
        
        sortMode = getTracksSortMode()
        sortModeForSearch = getSearchTracksSortMode()
        tableView.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OATwoButtonsTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATwoButtonsTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OALargeImageTitleDescrTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupSearchController()
        reloadTableViewOnAppearIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let asyncLoader {
            asyncLoader.cancel()
        }
        tabBarController?.navigationItem.searchController = nil
        navigationItem.searchController = nil
        super.viewWillDisappear(animated)
    }
    
    private func reloadTableViewOnAppearIfNeeded() {
        guard shouldReloadTableView else { return }
        generateData()
        tableView.reloadData()
        shouldReloadTableView = false
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
        (smartFolderHelper.getSmartFolders() as? [SmartFolder])?.forEach { smartFolderHelper.refreshSmartFolder(smartFolder: $0) }
        reloadTracks(forceLoad: forceLoad)

        if let hostVCDelegate {
            hostVCDelegate.updateHostVCWith(rootFolder: rootFolder, visibleTracksFolder: visibleTracksFolder)
        }
    }
    
    private func updateSearchResultsWithFilteredTracks() {
        guard isSearchActive else { return }
        baseFilters?.updateFilteredTracks(newTracks: rootFolder.getFlattenedTrackItems())
        baseFiltersResult = baseFilters?.performFiltering()
    }
    
    private func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        if isSearchActive || isSelectionModeInSearch || isEditFilterActive {
            if let allTracks = baseFiltersResult?.values ?? (isSmartFolder ? smartFolder?.getTrackItems() : nil) {
                if allTracks.isEmpty {
                    let emptyFilterBannerRow = section.createNewRow()
                    emptyFilterBannerRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
                    emptyFilterBannerRow.key = emptyFilterFolderKey
                    emptyFilterBannerRow.title = localizedString("no_matched_tracks")
                    emptyFilterBannerRow.descr = localizedString("no_matched_tracks_descr")
                    emptyFilterBannerRow.iconName = "ic_custom_search"
                    emptyFilterBannerRow.iconTintColor = .iconColorSecondary
                } else {
                    let gpxItems = allTracks.compactMap { $0.dataItem }
                    let sortedTracks = TracksSortModeHelper.sortTracksWithMode(gpxItems, mode: isEditFilterActive ? sortMode : sortModeForSearch)
                    sortedTracks.forEach { createRowFor(track: $0, section: section) }
                }
            }
        } else {
            if !tableView.isEditing {
                if isRootFolder && iapHelper.trackRecording.isActive() {
                    if settings.mapSettingTrackRecording {
                        let currentRecordingTrackRow = section.createNewRow()
                        currentRecordingTrackRow.cellType = OATwoButtonsTableViewCell.reuseIdentifier
                        currentRecordingTrackRow.key = recordingTrackKey
                        currentRecordingTrackRow.title = localizedString("recorded_track")
                        currentRecordingTrackRow.descr = OAGPXUIHelper.getGPXStatisticString(for: nil,
                                                                                             totalDistance: savingHelper.distance,
                                                                                             timeSpan: Int(savingHelper.currentTrack.getAnalysis(fileTimestamp: 0).timeSpan),
                                                                                             wptPoints: savingHelper.points)
                        let isVisible = settings.mapSettingShowRecordingTrack.get()
                        currentRecordingTrackRow.setObj(isVisible, forKey: isVisibleKey)
                        currentRecordingTrackRow.iconName = "ic_custom_track_recordable"
                        currentRecordingTrackRow.iconTintColor = isVisible ? .iconColorActive : .iconColorDefault
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
                            currentPausedTrackRow.descr = OAGPXUIHelper.getGPXStatisticString(for: nil,
                                                                                              totalDistance: savingHelper.distance,
                                                                                              timeSpan: Int(savingHelper.currentTrack.getAnalysis(fileTimestamp: 0).timeSpan), wptPoints: savingHelper.points)
                            let isVisible = settings.mapSettingShowRecordingTrack.get()
                            currentPausedTrackRow.setObj(isVisible, forKey: isVisibleKey)
                            currentPausedTrackRow.iconName = "ic_custom_track_recordable"
                            currentPausedTrackRow.iconTintColor = isVisible ? .iconColorActive : .iconColorDefault
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
                            recordNewTrackRow.iconTintColor = .iconColorDefault
                            recordNewTrackRow.setObj(localizedString("start_recording"), forKey: buttonTitleKey)
                            recordNewTrackRow.setObj(localizedString("ic_custom_play"), forKey: buttonIconKey)
                            recordNewTrackRow.setObj(ButtonActionNumberTag.startRecording.rawValue, forKey: buttonActionNumberTagKey)
                            let isVisible = settings.mapSettingShowRecordingTrack.get()
                            recordNewTrackRow.setObj(isVisible, forKey: isVisibleKey)
                            recordNewTrackRow.setObj(isVisible ? .iconColorActive : UIColor.iconColorDefault, forKey: colorKey)
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
                emptyFolderBannerRow.iconTintColor = .iconColorSecondary
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
                
                if !isSmartFolder {
                    let trackFolders: [TrackFolder] = currentTrackFolder.getSubFolders()
                    let smartFolders: [SmartFolder] = isRootFolder ? (smartFolderHelper.getSmartFolders() as! [SmartFolder]) : []
                    let allFolders: [SortableFolder] = trackFolders + smartFolders
                    let sortedFolders = TracksSortModeHelper.sortFoldersWithMode(allFolders, mode: sortMode)
                    for folder in sortedFolders {
                        createRowFor(folder: folder, section: section)
                    }
                }
                
                let gpxItems = isSmartFolder ? smartFolder.getTrackItems().compactMap { $0.dataItem } : currentTrackFolder.getTrackItems().compactMap { $0.dataItem }
                if isSmartFolder && !isEditFilterActive && gpxItems.isEmpty {
                    let emptySmartFolderBannerRow = section.createNewRow()
                    emptySmartFolderBannerRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
                    emptySmartFolderBannerRow.key = emptySmartFolderKey
                    emptySmartFolderBannerRow.title = localizedString("empty_smart_folder_title")
                    emptySmartFolderBannerRow.descr = localizedString("empty_smart_folder_descr")
                    emptySmartFolderBannerRow.iconName = "ic_custom_folder_open"
                    emptySmartFolderBannerRow.iconTintColor = .iconColorSecondary
                    emptySmartFolderBannerRow.setObj(localizedString("edit_filter"), forKey: buttonTitleKey)
                } else {
                    let sortedTracks = TracksSortModeHelper.sortTracksWithMode(gpxItems, mode: sortMode)
                    for trackItem in sortedTracks {
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
    
    fileprivate func createRowFor(folder: SortableFolder, section: OATableSectionData) {
        let folderRow = section.createNewRow()
        let folderName = folder.getDirName(includingSubdirs: false)
        folderRow.cellType = OASimpleTableViewCell.reuseIdentifier
        folderRow.title = folderName
        folderRow.setObj(UIColor.iconColorSelected, forKey: colorKey)
        if let trackFolder = folder as? TrackFolder {
            folderRow.key = tracksFolderKey
            folderRow.setObj(trackFolder.relativePath, forKey: pathKey)
            folderRow.iconName = "ic_custom_folder"
            let tracksCount = trackFolder.totalTracksCount
            folderRow.setObj(tracksCount, forKey: tracksCountKey)
            folderRow.descr = TracksSortModeHelper.descriptionForFolder(folder: trackFolder, currentFolderPath: currentFolderPath)
        } else if let smartFolder = folder as? SmartFolder {
            folderRow.key = tracksSmartFolderKey
            folderRow.iconName = "ic_custom_folder_smart"
            let tracksCount = smartFolder.getTrackItems().count
            folderRow.setObj(tracksCount, forKey: tracksCountKey)
            folderRow.descr = String(format: localizedString("folder_tracks_count"), tracksCount)
        }
    }
    
    fileprivate func createRowFor(track: GpxDataItem, section: OATableSectionData) {
        let trackRow = section.createNewRow()
        let fileName = track.gpxFileName
        
        trackRow.cellType = OASimpleTableViewCell.reuseIdentifier
        trackRow.key = trackKey
        trackRow.title = fileName.lastPathComponent().deletingPathExtension()
        trackRow.setObj(track, forKey: trackObjectKey)
        trackRow.setObj(track.gpxFilePath as Any, forKey: pathKey)
        trackRow.setObj(fileName, forKey: fileNameKey)
        trackRow.iconName = "ic_custom_trip"
        let isVisible = settings.mapSettingVisibleGpx.contains(track.gpxFilePath)
        trackRow.setObj(isVisible, forKey: isVisibleKey)
        trackRow.setObj(isVisible ? UIColor.iconColorActive : UIColor.iconColorDefault, forKey: colorKey)
        trackRow.setObj(TracksSortModeHelper.getTrackDescription(track: track, sortMode: isSearchActive || isSelectionModeInSearch ? sortModeForSearch : sortMode, includeFolderInfo: false), forKey: trackSortDescrKey)
    }
    
    private func setupNavbar() {
        if tableView.isEditing {
            tabBarController?.navigationItem.hidesBackButton = true
            navigationItem.hidesBackButton = true
            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
            cancelButton.setImage(nil, for: .normal)
            cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
            cancelButton.addTarget(self, action: #selector(onNavbarCancelButtonClicked), for: .touchUpInside)
            tabBarController?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        } else if isEditFilterActive {
            tabBarController?.navigationItem.hidesBackButton = true
            navigationItem.hidesBackButton = true
            let editFilterCancelButton = UIButton(type: .system)
            editFilterCancelButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
            editFilterCancelButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
            editFilterCancelButton.addTarget(self, action: #selector(onNavbarEditFilterCancelButtonClicked), for: .touchUpInside)
            tabBarController?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: editFilterCancelButton)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: editFilterCancelButton)
            let doneButton = UIButton(type: .system)
            doneButton.setTitle(localizedString("shared_string_done"), for: .normal)
            doneButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
            doneButton.addTarget(self, action: #selector(onNavbarDoneButtonClicked), for: .touchUpInside)
            tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButton)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButton)
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
        if !isEditFilterActive {
            setupNavBarMenuButton()
        }
    }
    
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .navBarBgColorPrimary
        appearance.shadowColor = .navBarBgColorPrimary
        appearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.navBarTextColorPrimary]
        
        let blurAppearance = UINavigationBarAppearance()
        blurAppearance.backgroundEffect = UIBlurEffect(style: .regular)
        blurAppearance.backgroundColor = .navBarBgColorPrimary
        blurAppearance.shadowColor = .navBarBgColorPrimary
        blurAppearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.navBarTextColorPrimary]
        
        navigationController?.navigationBar.standardAppearance = blurAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .navBarTextColorPrimary
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func updateNavigationBarTitle() {
        var title: String = currentFolder?.getDirName(includingSubdirs: false) ?? localizedString("menu_my_trips")
        if tableView.isEditing {
            let totalSelectedTracks = selectedTracks.count
            let totalSelectedFolders = selectedFolders.count
            let totalSelectedItems = totalSelectedTracks + totalSelectedFolders
            if totalSelectedItems == 0 {
                title = localizedString("select_items")
            } else {
                let tracksInSelectedFolders = selectedFolders.reduce(0) { result, folderName -> Int in
                    if let folder = currentFolder.getFlattenedSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
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
        } else if isSmartFolder {
            title = isEditFilterActive ? localizedString("edit_filter") : smartFolder.getDirName(includingSubdirs: false)
        }
        
        tabBarController?.navigationItem.title = title
        navigationItem.title = title
    }
    
    private func setupNavBarMenuButton() {
        var menuActions: [UIMenuElement] = []
        if !tableView.isEditing {
            if isSmartFolder {
                let selectSmartFolderAction = UIAction(title: localizedString("shared_string_select"), image: .icCustomSelectOutlined) { [weak self] _ in
                    self?.onNavbarSelectButtonClicked()
                }
                let refreshSmartFolderAction = UIAction(title: localizedString("shared_string_refresh"), image: .icCustomUpdate) { [weak self] _ in
                    self?.onNavbarRefreshSmartFolderButtonClicked()
                }
                let editFilterSmartFolderAction = UIAction(title: localizedString("edit_filter"), image: .icCustomParameters) { [weak self] _ in
                    self?.onNavbarEditFilterSmartFolderButtonClicked()
                }
                let selectSmartFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: [selectSmartFolderAction])
                let refreshSmartFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: [refreshSmartFolderAction])
                let editFilterSmartFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: [editFilterSmartFolderAction])
                menuActions.append(contentsOf: [selectSmartFolderActionWithDivider, refreshSmartFolderActionWithDivider, editFilterSmartFolderActionWithDivider])
            } else {
                let selectAction = UIAction(title: localizedString("shared_string_select"), image: .icCustomSelectOutlined) { [weak self] _ in
                    self?.onNavbarSelectButtonClicked()
                }
                let addFolderAction = UIAction(title: localizedString("add_folder"), image: .icCustomFolderAddOutlined) { [weak self] _ in
                    self?.onNavbarAddFolderButtonClicked()
                }
                var addSmartFolderAction: UIAction?
                if isRootFolder {
                    addSmartFolderAction = UIAction(title: localizedString("add_smart_folder"), image: .icCustomFolderSmartOutlined) { [weak self] _ in
                        self?.onNavbarAddSmartFolderButtonClicked()
                    }
                }
                var folderActions: [UIAction] = [addFolderAction]
                if let smartAction = addSmartFolderAction {
                    folderActions.append(smartAction)
                }
                let importAction = UIAction(title: localizedString("shared_string_import"), image: .icCustomImportOutlined) { [weak self] _ in
                    self?.onNavbarImportButtonClicked()
                }
                let sortSubfoldersActions = createSortMenu(isSortingSubfolders: true)
                
                let selectActionWithDivider = UIMenu(title: "", options: .displayInline, children: [selectAction])
                let addFolderActionWithDivider = UIMenu(title: "", options: .displayInline, children: folderActions)
                let importActionWithDivider = UIMenu(title: "", options: .displayInline, children: [importAction])
                let sortSubfoldersActionWithDivider = UIMenu(title: "", options: .displayInline, children: [sortSubfoldersActions])
                menuActions.append(contentsOf: [selectActionWithDivider, addFolderActionWithDivider, importActionWithDivider, sortSubfoldersActionWithDivider])
            }
        } else {
            let showOnMapAction = UIAction(title: localizedString("shared_string_show_on_map"), image: .icCustomMapPinOutlined) { [weak self] _ in
                self?.onNavbarShowOnMapButtonClicked()
            }
            let exportAction = UIAction(title: localizedString("shared_string_export"), image: .icCustomExportOutlined) { [weak self] _ in
                self?.onNavbarExportButtonClicked()
            }
            let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm_short"), image: .icCustomUploadToOpenstreetmapOutlined) { [weak self] _ in
                self?.onNavbarUploadToOsmButtonClicked()
            }
            let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { [weak self] _ in
                self?.onNavbarMoveButtonClicked()
            }
            let changeAppearanceAction = UIAction(title: localizedString("change_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
                self?.onNavbarChangeAppearanceButtonClicked()
            }
            let changeActivityAction = UIAction(title: localizedString("change_activity"), image: .icCustomActivityOutlined) { [weak self] _ in
                self?.onNavbarChangeActivityButtonClicked()
            }
            let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                self?.onNavbarDeleteButtonClicked()
            }
            
            let mapTrackOptionsActions = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, exportAction, uploadToOsmAction])
            let moveItemsActions = UIMenu(title: "", options: .displayInline, children: [moveAction])
            let changeAppearanceItemsActions = UIMenu(title: "", options: .displayInline, children: [changeAppearanceAction, changeActivityAction])
            let deleteItemsActions = UIMenu(title: "", options: .displayInline, children: [deleteAction])
            menuActions.append(contentsOf: [mapTrackOptionsActions, moveItemsActions, changeAppearanceItemsActions, deleteItemsActions])
        }
        
        let menu = UIMenu(title: "", image: nil, children: menuActions)
        if let navBarButton = OABaseNavbarViewController.createRightNavbarButton("", icon: UIImage.templateImageNamed("ic_navbar_overflow_menu_stroke.png"), color: .navBarTextColorPrimary, action: nil, target: self, menu: menu) {
            navigationController?.navigationBar.topItem?.setRightBarButtonItems([navBarButton], animated: false)
            navigationItem.setRightBarButtonItems([navBarButton], animated: false)
        }
    }
    
    private func setupHeaderView() -> UIView? {
        let headerView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.width, height: 44))
        headerView.backgroundColor = .groupBg
        headerView.addSubview(filterButton)
        headerView.addSubview(sortButton)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterButton.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor),
            filterButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            filterButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            sortButton.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            sortButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            sortButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            sortButton.trailingAnchor.constraint(lessThanOrEqualTo: filterButton.leadingAnchor)
        ])
        
        return headerView
    }
    
    private func updateFilterButtonVisibility(filterIsActive: Bool) {
        filterButton.isHidden = !filterIsActive
    }
    
    private func updateFilterButton() {
        var baseTitle = localizedString("filter_current_poiButton")
        var baseIcon: UIImage = .icCustomFilter
        if let count = isEditFilterActive ? smartFolder.filters?.count : baseFilters?.getAppliedFiltersCount(), count > 0 {
            baseTitle += " (\(count))"
            baseIcon = .icCustomFilterFilled
        }
        
        var currentConfig = filterButton.configuration ?? UIButton.Configuration.plain()
        currentConfig.title = baseTitle
        filterButton.setImage(baseIcon, for: .normal)
        filterButton.configuration = currentConfig
    }
    
    private func setTracksSortMode(_ sortMode: TracksSortMode, isSortingSubfolders: Bool) {
        var sortModes = settings.getTracksSortModes()
        if isSmartFolder, let smartFolder = smartFolder {
            sortModes[smartFolder.getId()] = sortMode.title
        } else if let folder = currentFolder {
            if !isSortingSubfolders {
                sortModes[folder.relativePath] = sortMode.title
            } else {
                let subFolders = folder.getFlattenedSubFolders()
                for subFolder in subFolders {
                    sortModes[subFolder.relativePath] = sortMode.title
                }
            }
        }
        
        settings.saveTracksSortModes(sortModes)
    }
    
    private func setSearchTracksSortMode(_ sortMode: TracksSortMode) {
        settings.searchTracksSortModes.set(sortMode.title)
    }
    
    private func getTracksSortMode() -> TracksSortMode {
        let sortModes = settings.getTracksSortModes()
        if isSmartFolder, let smartFolder {
            if let sortModeTitle = sortModes[smartFolder.getId()] {
                return TracksSortMode.getByTitle(sortModeTitle)
            }
        } else if let folderName = currentFolder?.relativePath, let sortModeTitle = sortModes[folderName] {
            return TracksSortMode.getByTitle(sortModeTitle)
        }
        
        return TracksSortModeHelper.getDefaultSortMode(for: currentFolder.getId())
    }
    
    private func getSearchTracksSortMode() -> TracksSortMode {
        let searchSortModeTitle = settings.searchTracksSortModes.get()
        return TracksSortMode.getByTitle(searchSortModeTitle)
    }
    
    private func setupTableFooter() {
        guard !currentFolder.getFlattenedTrackItems().isEmpty, !isSearchActive, !tableView.isEditing, !isEditFilterActive, !(isSmartFolder && smartFolder.getTrackItems().isEmpty) else {
            tableView.tableFooterView = nil
            return
        }
        
        let footer = OAUtilities.setupTableHeaderView(withText: getTotalTracksStatistics(), font: .preferredFont(forTextStyle: .footnote), textColor: .textColorSecondary, isBigTitle: false, parentViewWidth: view.frame.width)
        footer.backgroundColor = .groupBg
        for subview in footer.subviews {
            if let label = subview as? UILabel {
                label.textAlignment = .center
                label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
        }
        
        tableView.tableFooterView = footer
    }
    
    @objc private func filterButtonTapped() {
        if isEditFilterActive {
            baseFilters = TracksSearchFilter(trackItems: Array(smartFolderHelper.getAllAvailableTrackItems()).compactMap { $0 as? TrackItem }, initialFilters: smartFolder.filters ?? [])
            TracksSearchFilter.setRootFolder(rootFolder)
            baseFilters?.addFiltersChangedListener(self)
            baseFiltersResult = baseFilters?.performFiltering()
            isFiltersInitialized = true
        }
        
        guard let baseFilters, let baseFiltersResult else { return }
        let navigationController = UINavigationController(rootViewController: TracksFiltersViewController(baseFilters: baseFilters, baseFiltersResult: baseFiltersResult, smartFolder: isEditFilterActive ? smartFolder : nil))
        navigationController.modalPresentationStyle = .custom
        present(navigationController, animated: true, completion: nil)
    }
    
    private func getTotalTracksStatistics() -> String {
        let folderAnalysis: TrackFolderAnalysis
        if isSmartFolder {
            guard let smartFolder = smartFolder else { return "" }
            folderAnalysis = smartFolder.getFolderAnalysis()
        } else {
            guard let analysis = getTrackFolderByPath(currentFolderPath)?.getFolderAnalysis() else { return "" }
            folderAnalysis = analysis
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
        let title = localizedString(isSearchActive ? "shared_string_select" : (areAllItemsSelected() ? "shared_string_deselect_all" : "shared_string_select_all"))
        let action = isSearchActive ? #selector(onSelectToolbarButtonClicked) : #selector(onSelectDeselectAllButtonClicked)
        configureToolbar(withTitle: title, action: action)
    }
    
    private func configureToolbarForeSmartFolders() {
        let title = localizedString("shared_string_reset_all")
        let action = #selector(onResetToolbarButtonClicked)
        configureToolbar(withTitle: title, action: action)
    }
    
    private func configureToolbar(withTitle title: String, action: Selector) {
        let selectDeselectButton = UIBarButtonItem(title: title, style: .plain, target: self, action: action)
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.iconColorActive]
        selectDeselectButton.setTitleTextAttributes(attributes, for: .normal)
        tabBarController?.toolbarItems = [selectDeselectButton]
        toolbarItems = [selectDeselectButton]
    }
    
    private func updateDistanceAndDirection(_ forceUpdate: Bool) {
        if isContextMenuVisible {
            shouldReloadTableView = true
            return
        }

        let currentSortMode = isSearchActive || isSelectionModeInSearch ? sortModeForSearch : sortMode
        guard currentSortMode == .nearest, forceUpdate || Date.now.timeIntervalSince1970 - (lastUpdate ?? 0) >= 0.5 else {
            return
        }
        
        lastUpdate = Date.now.timeIntervalSince1970
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard view.window != nil else {
                shouldReloadTableView = true
                return
            }
            updateData()
        }
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
            searchController.searchBar.searchTextField.backgroundColor = .groupBg
            searchController.searchBar.searchTextField.leftView?.tintColor = .textColorTertiary
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
    
    @objc private func updateDistanceAndDirection() {
        updateDistanceAndDirection(false)
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
    
    private func onNavbarRefreshSmartFolderButtonClicked() {
        smartFolderHelper.refreshSmartFolder(smartFolder: smartFolder)
        reloadTracks(forceLoad: true)
    }
    
    @objc private func onNavbarEditFilterSmartFolderButtonClicked() {
        isEditFilterActive = true
        setupNavbar()
        updateNavigationBarTitle()
        updateFilterButtonVisibility(filterIsActive: true)
        updateFilterButton()
        updateData()
        tabBarController?.tabBar.isHidden = true
        tabBarController?.navigationController?.setToolbarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        configureToolbarForeSmartFolders()
        setupTableFooter()
    }
    
    private func onNavbarSelectButtonClicked() {
        removeRefreshControl()
        tableView.setEditing(true, animated: false)
        tableView.allowsMultipleSelectionDuringEditing = true
        updateData()
        setupNavbar()
        updateNavigationBarTitle()
        if !isSelectionModeInSearch {
            tabBarController?.tabBar.isHidden = true
            tabBarController?.navigationController?.setToolbarHidden(false, animated: true)
            navigationController?.setToolbarHidden(false, animated: true)
        }

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
    
    private func onNavbarAddSmartFolderButtonClicked() {
        let alert = UIAlertController(title: localizedString("add_smart_folder"), message: localizedString("access_hint_enter_name"), preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: localizedString("shared_string_add"), style: .default) { [weak self] _ in
            guard let self else { return }
            if let folderName = alert.textFields?.first?.text {
                if folderName.isEmpty {
                    OAUtilities.showToast(localizedString("empty_name"), details: nil, duration: 4, verticalOffset: 120, in: self.view)
                } else if smartFolderHelper.isSmartFolderPresent(name: folderName) {
                    OAUtilities.showToast(localizedString("smart_folder_name_present"), details: nil, duration: 4, verticalOffset: 120, in: self.view)
                } else {
                    smartFolderHelper.saveNewSmartFolder(name: folderName, filters: nil)
                    updateAllFoldersVCData(forceLoad: true)
                    shouldReload = true
                    showTracksViewControllerForSmartFolder(withName: folderName)
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
                    let folderTracksToShow = folder.getFlattenedTrackItems().compactMap { settings.mapSettingVisibleGpx.contains($0.gpxFilePath) ? nil : $0.gpxFilePath }
                    tracksToShow.append(contentsOf: folderTracksToShow)
                } else if let smartFolder = smartFolderHelper.getSmartFolder(name: folderName) {
                    let folderTracksToShow = smartFolder.getTrackItems().compactMap { settings.mapSettingVisibleGpx.contains($0.gpxFilePath) ? nil : $0.gpxFilePath }
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
                if let folder = currentFolder.getSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
                    let allTracksFilePaths = folder.getFlattenedTrackItems().compactMap({ $0.gpxFilePath }).map { OsmAndApp.swiftInstance().gpxPath.appendingPathComponent($0) }
                    allExportFilePaths.append(contentsOf: allTracksFilePaths)
                } else if let smartFolder = smartFolderHelper.getSmartFolder(name: folderName) {
                    let allTracksFilePaths = smartFolder.getTrackItems().compactMap { $0.gpxFilePath }.map { OsmAndApp.swiftInstance().gpxPath.appendingPathComponent($0) }
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
                if let folder = currentFolder.getSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
                    let tracks = folder.getFlattenedTrackItems().compactMap({ $0.dataItem })
                    allTracks.append(contentsOf: tracks)
                } else if let smartFolder = smartFolderHelper.getSmartFolder(name: folderName) {
                    let tracks = smartFolder.getTrackItems().compactMap { $0.dataItem }
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
    
    @objc private func onNavbarMoveButtonClicked() {
        guard !selectedTracks.isEmpty || !selectedFolders.isEmpty else { return }
        let validFolders = selectedFolders.filter { smartFolderHelper.getSmartFolder(name: $0) == nil }
        let fullFolderPaths = validFolders.map { folderName -> String in
            var trimmedPath = currentFolderPath.hasPrefix("/") ? String(currentFolderPath.dropFirst()) : currentFolderPath
            trimmedPath = trimmedPath.appendingPathComponent(folderName)
            return trimmedPath
        }
        
        if let viewController = OASelectTrackFolderViewController(selectedFolderName: currentFolderPath, excludedSubfolderPaths: fullFolderPaths) {
            viewController.delegate = self
            present(UINavigationController(rootViewController: viewController), animated: true)
        }
    }
    
    @objc private func onNavbarChangeAppearanceButtonClicked() {
        let allTracks: [GpxDataItem] = selectedTracks + selectedFolders.flatMap { folderName in
            if let folder = currentFolder.getSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
                return folder.getFlattenedTrackItems().compactMap { $0.dataItem }
            } else if let smartFolder = smartFolderHelper.getSmartFolder(name: folderName) {
                return smartFolder.getTrackItems().compactMap { $0.dataItem }
            }
            return []
        }
        
        let trackItems = Set(allTracks.toTrackItems())
        guard !trackItems.isEmpty else { return }
        let vc = TracksChangeAppearanceViewController(tracks: trackItems)
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.modalPresentationStyle = .custom
        present(navigationController, animated: true) { [weak self] in
            guard let self else { return }
            self.onNavbarCancelButtonClicked()
        }
    }
    
    @objc private func onNavbarChangeActivityButtonClicked() {
        let allTracks: [GpxDataItem] = selectedTracks + selectedFolders.flatMap { folderName in
            if let folder = currentFolder.getSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
                return folder.getFlattenedTrackItems().compactMap { $0.dataItem }
            } else if let smartFolder = smartFolderHelper.getSmartFolder(name: folderName) {
                return smartFolder.getTrackItems().compactMap { $0.dataItem }
            }
            return []
        }
        
        guard !allTracks.toTrackItems().isEmpty else { return }
        let vc = SelectRouteActivityViewController(tracks: Set(allTracks.toTrackItems()))
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.modalPresentationStyle = .custom
        present(navigationController, animated: true) { [weak self] in
            self?.onNavbarCancelButtonClicked()
        }
    }
    
    @objc private func onNavbarDeleteButtonClicked() {
        if hasSelectedItems() {
            let tracksInSelectedFolders = selectedFolders.reduce(0) { (result, folderName) -> Int in
                if let folder = currentFolder.getFlattenedSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
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
                    handleDeletedGpxFile(gpxFile: track.file)
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
        isSelectionModeInSearch = false
        updateSortButtonAndMenu()
        updateData()
        setupNavbar()
        updateNavigationBarTitle()
        setupSearchController()
        tabBarController?.navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func onNavbarEditFilterCancelButtonClicked() {
        if let appliedCount = baseFilters?.getAppliedFiltersCount(), let smartFiltersCount = smartFolder.filters?.count, appliedCount != smartFiltersCount {
            let alertController = UIAlertController(title: localizedString("unsaved_changes"), message: localizedString("unsaved_changes_will_be_lost_discard"), preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel, handler: nil)
            let resetAction = UIAlertAction(title: localizedString("shared_string_discard"), style: .destructive) { _ in
                self.exitEditFilterMode()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(resetAction)
            present(alertController, animated: true)
        } else {
            exitEditFilterMode()
        }
    }
    
    @objc private func onSelectDeselectAllButtonClicked() {
        if isSelectionModeInSearch {
            if areAllItemsSelected() {
                selectedTracks.removeAll()
                for row in 0..<tableView.numberOfRows(inSection: 0) {
                    tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
                }
            } else {
                if let allTracks = baseFiltersResult?.values {
                    selectedTracks = allTracks.compactMap { $0.dataItem }
                    for row in 0..<tableView.numberOfRows(inSection: 0) {
                        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
                    }
                }
            }
        } else {
            if isSmartFolder {
                let allSmartTracks = smartFolder.getTrackItems().compactMap { $0.dataItem }
                if allSmartTracks.allSatisfy({ selectedTracks.contains($0) }) {
                    selectedTracks.removeAll()
                    for row in 0..<tableView.numberOfRows(inSection: 0) {
                        tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
                    }
                } else {
                    selectedTracks = allSmartTracks
                    for row in 0..<tableView.numberOfRows(inSection: 0) {
                        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
                    }
                }
            } else {
                if areAllItemsSelected() {
                    selectedTracks.removeAll()
                    selectedFolders.removeAll()
                    for row in 0..<tableView.numberOfRows(inSection: 0) {
                        tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
                    }
                } else {
                    guard let currentFolder = getTrackFolderByPath(currentFolderPath) else { return }
                    let allFolders = currentFolder.getSubFolders()
                    selectedFolders = allFolders.map { $0.getDirName(includingSubdirs: false) }
                    selectedTracks = currentFolder.getTrackItems().compactMap({ $0.dataItem }).filter { track in
                        !selectedFolders.contains(where: { folderName in
                            track.gpxFilePath.contains(folderName)
                        })
                    }
                    
                    for row in 0..<tableView.numberOfRows(inSection: 0) {
                        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
                    }
                }
            }
        }
        
        updateNavigationBarTitle()
        configureToolbar()
    }
    
    @objc private func onNavbarDoneButtonClicked() {
        if let filters = baseFilters?.getCurrentFilters() {
            smartFolderHelper.saveSmartFolder(smartFolder: smartFolder, filters: NSMutableArray(array: filters))
        }
        
        exitEditFilterMode()
    }
    
    @objc private func onSelectToolbarButtonClicked() {
        isSelectionModeInSearch = true
        searchController.isActive = false
        onNavbarSelectButtonClicked()
    }
    
    @objc private func onResetToolbarButtonClicked() {
        baseFilters = nil
        baseFiltersResult = nil
        isFiltersInitialized = false
        updateData()
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
        if let selectedFolder = currentFolder.getSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == selectedFolderName }) {
            let exportFilePaths = selectedFolder.getTrackItems().compactMap({ $0.path })
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            let vc = OAExportItemsViewController(tracks: exportFilePaths)
            navigationController?.pushViewController(vc, animated: true)
        } else if let smartFolder = smartFolderHelper.getSmartFolder(name: selectedFolderName) {
            let exportFilePaths = smartFolder.getTrackItems().compactMap { $0.path }
            let state = OATrackMenuViewControllerState()
            state.openedFromTracksList = true
            let vc = OAExportItemsViewController(tracks: exportFilePaths)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func onFolderMoveButtonClicked(_ destinationFolderName: String) {
        guard smartFolderHelper.getSmartFolder(name: destinationFolderName) == nil else { return }
        var trimmedPath = currentFolderPath.hasPrefix("/") ? currentFolderPath.substring(from: 1) : currentFolderPath
        trimmedPath = trimmedPath.appendingPathComponent(destinationFolderName)
        selectedFolderPath = trimmedPath
        let selectedFolderName = trimmedPath.deletingLastPathComponent()
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
                navigationController?.setNavigationBarHidden(true, animated: false)
                navigationController?.popToRootViewController(animated: true)
                rootVC.present(vc, animated: true)
            }
        } else {
            if routingHelper.isFollowingMode() {
                rootVC.mapPanel.mapActions.stopNavigationActionConfirm()
            }
            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.popToRootViewController(animated: true)
            rootVC.mapPanel.mapActions.enterRoutePlanningMode(givenGpx: trackItem, useIntermediatePointsByDefault: true, showDialog: true)
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
        let gpxDoc: GpxFile?
        if isCurrentTrack {
            gpxDoc = nil
        } else {
            guard let file = trackItem.getFile() else { return }
            gpxDoc = GpxUtilities.shared.loadGpxFile(file: file)
        }
        
        gpxHelper.openExport(forTrack: trackItem.dataItem, gpxDoc: gpxDoc, isCurrentTrack: isCurrentTrack, in: self, hostViewControllerDelegate: self, touchPointArea: touchPointArea)
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
        gpxHelper.copyGPX(toNewFolder: isSearchActive ? track.gpxFolderName : currentFolderPath,
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
                if let file = trackItem.getFile() {
                    handleDeletedGpxFile(gpxFile: file)
                }

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
    
    @objc private func onObservedRecordedTrackChanged() {
         guard isRootFolder else { return }
         DispatchQueue.main.async { [weak self] in
             guard let self else { return }
             if self.isContextMenuVisible {
                 self.shouldReloadTableView = true
                 return
             }

             guard view.window != nil else {
                 shouldReloadTableView = true
                 return
             }
             generateData()
             
             let section = 0
             guard tableView.numberOfSections > section else {
                 return
             }
             
             let numberOfRows = tableView.numberOfRows(inSection: section)
             if numberOfRows > 0 {
                 let indexPath = IndexPath(row: 0, section: section)
                 
                 if tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
                     tableView.reloadRows(at: [indexPath], with: .none)
                 } else {
                     tableView.reloadData()
                 }
             } else {
                 tableView.reloadData()
             }
         }
     }
    
    @objc private func didFinishImport() {
        guard view.window != nil else { return }
        updateAllFoldersVCData(forceLoad: true)
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
        handleDeletedGpxFile(gpxFile: src)
        let trackItem = TrackItem(file: dest)
        trackItem.dataItem = OAGPXDatabase.sharedDb().getGPXItem(dest.path())
        smartFolderHelper.addTrackItemToSmartFolder(item: trackItem)
    }
    
    private func renameFolder(newName: String, oldName: String) {
        if let smartFolder = smartFolderHelper.getSmartFolder(name: oldName) {
            let oldSmartFolderId = smartFolder.getId()
            smartFolderHelper.renameSmartFolder(smartFolder: smartFolder, newName: newName)
            renameSortModeKey(from: oldSmartFolderId, to: smartFolder.getId())
            updateData()
        }
        
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
                            renameSortModeKey(from: oldPath, to: newPath)
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
        if let smartFolder = smartFolderHelper.getSmartFolder(name: folderName) {
            smartFolderHelper.deleteSmartFolder(smartFolder: smartFolder)
            removeSortMode(forFolderPath: smartFolder.getId())
            updateData()
            return
        }
        
        let folderPath = currentFolderAbsolutePath().appendingPathComponent(folderName)
        do {
            if let folderForDelete = currentFolder.getSubFolders().first(where: { $0.getDirName(includingSubdirs: false) == folderName }) {
                let tracksItems: [GpxDataItem] = folderForDelete.getFlattenedTrackItems().compactMap({ $0.dataItem })
                if !tracksItems.isEmpty {
                    tracksItems.forEach({
                        gpxDB.removeGpxItem($0, withLocalRemove: false)
                        handleDeletedGpxFile(gpxFile: $0.file)
                        let gpxFilePath = $0.gpxFilePath
                        let isVisible = settings.mapSettingVisibleGpx.contains(gpxFilePath)
                        if isVisible {
                            settings.hideGpx([gpxFilePath])
                        }
                    })
                }
                removeSortMode(forFolderPath: folderForDelete.relativePath)
            }

            // remove folders with tracks
            try FileManager.default.removeItem(atPath: folderPath)
            updateAllFoldersVCData(forceLoad: true)
        } catch let error {
            debugPrint(error)
        }
    }
    
    private func performMove(toFolder destinationFolder: String, tracks: [GpxDataItem]? = nil, folders: [String]? = nil) {
        tracks?.forEach { moveTrack($0, toFolder: destinationFolder) }
        folders?.forEach { moveFolder($0, toFolder: destinationFolder) }
    }
    
    private func moveTrack(_ track: GpxDataItem, toFolder folderName: String) {
        let trackItem = TrackItem(file: track.file)
        trackItem.dataItem = track
        gpxHelper.copyGPX(toNewFolder: folderName,
                          renameToNewName: nil,
                          deleteOriginalFile: true,
                          openTrack: false,
                          trackItem: trackItem)
    }
    
    private func renameVisibleTracks(oldPath: String, newPath: String) {
        var visibleGpx = settings.mapSettingVisibleGpx.get()
        
        for i in 0..<visibleGpx.count where visibleGpx[i].hasPrefix(oldPath) {
            let newPathCount = oldPath.count
            let oldPathString = visibleGpx[i]
            let modifiedString = newPath + oldPathString.dropFirst(newPathCount)
            visibleGpx[i] = modifiedString
        }
        settings.mapSettingVisibleGpx.set(visibleGpx)
    }
    
    private func moveFolder(_ folderName: String, toFolder destinationFolderName: String) {
        let sourceFolderPath = getAbsolutePath(folderName)
        let destinationShortFolderPath = (destinationFolderName == localizedString("shared_string_gpx_tracks") ? "" : destinationFolderName)
            .appendingPathComponent(sourceFolderPath.lastPathComponent())
        let destinationFolderPath = getAbsolutePath(destinationShortFolderPath)
        
        guard let trackFolder = getTrackFolderByPath(folderName) else { return }
        
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
    
        renameSortModeKey(from: folderName, to: destinationShortFolderPath)
    }
    
    private func renameSortModeKey(from oldBasePath: String, to newBasePath: String) {
        let sortModes = settings.getTracksSortModes()
        var updatedSortModes = [String: String]()
        for (key, value) in sortModes {
            if key.hasPrefix(oldBasePath) {
                let newPathCount = oldBasePath.count
                let modifiedKey = newBasePath + key.dropFirst(newPathCount)
                updatedSortModes[modifiedKey] = value
            } else {
                updatedSortModes[key] = value
            }
        }
        
        settings.saveTracksSortModes(updatedSortModes)
    }
    
    private func removeSortMode(forFolderPath folderPath: String) {
        let sortModes = settings.getTracksSortModes()
        var updatedSortModes = [String: String]()
        for (key, value) in sortModes where !key.hasPrefix(folderPath) {
            updatedSortModes[key] = value
        }
        
        settings.saveTracksSortModes(updatedSortModes)
    }
   
    private func areAllItemsSelected() -> Bool {
        if isSelectionModeInSearch {
            if let allTracks = baseFiltersResult?.values {
                return allTracks.compactMap { $0.dataItem }.allSatisfy { selectedTracks.contains($0) }
            }
            return false
        } else if isSmartFolder {
            let allSmartTracks = smartFolder.getTrackItems().compactMap { $0.dataItem }
            return allSmartTracks.allSatisfy { selectedTracks.contains($0) }
        } else {
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
    }
    
    private func hasSelectedItems() -> Bool {
        !selectedFolders.isEmpty || !selectedTracks.isEmpty
    }
    
    private func showTracksViewControllerForSmartFolder(withName name: String) {
        let smartFolder = smartFolderHelper.getSmartFolder(name: name)
        let storyboard = UIStoryboard(name: "MyPlaces", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "TracksViewController") as? TracksViewController {
            vc.smartFolder = smartFolder
            vc.rootFolder = rootFolder
            vc.currentFolder = currentFolder
            vc.visibleTracksFolder = visibleTracksFolder
            vc.isRootFolder = false
            vc.isSmartFolder = true
            vc.hostVCDelegate = self
            show(vc)
        }
    }
    
    private func exitEditFilterMode() {
        baseFilters = nil
        baseFiltersResult = nil
        isFiltersInitialized = false
        isEditFilterActive = false
        setupNavbar()
        updateNavigationBarTitle()
        setupSearchController()
        updateFilterButtonVisibility(filterIsActive: false)
        updateAllFoldersVCData(forceLoad: true)
        setupTableFooter()
        tabBarController?.navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = false
    }
    
    private func handleDeletedGpxFile(gpxFile: KFile) {
        smartFolderHelper.onGpxFileDeleted(gpxFile: gpxFile)
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
                    cell.leftIconView.tintColor = .iconColorDefault
                }
                
                cell.button.layer.cornerRadius = 9
                cell.button.configuration = getRecButtonConfig()
                cell.button.backgroundColor = .contextMenuButtonBg
                if let buttonTitle = item.string(forKey: buttonTitleKey) {
                    cell.button.setTitle(buttonTitle, for: .normal)
                }
                if let buttonIconName = item.string(forKey: buttonIconKey) {
                    cell.button.setImage(UIImage.templateImageNamed(buttonIconName), for: .normal)
                    cell.button.tintColor = .iconColorActive
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
                cell.leftButton.backgroundColor = .contextMenuButtonBg
                if let buttonIconName = item.string(forKey: buttonIconKey) {
                    cell.leftButton.setImage(UIImage.templateImageNamed(buttonIconName), for: .normal)
                    cell.leftButton.tintColor = .iconColorActive
                }
                cell.leftButton.removeTarget(nil, action: nil, for: .allEvents)
                cell.leftButton.addTarget(self, action: #selector(onCurrentTrackButtonClicked(_:)), for: .touchUpInside)
                cell.leftButton.tag = item.integer(forKey: buttonActionNumberTagKey)
                
                cell.rightButton.setTitle("", for: .normal)
                cell.rightButton.backgroundColor = .contextMenuButtonBg
                if let buttonIconName = item.string(forKey: secondButtonIconKey) {
                    cell.rightButton.setImage(UIImage.templateImageNamed(buttonIconName), for: .normal)
                    cell.rightButton.tintColor = .iconColorActive
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
                cell.titleLabel.textColor = .textColorPrimary
                cell.descriptionLabel.textColor = .textColorSecondary
                cell.titleLabel.text = item.title
                if item.key == trackKey {
                    cell.descriptionLabel.text = nil
                    cell.descriptionLabel.attributedText = item.obj(forKey: trackSortDescrKey) as? NSAttributedString
                } else {
                    cell.descriptionLabel.attributedText = nil
                    cell.descriptionLabel.text = item.descr
                }
                cell.accessoryType = tableView.isEditing ? .none : .disclosureIndicator
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage.templateImageNamed(iconName)
                } else {
                    cell.leftIconView.image = nil
                }
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
                cell.showButton(item.key != emptyFilterFolderKey)
                cell.titleLabel?.text = item.title
                cell.descriptionLabel?.text = item.descr
                if let iconName = item.iconName {
                    cell.cellImageView?.image = UIImage.templateImageNamed(iconName)
                } else {
                    cell.cellImageView?.image = nil
                }
                
                cell.cellImageView?.tintColor = item.iconTintColor
                cell.button?.setTitle(item.obj(forKey: buttonTitleKey) as? String, for: .normal)
                cell.button?.removeTarget(nil, action: nil, for: .allEvents)
                cell.button?.addTarget(self, action: item.key == emptySmartFolderKey ? #selector(onNavbarEditFilterSmartFolderButtonClicked) : #selector(onNavbarImportButtonClicked), for: .touchUpInside)
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
            outgoing.font = .preferredFont(forTextStyle: .footnote)
            return outgoing
        }
        return buttonConfig
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isEditFilterActive else { return }
        let item = tableData.item(for: indexPath)
        if tableView.isEditing {
            if item.key == trackKey {
                if let trackPath = item.obj(forKey: pathKey) as? String,
                   let track = rootFolder.getFlattenedTrackItems().compactMap({ $0.dataItem }).first(where: { $0.gpxFilePath == trackPath }) {
                    if !selectedTracks.contains(track) {
                        selectedTracks.append(track)
                    }
                }
            } else if item.key == tracksFolderKey || item.key == tracksSmartFolderKey {
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
                    shouldReload = true
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
            } else if item.key == tracksSmartFolderKey {
                guard let title = item.title else { return }
                showTracksViewControllerForSmartFolder(withName: title)
            } else if item.key == trackKey {
                if let trackPath = item.obj(forKey: pathKey) as? String,
                   let track = rootFolder.getFlattenedTrackItems().first(where: { $0.gpxFilePath == trackPath }),
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
                   let track = rootFolder.getFlattenedTrackItems().compactMap({ $0.dataItem }).first(where: { $0.gpxFilePath == trackPath }),
                   let index = selectedTracks.firstIndex(of: track) {
                    selectedTracks.remove(at: index)
                }
            } else if item.key == tracksFolderKey || item.key == tracksSmartFolderKey {
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
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        isContextMenuVisible = true
        return nil
    }
    
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        animator?.addCompletion { [weak self] in
            guard let self else { return }
            if self.shouldReloadTableView {
                self.updateData()
                self.shouldReloadTableView = false
            }
            self.isContextMenuVisible = false
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.key == tracksFolderKey || item.key == tracksSmartFolderKey {
            
            let selectedFolderName = item.title ?? ""
            
            let menuProvider: UIContextMenuActionProvider = { [weak self] _ in
                
                // TODO: implement Folder Details in next task   https://github.com/osmandapp/OsmAnd-Issues/issues/2348
                // let detailsAction = UIAction(title: localizedString("shared_string_details"), image: UIImage.icCustomInfoOutlined) { [weak self] _ in
                //     self?.onFolderDetailsButtonClicked()
                // }
                // let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [detailsAction])
                
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit) { _ in
                    self?.onFolderRenameButtonClicked(selectedFolderName)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [renameAction])
                
                let exportAction = UIAction(title: localizedString("shared_string_export"), image: .icCustomExportOutlined) { _ in
                    self?.onFolderExportButtonClicked(selectedFolderName)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined) { _ in
                    self?.onFolderMoveButtonClicked(selectedFolderName)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [exportAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { _ in
                    guard let self else { return }
                    
                    let folderTracksCount = item.integer(forKey: self.tracksCountKey)
                    self.onFolderDeleteButtonClicked(folderName: selectedFolderName, tracksCount: folderTracksCount)
                }
                let lastButtonsSection = UIMenu(title: "", options: .displayInline, children: [deleteAction])
                return UIMenu(title: "", image: nil, children: [secondButtonsSection, thirdButtonsSection, lastButtonsSection])
            }
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
        } else if item.key == trackKey || item.key == recordingTrackKey {
            guard !isEditFilterActive else { return nil }
            let isCurrentTrack = item.key == recordingTrackKey
            if isCurrentTrack && !savingHelper.hasData() {
                return nil
            }
            let isTrackVisible = item.bool(forKey: isVisibleKey)
            let selectedTrackPath = item.string(forKey: self.pathKey) ?? ""
            let selectedTrackFilename = item.string(forKey: self.fileNameKey) ?? ""
            var track = getTrackFolderByPath(currentFolderPath)?
                .getTrackItems()
                .first(where: { $0.gpxFileName == selectedTrackFilename })
            if track == nil, (isSearchActive || isSmartFolder),
               let gpx = item.obj(forKey: trackObjectKey) as? GpxDataItem {
                track = TrackItem(file: gpx.file)
                track?.dataItem = gpx
            }
            
            let menuProvider: UIContextMenuActionProvider = { [weak self] _ in
                
                let showOnMapAction = UIAction(title: localizedString(isTrackVisible ? "shared_string_hide_from_map" : "shared_string_show_on_map"), image: .icCustomMapPinOutlined) { _ in
                    self?.onTrackShowOnMapClicked(trackPath: selectedTrackPath, isVisible: isTrackVisible, isCurrentTrack: isCurrentTrack)
                }
                let appearenceAction = UIAction(title: localizedString("shared_string_appearance"), image: .icCustomAppearanceOutlined) { _ in
                    self?.onTrackAppearenceClicked(track: track, isCurrentTrack: isCurrentTrack)
                }
                let navigationAction = UIAction(title: localizedString("shared_string_navigation"), image: .icCustomNavigationOutlined) { _ in
                    self?.onTrackNavigationClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let firstButtonsSection = UIMenu(title: "", options: .displayInline, children: [showOnMapAction, appearenceAction, navigationAction])
                
                let analyzeAction = UIAction(title: localizedString("gpx_analyze"), image: .icCustomGraph) { _ in
                    self?.onTrackAnalyzeClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let secondButtonsSection = UIMenu(title: "", options: .displayInline, children: [analyzeAction])
                
                let shareAction = UIAction(title: localizedString("shared_string_share"), image: .icCustomExportOutlined) { _ in
                    guard let self else { return }
                    let cellScreenArea = self.view.convert(self.tableView.rectForRow(at: indexPath), from: self.tableView)
                    self.onTrackShareClicked(track, isCurrentTrack: isCurrentTrack, touchPointArea: cellScreenArea)
                }
                let uploadToOsmAction = UIAction(title: localizedString("upload_to_osm_short"), image: .icCustomUploadToOpenstreetmapOutlined) { _ in
                    self?.onTrackUploadToOsmClicked(track)
                }
                let thirdButtonsSection = UIMenu(title: "", options: .displayInline, children: [shareAction, uploadToOsmAction])
                
                let editAction = UIAction(title: localizedString("shared_string_edit"), image: .icCustomTrackEdit, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self?.onTrackEditClicked(track)
                }
                let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: .icCustomCopy, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self?.onTrackDuplicateClicked(track: track)
                }
                let renameAction = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self?.onTrackRenameClicked(track)
                }
                let moveAction = UIAction(title: localizedString("shared_string_move"), image: .icCustomFolderMoveOutlined, attributes: isCurrentTrack ? .disabled : []) { _ in
                    self?.onTrackMoveClicked(track, isCurrentTrack: isCurrentTrack)
                }
                let fourthButtonsSection = UIMenu(title: "", options: .displayInline, children: [editAction, duplicateAction, renameAction, moveAction])
                
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { _ in
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
        guard let selectedFolderName else { return }
        let validFolders = selectedFolders.filter { smartFolderHelper.getSmartFolder(name: $0) == nil }
        if !selectedTracks.isEmpty || !validFolders.isEmpty {
            let fullRelativeFolders = validFolders.map { folderName -> String in
                var trimmedPath = currentFolderPath.hasPrefix("/") ? String(currentFolderPath.dropFirst()) : currentFolderPath
                trimmedPath = trimmedPath.appendingPathComponent(folderName)
                return trimmedPath
            }
            performMove(toFolder: selectedFolderName, tracks: selectedTracks, folders: fullRelativeFolders)
        } else if let track = selectedTrack {
            performMove(toFolder: selectedFolderName, tracks: [track], folders: nil)
        } else if let folderPath = selectedFolderPath {
            performMove(toFolder: selectedFolderName, tracks: nil, folders: [folderPath])
        }
        
        updateAllFoldersVCData(forceLoad: true)
    }
    
    func onFolderAdded(_ addedFolderName: String) {
        let newFolderPath = getAbsolutePath(addedFolderName)
        if !FileManager.default.fileExists(atPath: newFolderPath) {
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true)
                onFolderSelected(addedFolderName)
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func onFolderSelectCancelled() {
        selectedFolderPath = nil
        selectedTrack = nil
        if tableView.isEditing {
            onNavbarCancelButtonClicked()
        }
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
                self.updateFilterButton()
            }
        }
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
        
        if searchController.isActive {
            if !isFiltersInitialized && (searchController.searchBar.searchTextField.text?.isEmpty ?? true) {
                isSearchActive = true
                isNameFiltered = false
                tabBarController?.tabBar.isHidden = true
                tabBarController?.navigationController?.setToolbarHidden(false, animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
                configureToolbar()
                baseFilters = TracksSearchFilter(trackItems: rootFolder.getFlattenedTrackItems(), currentFolder: nil)
                baseFilters?.addFiltersChangedListener(self)
                TracksSearchFilter.setRootFolder(rootFolder)
                isFiltersInitialized = true
            } else if !(searchController.searchBar.searchTextField.text ?? "").isEmpty {
                isSearchActive = true
                isNameFiltered = true
            } else {
                isNameFiltered = false
            }
            (baseFilters?.getFilterByType(.name) as? TextTrackFilter)?.value = searchController.searchBar.searchTextField.text ?? ""
        } else {
            isSearchActive = false
            isNameFiltered = false
            isFiltersInitialized = false
        }
        
        updateSearchController()
        updateFilterButtonVisibility(filterIsActive: isSearchActive)
        baseFiltersResult = baseFilters?.performFiltering()
        updateSortButtonAndMenu()
        updateData()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        isNameFiltered = false
        baseFilters = nil
        baseFiltersResult = nil
        isFiltersInitialized = false
        tabBarController?.navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = false
        updateSearchController()
        updateFilterButtonVisibility(filterIsActive: isSearchActive)
        updateSortButtonAndMenu()
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

extension TracksViewController {
    private func createSortMenu(isSortingSubfolders: Bool) -> UIMenu {
        let sortingOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .nearest, isSortingSubfolders: isSortingSubfolders),
            createAction(for: .lastModified, isSortingSubfolders: isSortingSubfolders)
        ])
        let alphabeticalOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .nameAZ, isSortingSubfolders: isSortingSubfolders),
            createAction(for: .nameZA, isSortingSubfolders: isSortingSubfolders)
        ])
        let dateOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .newestDateFirst, isSortingSubfolders: isSortingSubfolders),
            createAction(for: .oldestDateFirst, isSortingSubfolders: isSortingSubfolders)
        ])
        let distanceOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .longestDistanceFirst, isSortingSubfolders: isSortingSubfolders),
            createAction(for: .shortestDistanceFirst, isSortingSubfolders: isSortingSubfolders)
        ])
        let durationOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .longestDurationFirst, isSortingSubfolders: isSortingSubfolders),
            createAction(for: .shorterDurationFirst, isSortingSubfolders: isSortingSubfolders)
        ])
        
        return UIMenu(title: isSortingSubfolders ? localizedString("sort_subfolders_tracks") : "", image: isSortingSubfolders ? .icCustomSortSubfolder : nil, children: [sortingOptions, alphabeticalOptions, dateOptions, distanceOptions, durationOptions])
    }
    
    private func createAction(for sortType: TracksSortMode, isSortingSubfolders: Bool) -> UIAction {
        let isCurrentSortType = isSearchActive || isSelectionModeInSearch ? sortType == sortModeForSearch : sortType == sortMode
        let actionState: UIMenuElement.State = isCurrentSortType ? .on : .off
        return UIAction(title: sortType.title, image: sortType.image, state: actionState) { [weak self] _ in
            guard let self else { return }
            if self.isSearchActive || self.isSelectionModeInSearch {
                self.setSearchTracksSortMode(sortType)
                self.sortModeForSearch = getSearchTracksSortMode()
            } else {
                self.setTracksSortMode(sortType, isSortingSubfolders: isSortingSubfolders)
                self.sortMode = getTracksSortMode()
            }
            updateSortButtonAndMenu()
            if !self.isEditFilterActive {
                self.setupNavBarMenuButton()
            }
            self.updateData()
            if isSortingSubfolders {
                let sortingFolderName = self.currentFolder.getDirName(includingSubdirs: false)
                let sortingOrderName = localizedString(sortType.title)
                let message = "\(localizedString("shared_string_subfolders_in")) “\(sortingFolderName)” \(localizedString("shared_string_sorted_by")) “\(sortingOrderName)”"
                OAUtilities.showToast("", details: message, duration: 4, verticalOffset: 120, in: self.view)
            }
        }
    }
    
    private func updateSortButtonAndMenu() {
        sortButton.setImage(isSearchActive || isSelectionModeInSearch ? sortModeForSearch.image : sortMode.image, for: .normal)
        sortButton.menu = createSortMenu(isSortingSubfolders: false)
    }
}
