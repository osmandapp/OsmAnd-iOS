//
//  SavedArticlesTabViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class SavedArticlesTabViewController: OACompoundViewController, GpxReadDelegate, TravelExploreViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate {
    
    @IBOutlet private weak var tableView: UITableView!
    
    var tableData = OATableDataModel()
    var imagesCacheHelper: TravelGuidesImageCacheHelper?
    var savedArticlesObserver: OAAutoObserverProxy?
    var isGpxReading = false
    var searchController = UISearchController()
    var isSearchActive = false
    var isFiltered = false
    var searchText = ""
    var lastSelectedIndexPath: IndexPath?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.topItem?.setRightBarButtonItems([], animated: false)
        tabBarController?.navigationItem.title = localizedString("shared_string_travel_guides")
        setupSearchController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        startAsyncInit()
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
            self.generateData()
            self.tableView?.reloadData()
            self.view.removeSpinner()
        }
    }
    
    func generateData() {
        tableData.clearAllData()
        var savedArticles = TravelObfHelper.shared.getBookmarksHelper().getSavedArticles()
        savedArticles = savedArticles.sorted { ($0.title ?? "") < ($1.title ?? "")}
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
            articleRow.setObj(item.lang, forKey: "lang")
            if let imageTitle = item.imageTitle, !imageTitle.isEmpty {
                articleRow.iconName = TravelArticle.getImageUrl(imageTitle: imageTitle, thumbnail: false)
            }
        }
    }
    
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        tabBarController?.navigationItem.searchController = searchController
        updateSearchController()
    }
    
    func updateSearchController() {
        if isFiltered {
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
    
    // MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(tableData.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        lastSelectedIndexPath = indexPath
        if let article = item.obj(forKey: "article") as? TravelArticle {
            let vc = TravelArticleDialogViewController(articleId: article.generateIdentifier(), lang: article.lang ?? "")
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        if item.cellType == ArticleTravelCell.getIdentifier() {
            if let article = item.obj(forKey: "article") as? TravelArticle {
                let lang = item.string(forKey: "lang") ?? ""
                
                let menuProvider: UIContextMenuActionProvider = { _ in
                    let readAction = UIAction(title: localizedString("shared_string_read"), image: UIImage(named: "ic_custom_file_read")) { [weak self] _ in
                        guard let self else { return }
                        lastSelectedIndexPath = indexPath
                        let vc = TravelArticleDialogViewController(articleId: article.generateIdentifier(), lang: article.lang ?? "")
                        vc.delegate = self
                        navigationController?.pushViewController(vc, animated: true)
                    }
                    let bookmarkAction = UIAction(title: localizedString("shared_string_remove_bookmark"), image: UIImage(named: "ic_custom_bookmark_outlined")) { [weak self] _ in
                        guard let self else { return }
                        TravelObfHelper.shared.getBookmarksHelper().removeArticleFromSaved(article: article)
                        self.generateData()
                        self.tableView.reloadData()
                    }
                    let pointsAction = UIAction(title: localizedString("shared_string_gpx_points"), image: UIImage(named: "ic_custom_point_markers_outlined")) { [weak self] _ in
                        guard let self else { return }
                        self.view.addSpinner(inCenterOfCurrentView: true)
                        _ = TravelObfHelper.shared.getArticleById(articleId: article.generateIdentifier(), lang: lang, readGpx: true, callback: self)
                    }
                    return UIMenu(title: "", children: [readAction, bookmarkAction, pointsAction])
                }
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
            }
        }
        return nil
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
            // FIXME:
//            OARootViewController.instance().mapPanel.openTargetViewWithGPX(fromTracksList: gpx,
//                                                                           navControllerHistory: newCurrentHistory,
//                                                                           fromTrackMenu: false,
//                                                                           selectedTab: .pointsTab)
        }
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
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
        updateSearchController()
        generateData()
        tableView.reloadData()
    }
    
    // MARK: UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        isFiltered = false
        updateSearchController()
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
