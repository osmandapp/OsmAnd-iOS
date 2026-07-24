//
//  SavedArticlesTabViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class SavedArticlesTabViewController: UITableViewController, GpxReadDelegate, TravelExploreViewControllerDelegate, MyPlacesSearchable {
    
    var tableData = OATableDataModel()
    var imagesCacheHelper: TravelGuidesImageCacheHelper?
    var savedArticlesObserver: OAAutoObserverProxy?
    var isGpxReading = false
    var isSearchActive = false
    var isFiltered = false
    var searchText = ""
    var lastSelectedIndexPath: IndexPath?
    weak var myPlacesDelegate: MyPlacesDelegate?
    
    private var sortMode: MyPlacesSortMode = .lastModified
    private lazy var settings: OAAppSettings = .sharedManager()
    
    private lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 7
        config.imagePlacement = .leading
        config.baseForegroundColor = .iconColorActive
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        let button = UIButton(configuration: config, primaryAction: nil)
        button.setImage(sortMode.image?.resizedMenuImage(), for: .normal)
        button.menu = createSortMenu()
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    init(frame: CGRect) {
        super.init(style: .insetGrouped)
        view.frame = frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbarButtons()
        definesPresentationContext = true
        tableView.tableHeaderView = setupHeaderView()
        tableView.backgroundColor = .viewBg
        myPlacesDelegate?.updateContentScrollView(tableView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        startAsyncInit()
        sortMode = savedSortMode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        definesPresentationContext = false
        myPlacesDelegate?.updateSearchEnabling(false)
    }
    
    override func isNavbarVisible() -> Bool {
        true
    }
    
    func startAsyncInit() {
        self.view.addSpinner(inCenterOfCurrentView: true)
        DispatchQueue.global(qos: .default).async {
            self.savedArticlesObserver = OAAutoObserverProxy(self, withHandler: #selector(self.update), andObserve: TravelObfHelper.shared.getBookmarksHelper().observable)
            self.imagesCacheHelper = TravelGuidesImageCacheHelper.sharedDatabase
            TravelObfHelper.shared.getBookmarksHelper().refreshCachedData()
            // call update() on finish
        }
    }
    
    deinit {
        savedArticlesObserver?.detach()
    }

    @objc func update() {
        DispatchQueue.main.async {
            self.updateData()
            self.view.removeSpinner()
        }
    }
    
    func generateData() {
        tableData.clearAllData()
        var savedArticles = MyPlacesSortModeHelper.sortTravelGuidesWithMode(TravelObfHelper.shared.getBookmarksHelper().getSavedArticles(), mode: sortMode)
        if isFiltered {
            savedArticles = savedArticles.filter { ($0.title?.lowercased() ?? "").contains(searchText.lowercased()) }
        }
        
        let section = tableData.createNewSection()
        section.headerText = localizedString("saved_articles")
        
        for article in savedArticles {
            let item: TravelArticle = article
            let articleRow = section.createNewRow()
            articleRow.cellType = ArticleTravelCell.getIdentifier()
            articleRow.title = item.title ?? "nil"
            articleRow.descr = OATravelGuidesHelper.getPatrialContent(item.content)
            articleRow.setObj(item.getGeoDescription() ?? "", forKey: "isPartOf")
            articleRow.setObj(item, forKey: "article")
            articleRow.setObj(item.lang as Any, forKey: "lang")
            if let imageTitle = item.imageTitle, !imageTitle.isEmpty {
                articleRow.iconName = TravelArticle.getImageUrl(imageTitle: imageTitle, thumbnail: false)
            }
        }
    }
    
    // MARK: TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Int(tableData.sectionCount())
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)
        if item.cellType == ArticleTravelCell.getIdentifier() {
            var cell = self.tableView.dequeueReusableCell(withIdentifier: ArticleTravelCell.getIdentifier()) as? ArticleTravelCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("ArticleTravelCell", owner: self, options: nil)
                cell = nib?.first as? ArticleTravelCell
                cell?.imageVisibility(true)
                cell?.imagePreview.contentMode = .scaleAspectFill
                cell?.imagePreview.layer.cornerRadius = 11
            }
            if let cell {
                cell.article = item.obj(forKey: "article") as? TravelArticle
                cell.articleLang = item.string(forKey: "lang")
                cell.arcticleTitle.text = item.title
                cell.arcticleDescription.text = item.descr
                cell.regionLabel.text = item.string(forKey: "isPartOf")
                
                cell.imageVisibility(true)
                
                if let imageUrl = item.iconName, let downloadMode = OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode {
                    
                    // fetch image from db. if not found -  start async downloading.
                    imagesCacheHelper?.fetchSingleImage(byURL: imageUrl, customKey: nil, downloadMode: downloadMode, onlyNow: false) { [imageUrl] imageAsBase64 in
                        DispatchQueue.main.async {
                            
                            if imageUrl == item.iconName {
                                if let imageAsBase64, !imageAsBase64.isEmpty {
                                    if let image = ImageToStringConverter.base64StringToImage(imageAsBase64) {
                                        cell.imagePreview.image = image
                                        cell.noImageIconVisibility(false)
                                    }
                                } else {
                                    cell.noImageIconVisibility(true)
                                }
                            }
                        }
                    }
                } else {
                    cell.noImageIconVisibility(true)
                }
                
                cell.updateSaveButton()
                return cell
            }
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        lastSelectedIndexPath = indexPath
        if let article = item.obj(forKey: "article") as? TravelArticle {
            let vc = TravelArticleDialogViewController(articleId: article.generateIdentifier(), lang: article.lang ?? "")
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.cellType == ArticleTravelCell.getIdentifier() {
            if let article = item.obj(forKey: "article") as? TravelArticle {
                let lang = item.string(forKey: "lang") ?? ""
                
                let menuProvider: UIContextMenuActionProvider = { _ in
                    let readAction = UIAction(title: localizedString("shared_string_read"), image: .icCustomFileRead) { [weak self] _ in
                        guard let self else { return }
                        lastSelectedIndexPath = indexPath
                        let vc = TravelArticleDialogViewController(articleId: article.generateIdentifier(), lang: article.lang ?? "")
                        vc.delegate = self
                        navigationController?.pushViewController(vc, animated: true)
                    }
                    let bookmarkAction = UIAction(title: localizedString("shared_string_remove_bookmark"), image: .icCustomBookmarkOutlined) { [weak self] _ in
                        guard let self else { return }
                        TravelObfHelper.shared.getBookmarksHelper().removeArticleFromSaved(article: article)
                        self.updateData()
                    }
                    let pointsAction = UIAction(title: localizedString("shared_string_gpx_points"), image: .icCustomPointMarkersOutlined) { [weak self] _ in
                        guard let self else { return }
                        self.view.addSpinner(inCenterOfCurrentView: true)
                        _ = TravelObfHelper.shared.getArticleById(articleId: article.generateIdentifier(), lang: lang, readGpx: true, callback: self)
                    }
                    return UIMenu.composedMenu(from: [[readAction, pointsAction], [bookmarkAction]])
                }
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
            }
        }
        return nil
    }
    
    private func setupHeaderView() -> UIView? {
        let headerView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.width, height: 44))
        headerView.backgroundColor = .clear
        headerView.addSubview(sortButton)
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sortButton.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            sortButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            sortButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            sortButton.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor)
        ])
        
        return headerView
    }
    
    private func updateSortButtonAndMenu() {
        sortButton.setImage(sortMode.image?.resizedMenuImage(), for: .normal)
        sortButton.menu = createSortMenu()
    }
    
    private func createSortMenu() -> UIMenu {
        let sortingOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .lastModified)
        ])
        let alphabeticalOptions = UIMenu(options: .displayInline, children: [
            createAction(for: .nameAZ),
            createAction(for: .nameZA)
        ])
        
        return UIMenu(title: "", image: nil, children: [sortingOptions, alphabeticalOptions])
    }
    
    private func createAction(for sortType: MyPlacesSortMode) -> UIAction {
        let actionState: UIMenuElement.State = sortType == sortMode ? .on : .off
        return UIAction(title: sortType.title, image: sortType.image, state: actionState) { [weak self] _ in
            guard let self else { return }
            self.updateSortMode(sortType)
            self.sortMode = savedSortMode()
            updateSortButtonAndMenu()
            updateData()
        }
    }
    
    private func updateSortMode(_ sortMode: MyPlacesSortMode) {
        settings.travelGuidesSortMode.set(sortMode.title)
    }
    
    private func savedSortMode() -> MyPlacesSortMode {
        let sortModeTitle = settings.travelGuidesSortMode.get()
        return MyPlacesSortMode.byTitle(sortModeTitle)
    }
    
    private func setupNavbarButtons() {
        guard !isSearchActive else {
            navigationController?.navigationBar.topItem?.setRightBarButtonItems(nil, animated: false)
            navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }

        let searchIcon = UIImage(systemName: "magnifyingglass",
                                 withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .textColorPrimary))
        let searchButton = UIBarButtonItem(image: searchIcon,
                                           style: .plain,
                                           target: self,
                                           action: #selector(searchButtonPressed(_:)))
        searchButton.accessibilityLabel = localizedString("shared_string_search")

        if #available(iOS 26.0, *) {
            searchButton.style = .prominent
            searchButton.tintColor = .clear
        }

        navigationController?.navigationBar.topItem?.setRightBarButtonItems([searchButton], animated: false)
        navigationItem.setRightBarButtonItems([searchButton], animated: false)
    }

    private func updateData() {
        generateData()
        tableView.reloadData()
    }
    
    @objc
    private func searchButtonPressed(_ sender: Any) {
        myPlacesDelegate?.updateSearchEnabling(true)
        isSearchActive = true
        setupNavbarButtons()
    }

    // MARK: GpxReadDelegate
    
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle) {
        // Open TravelGpx track
        article.gpxFile = gpxFile
        let filename = TravelObfHelper.shared.createGpxFile(article: article)
        OATravelGuidesHelper.createGpxFile(article, fileName: filename)
        view.removeSpinner()

        guard let gpx = OATravelGuidesHelper.buildGpx(filename, title: article.title, document: gpxFile), gpx.wptPoints != 0 else {
            OAUtilities.showToast(nil, details: localizedString("article_has_no_points"), duration: 4, in: self.view)
            return
        }

        OAAppSettings.sharedManager().showGpx([filename], update: true)
        if let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty {
            let trackItem = TrackItem(file: gpx.file)
            OARootViewController.instance().mapPanel.openTargetViewWithGPX(fromTracksList: trackItem,
                                                                           navControllerHistory: newCurrentHistory,
                                                                           fromTrackMenu: false,
                                                                           selectedTab: .pointsTab)
        }
    }
    
    // MARK: MyPlacesSearchable
    
    func searchResults(for searchController: UISearchController) {
        if searchController.isActive && searchController.searchBar.searchTextField.text?.length == 0 {
            isSearchActive = true
            isFiltered = false
        } else if searchController.isActive && !(searchController.searchBar.searchTextField.text ?? "").isEmpty {
            isSearchActive = true
            isFiltered = true
            searchText = searchController.searchBar.searchTextField.text ?? ""
        } else {
            isSearchActive = false
            isFiltered = false
        }
        updateData()
        setupNavbarButtons()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        isFiltered = false
        myPlacesDelegate?.updateSearchEnabling(false)
    }
    
    // MARK: TravelExploreViewControllerDelegate
    
    func close() {
        self.view.addSpinner(inCenterOfCurrentView: true)
        if let indexPath = lastSelectedIndexPath {
            let item = tableData.item(for: indexPath)
            if let article = item.obj(forKey: "article") as? TravelArticle, let lang = item.string(forKey: "lang") {
                _ = TravelObfHelper.shared.getArticleById(articleId: article.generateIdentifier(), lang: lang, readGpx: true, callback: self)
            }
        }
    }
}
