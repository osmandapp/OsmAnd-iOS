//
//  TravelExploreViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelExploreViewControllerDelegate)
protocol TravelExploreViewControllerDelegate: AnyObject {
    @objc optional func populateData(resetData: Bool)
    @objc optional func onDataLoaded()
    @objc optional func openArticle(article: TravelArticle, lang: String?)
    func close()
}

@objc(OATravelExploreViewController)
@objcMembers
final class TravelExploreViewController: OABaseNavbarViewController, TravelExploreViewControllerDelegate, GpxReadDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    enum ScreenModes {
        case popularArticles
        case history
        case searchResults
    }
  
    var searchController: UISearchController!
    var imagesCacheHelper: TravelGuidesImageCacheHelper?
    var downloadingCellHelper: OADownloadingCellHelper = OADownloadingCellHelper()
    var dataLock: NSObject = NSObject()
    var downloadingResources: [OAResourceSwiftItem] = []
    var lastSelectedIndexPath: IndexPath?
    var isGpxReading = false
    var isPointsReadingMode = false
    var searchHelper: TravelSearchHelper?
    var searchQuery = ""
    var searchResults = [TravelSearchResult]()
    var isFiltered = false
    var screenMode: ScreenModes = .popularArticles
    var isInited = false
    var isDataLoaded = false
    var isGpxPointsOpening = false
    
    override func commonInit() {
        super.commonInit()
        searchQuery = ""
        searchHelper = TravelSearchHelper()
        searchHelper!.uiCanceled = false
        searchResults = []
        imagesCacheHelper = TravelGuidesImageCacheHelper.sharedDatabase
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        downloadingResources = []
        setupDownloadingCellHelper()
        populateData(resetData: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        setupSearchControllerWithFilter(false)
        tableView.keyboardDismissMode = .onDrag
        isInited = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.leftItemsSupplementBackButton = true
        navigationController?.navigationBar.topItem?.backButtonTitle = localizedString("shared_string_back")
        screenMode = .popularArticles
    }
    
    override func registerObservers() {
        addObserver(OAAutoObserverProxy(self, withHandler: #selector(update), andObserve: TravelObfHelper.shared.getBookmarksHelper().observable))
        addObserver(OAAutoObserverProxy(self, withHandler: #selector(populateAndUpdate), andObserve: OsmAndApp.swiftInstance().localResourcesChangedObservable))
    }

    // MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        if let optionsButton = createRightNavbarButton(nil, iconName: "ic_navbar_overflow_menu_stroke", action: #selector(onOptionsButtonClicked), menu: nil) {
            optionsButton.accessibilityLabel = localizedString("shared_string_options")
            return [optionsButton]
        }
        return []
    }
    
    func populateData(resetData: Bool) {
        view.addSpinner(inCenterOfCurrentView: true)
        let task = LoadWikivoyageDataAsyncTask(resetData: resetData)
        task.delegate = self
        task.execute()
    }

    override func generateData() {
        
        tableData.clearAllData()
        
        if screenMode == .popularArticles {
            
            guard isInited  else { return }
            
            downloadingCellHelper.fetchResourcesBlock()
            
            if TravelObfHelper.shared.isOnlyDefaultTravelBookPresent() {
                
                let downloadSection = tableData.createNewSection()
                
                let downloadHeaderRow = downloadSection.createNewRow()
                downloadHeaderRow.cellType = OARightIconTableViewCell.getIdentifier()
                downloadHeaderRow.title = localizedString("download_file")
                downloadHeaderRow.iconName = "ic_custom_import"
                downloadHeaderRow.setObj(true, forKey: "kHideSeparator")
                
                let downloadDescrRow = downloadSection.createNewRow()
                downloadDescrRow.cellType = OARightIconTableViewCell.getIdentifier()
                downloadDescrRow.descr = localizedString("travel_card_download_descr")
                downloadDescrRow.setObj(false, forKey: "kHideSeparator")
                
                for _ in downloadingResources {
                    let row = downloadSection.createNewRow()
                    row.cellType = "kDownloadCellKey"
                }
                
            } else {
                
                // TODO: Add "Start editing Wikivoyage" card
                //        if (!Version.isPaidVersion(app) && !OpenBetaTravelCard.isClosed()) {
                //            items.add(new OpenBetaTravelCard(activity, nightMode));
                //        }
                
                let articles = TravelObfHelper.shared.getPopularArticles()
                if !articles.isEmpty {
                    
                    let articlesSection = tableData.createNewSection()
                    articlesSection.headerText = localizedString("popular_destinations")
                    
                    for article in articles {
                        if article is TravelGpx {
                            if let item: TravelGpx = article as? TravelGpx {
                                let gpxRow = articlesSection.createNewRow()
                                var title = item.title ?? ""
                                if let descr = item.descr, !descr.isEmpty {
                                    title = descr
                                }
                                item.title = title
                                gpxRow.cellType = GpxTravelCell.getIdentifier()
                                gpxRow.title = title
                                gpxRow.descr = item.user
                                gpxRow.setObj(item, forKey: "article")
                                
                                let analysis = item.getAnalysis()
                                let statisticsCells = OATrackMenuHeaderView.generateGpxBlockStatistics(analysis, withoutGaps: false)
                                gpxRow.setObj(statisticsCells, forKey: "statistics_cells")
                            }     
                        } else {
                            
                            let item: TravelArticle = article
                            let articleRow = articlesSection.createNewRow()
                            articleRow.cellType = ArticleTravelCell.getIdentifier()
                            articleRow.title = item.title ?? "nil"
                            articleRow.descr = OATravelGuidesHelper.getPatrialContent(item.content)
                            articleRow.setObj(item.getGeoDescription() ?? "", forKey: "isPartOf")
                            articleRow.setObj(item, forKey: "article")
                            articleRow.setObj(item.lang, forKey: "lang")
                            if let imageTitle = item.imageTitle, !imageTitle.isEmpty {
                                articleRow.iconName = TravelArticle.getImageUrl(imageTitle: item.imageTitle ?? "", thumbnail: false)
                            }
                        }
                    }
                    
                    let showMoreButtonRow = articlesSection.createNewRow()
                    showMoreButtonRow.cellType = OAFilledButtonCell.getIdentifier()
                    showMoreButtonRow.title = localizedString("show_more")
                    showMoreButtonRow.setObj("onShowMoreMapsClicked", forKey: "actionName")
                } else {
                    if isDataLoaded {
                        let section = tableData.createNewSection()
                        let headerTitleRow = section.createNewRow()
                        headerTitleRow.cellType = OARightIconTableViewCell.getIdentifier()
                        headerTitleRow.iconName = "ic_custom_search"
                        headerTitleRow.title = localizedString("popular_articles_not_found_title")
                        headerTitleRow.setObj(true, forKey: "kHideSeparator")
                        
                        let headerDescrRow = section.createNewRow()
                        headerDescrRow.cellType = OARightIconTableViewCell.getIdentifier()
                        headerDescrRow.descr = localizedString("popular_articles_not_found_descr")
                        headerDescrRow.setObj(false, forKey: "kHideSeparator")
                    }
                }
            }
        } else if screenMode == .history {
            
            let section = tableData.createNewSection()
            
            if TravelObfHelper.shared.isOnlyDefaultTravelBookPresent() {
                let headerTitleRow = section.createNewRow()
                headerTitleRow.cellType = OARightIconTableViewCell.getIdentifier()
                headerTitleRow.title = localizedString("no_travel_guides_data_title")
                headerTitleRow.iconName = "ic_custom_import"
                headerTitleRow.setObj(true, forKey: "kHideSeparator")
                
                let headerDescrRow = section.createNewRow()
                headerDescrRow.cellType = OARightIconTableViewCell.getIdentifier()
                headerDescrRow.descr = localizedString("no_travel_guides_data_descr")
                headerDescrRow.setObj(false, forKey: "kHideSeparator")
            } else {
                let historyItems = TravelObfHelper.shared.getBookmarksHelper().getAllHistory()
                for item in historyItems.reversed() {
                    let resultRow = section.createNewRow()
                    resultRow.cellType = SearchTravelCell.getIdentifier()
                    resultRow.title = item.articleTitle
                    resultRow.descr = item.isPartOf
                    resultRow.setObj("ic_custom_history", forKey: "noImageIcon")
                    if let imageTitle = item.imageTitle, !imageTitle.isEmpty {
                        resultRow.iconName = TravelArticle.getImageUrl(imageTitle: imageTitle, thumbnail: true)
                    }
                }
                let clearHistoryRow = section.createNewRow()
                clearHistoryRow.cellType = OASimpleTableViewCell.getIdentifier()
                clearHistoryRow.title = localizedString("clear_history")
                clearHistoryRow.iconName = "ic_custom_history"
            }
        } else if screenMode == .searchResults {
            
            let section = tableData.createNewSection()
            
            if TravelObfHelper.shared.isOnlyDefaultTravelBookPresent() {
                let headerTitleRow = section.createNewRow()
                headerTitleRow.cellType = OARightIconTableViewCell.getIdentifier()
                headerTitleRow.title = localizedString("no_travel_guides_data_title")
                headerTitleRow.iconName = "ic_custom_import"
                headerTitleRow.setObj(NSNumber(booleanLiteral: true), forKey: "kHideSeparator")
                
                let headerDescrRow = section.createNewRow()
                headerDescrRow.cellType = OARightIconTableViewCell.getIdentifier()
                headerDescrRow.descr = localizedString("no_travel_guides_data_descr")
                headerDescrRow.setObj(NSNumber(booleanLiteral: false), forKey: "kHideSeparator")
            }
            
            if !searchResults.isEmpty && !searchQuery.isEmpty {
                for item in searchResults {
                    let resultRow = section.createNewRow()
                    resultRow.cellType = SearchTravelCell.getIdentifier()
                    resultRow.title = item.getArticleTitle()
                    resultRow.descr = item.isPartOf
                    resultRow.setObj(item.articleId, forKey: "articleId")
                    
                    resultRow.setObj("ic_custom_photo", forKey: "noImageIcon")
                    if let imageTitle = item.imageTitle, !imageTitle.isEmpty {
                        resultRow.iconName = TravelArticle.getImageUrl(imageTitle: imageTitle, thumbnail: true)
                    }
                }
            }
        }
    }
    
    func setupDownloadingCellHelper() {
        downloadingCellHelper = OADownloadingCellHelper()
        downloadingCellHelper.hostViewController = self
        downloadingCellHelper.hostTableView = self.tableView
        downloadingCellHelper.hostDataLock = dataLock
        
        downloadingCellHelper.fetchResourcesBlock = { [weak self] in
            guard let self else { return }
            if var downloadingResouces = OAResourcesUISwiftHelper.getResourcesInRepositoryIds(byRegionId: "travel", resourceTypeNames: ["travel"]) {
                downloadingResouces.sort(by: { a, b in
                    a.title() < b.title()
                })
                self.downloadingResources = downloadingResouces
            }
        }
        
        downloadingCellHelper.getSwiftResourceByIndexBlock = { [weak self] (indexPath: IndexPath?) -> OAResourceSwiftItem? in
            guard let self else { return nil }
            let headerCellsCountInResourcesSection = self.headerCellsCountInResourcesSection()
            if let indexPath, indexPath.row >= headerCellsCountInResourcesSection {
                let index = indexPath.row - headerCellsCountInResourcesSection
                if self.downloadingResources.count > index {
                    return self.downloadingResources[index]
                }
            }
            return nil
        }
        
        downloadingCellHelper.getTableDataModelBlock = { [weak self] in
            guard let self else { return nil }
            return self.tableData
        }
    }
    
    func headerCellsCountInResourcesSection() -> Int {
        2
    }
    
    func notDownloadImages() -> Bool {
        guard let imagesDownloadMode = OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode else {return false}
        return imagesDownloadMode.isDontDownload() || (imagesDownloadMode.isDownloadOnlyViaWifi() && AFNetworkReachabilityManagerWrapper.isReachableViaWWAN())
    }
    
    // MARK: Actions
    
    @objc func update() {
        DispatchQueue.main.async {
            self.generateData()
            self.tableView.reloadData()
        }
    }
    
    @objc func populateAndUpdate() {
        TravelObfHelper.shared.loadPopularArticles()
        update()
    }
    
    func onOptionsButtonClicked() {
        let vc = TravelGuidesSettingsViewController()
        showModalViewController(vc)
    }
    
    func openArticle(article: TravelArticle, lang: String?) {
        if article is TravelGpx {
            view.addSpinner(inCenterOfCurrentView: true)
            openGpx(gpx: article as! TravelGpx)
        } else {
            let vc = TravelArticleDialogViewController.init(articleId: article.generateIdentifier(), lang: lang ?? "")
            vc.delegate = self
            show(vc)
        }
    }
    
    func openGpx(gpx: TravelGpx) {
        isPointsReadingMode = false
        view.addSpinner(inCenterOfCurrentView: true)
        TravelObfHelper.shared.getArticleById(articleId: gpx.generateIdentifier(), lang: nil, readGpx: true, callback: self)
    }
    
    @objc func onShowMoreMapsClicked() {
        populateData(resetData: false)
    }
    
    func showClearHistoryAlert() {
        let alert = UIAlertController(title: localizedString("search_history"), message: localizedString("clear_travel_search_history"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .default, handler: { [weak self] a in
            guard let self else { return }
            TravelObfHelper.shared.getBookmarksHelper().clearHistory()
            self.screenMode = .popularArticles
            self.generateData()
            self.tableView.reloadData()
            OAUtilities.showToast(nil, details: localizedString("cleared_travel_search_history"), duration: 4, in: self.view)
        }))
        present(alert, animated: true)
    }
    
    
    // MARK: TableView
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == "kDownloadCellKey" {
            let resource = downloadingCellHelper.getSwiftResourceByIndexBlock(indexPath)
            outCell = downloadingCellHelper.setupSwiftCell(resource, indexPath: indexPath)
        } else if item.cellType == OAFilledButtonCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAFilledButtonCell.getIdentifier()) as? OAFilledButtonCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAFilledButtonCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAFilledButtonCell
                cell?.selectionStyle = .none
            }
            cell?.button.setTitle(item.title, for: .normal)
            cell?.button.removeTarget(nil, action: nil, for: .allEvents)
            if let actionName = item.string(forKey: "actionName") {
                cell?.button.addTarget(self, action: Selector(actionName), for: .touchUpInside)
            }
            outCell = cell
        } else if item.cellType == OARightIconTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.getIdentifier()) as? OARightIconTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OARightIconTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OARightIconTableViewCell
                cell?.selectionStyle = .none
                cell?.leftIconVisibility(false)
                cell?.titleLabel.textColor = UIColor.textColorPrimary
                cell?.descriptionLabel.textColor = UIColor.textColorSecondary
            }
            if let cell {
                if let title = item.title {
                    cell.titleLabel.text = title
                    cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
                    cell.titleVisibility(true)
                } else {
                    cell.titleVisibility(false)
                }
                
                if let descr = item.descr {
                    cell.descriptionLabel.text = descr
                    cell.descriptionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    cell.descriptionVisibility(true)
                } else {
                    cell.descriptionVisibility(false)
                }
                
                if let iconName = item.iconName {
                    cell.rightIconView.image = UIImage.templateImageNamed(iconName)
                    cell.rightIconVisibility(true)
                } else {
                    cell.rightIconVisibility(false)
                }
                
                let hideSeparator = item.bool(forKey: "kHideSeparator")
                if hideSeparator {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
                } else {
                    cell.separatorInset = .zero
                }
            }
            
            outCell = cell
        } else if item.cellType == ArticleTravelCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: ArticleTravelCell.getIdentifier()) as? ArticleTravelCell
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
                    
                    //fetch image from db. if not found -  start async downloading.
                    imagesCacheHelper?.fetchSingleImage(byURL: imageUrl, customKey: nil, downloadMode: downloadMode, onlyNow: false) { [weak cell] imageAsBase64 in
                        guard let cell else { return }
                        DispatchQueue.main.async {
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
                } else {
                    cell.noImageIconVisibility(true)
                }
                
                cell.updateSaveButton()
                
                outCell = cell
            }
        } else if item.cellType == GpxTravelCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: GpxTravelCell.getIdentifier()) as? GpxTravelCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("GpxTravelCell", owner: self, options: nil)
                cell = nib?.first as? GpxTravelCell
                cell?.usernameIcon.contentMode = .scaleAspectFit
                cell?.usernameIcon.image = UIImage.templateImageNamed("ic_custom_user_profile")
                cell?.usernameIcon.tintColor = UIColor.iconColorActive
                cell?.usernameLabel.textColor = UIColor.textColorActive
            }
            if let cell {
                cell.arcticleTitle.text = item.title
                cell.usernameLabel.text = item.descr
                cell.travelGpx = item.obj(forKey: "article") as? TravelGpx
                if let statisticsCells = item.obj(forKey: "statistics_cells") as? [OAGPXTableCellData] {
                    cell.statisticsCells = statisticsCells
                }
                cell.usernameView.layer.borderColor = UIColor.customSeparator.cgColor
                cell.usernameView.layer.borderWidth = 1
                cell.usernameView.layer.cornerRadius = 4
                
                outCell = cell
            }
        } else if item.cellType == OATitleDescriptionBigIconCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OATitleDescriptionBigIconCell.getIdentifier()) as? OATitleDescriptionBigIconCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("OATitleDescriptionBigIconCell", owner: self, options: nil)
                cell = nib?.first as? OATitleDescriptionBigIconCell
                cell?.showLeftIcon(false)
                cell?.showRightIcon(true)
                cell?.rightIconView.layer.cornerRadius = 5
            }
            if let cell {
                cell.titleView.text = item.title
                cell.descriptionView.text = item.descr
            }
        } else if item.cellType == SearchTravelCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: SearchTravelCell.getIdentifier()) as? SearchTravelCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("SearchTravelCell", owner: self, options: nil)
                cell = nib?.first as? SearchTravelCell
                cell?.imagePreview.layer.cornerRadius = 5
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                
                if let noImageIconName = item.string(forKey: "noImageIcon") {
                    cell.noImageIcon.image = UIImage(named: noImageIconName)
                }

                if let imageUrl = item.iconName, let downloadMode = OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode {
                    
                    // fetch image from db. if not found - start async downloading
                    imagesCacheHelper?.fetchSingleImage(byURL: imageUrl, customKey: nil, downloadMode: downloadMode, onlyNow: false) { [weak cell] imageAsBase64 in
                        guard let cell else { return }
                        DispatchQueue.main.async {
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
                } else {
                    cell.noImageIconVisibility(true)
                }
            }
            outCell = cell
        } else if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.tintColor = UIColor.iconColorActive
                cell?.descriptionVisibility(false)
            }
            if let cell = cell {
                cell.titleLabel.text = item.title
                cell.titleLabel.textColor = UIColor.textColorActive
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named: iconName)
                }
                cell.leftIconView.tintColor = UIColor.iconColorActive
            }
            outCell = cell
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        lastSelectedIndexPath = indexPath
        if item.cellType == "kDownloadCellKey" {
            downloadingCellHelper.onItemClicked(indexPath)
            
        } else if item.cellType == ArticleTravelCell.getIdentifier() || item.cellType == GpxTravelCell.getIdentifier()  {
            if let article = item.obj(forKey: "article") as? TravelArticle {
                let lang = item.string(forKey: "lang") ?? ""
                openArticle(article: article, lang: lang)
            }
            
        } else if item.cellType == SearchTravelCell.getIdentifier() {
            var articleId = item.obj(forKey: "articleId") as? TravelArticleIdentifier
            let lang = OAUtilities.currentLang() ?? ""
            if articleId == nil {
                articleId = TravelObfHelper.shared.getArticleId(title: item.title ?? "", lang: lang)
            }
            if let articleId {
                let language = lang == "" ? "eng" : lang
                if let article = TravelObfHelper.shared.getArticleById(articleId: articleId, lang: language, readGpx: false, callback: nil) {
                    TravelObfHelper.shared.getBookmarksHelper().addToHistory(article: article)
                    openArticle(article: article, lang: lang)
                }
            }
        } else if item.cellType == OASimpleTableViewCell.getIdentifier() {
            showClearHistoryAlert()
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = tableData.item(for: indexPath)
        lastSelectedIndexPath = indexPath
        if item.cellType == ArticleTravelCell.getIdentifier() {
            if let article = item.obj(forKey: "article") as? TravelArticle {
                let lang = item.string(forKey: "lang") ?? ""
                
                let menuProvider: UIContextMenuActionProvider = { _ in
                    let readAction = UIAction(title: localizedString("shared_string_read"), image: UIImage(named: "ic_custom_file_read")) { [weak self] _ in
                        guard let self else { return }
                        self.openArticle(article: article, lang: lang)
                    }
                    
                    let isSaved = TravelObfHelper.shared.getBookmarksHelper().isArticleSaved(article: article)
                    let bookmarkAction = UIAction(title: localizedString(isSaved ? "shared_string_remove_bookmark" : "shared_string_bookmark"), image: UIImage(named: "ic_custom_bookmark_outlined")) { [weak self] _ in
                        guard let self else { return }
                        if isSaved {
                            TravelObfHelper.shared.getBookmarksHelper().removeArticleFromSaved(article: article)
                        } else {
                            TravelObfHelper.shared.getBookmarksHelper().addArticleToSaved(article: article)
                        }
                        self.generateData()
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                    let pointsAction = UIAction(title: localizedString("shared_string_gpx_points"), image: UIImage(named: "ic_custom_point_markers_outlined")) { [weak self] _ in
                        guard let self else { return }
                        self.isPointsReadingMode = true
                        self.view.addSpinner(inCenterOfCurrentView: true)
                        let _ = TravelObfHelper.shared.getArticleById(articleId: article.generateIdentifier(), lang: lang, readGpx: true, callback: self)
                    }
                    return UIMenu(title: "", children: [readAction, bookmarkAction, pointsAction])
                }
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
            }
        }
        return nil
    }

    // MARK: TravelExploreViewControllerDelegate
    
    func onDataLoaded() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isDataLoaded = true
            self.generateData()
            self.tableView.reloadData()
            self.view.removeSpinner()
        }
    }
    
    func close() {
        isGpxPointsOpening = true
        dismiss()
    }

    // MARK: GpxReadDelegate
    
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle) {
        // Open TravelGpx track
        article.gpxFile = gpxFile
        let filename = TravelObfHelper.shared.createGpxFile(article: article)
        OATravelGuidesHelper.createGpxFile(article, fileName: filename)
        let gpx = OATravelGuidesHelper.buildGpx(filename, title: article.title, document: gpxFile)
        
        view.removeSpinner()
        if isPointsReadingMode && (gpx == nil || gpx?.wptPoints == 0) {
            OAUtilities.showToast(nil, details: localizedString("article_has_no_points"), duration: 4, in: self.view)
            return
        }

        OAAppSettings.sharedManager().showGpx([filename], update: true)
        if let newCurrentHistory = navigationController?.saveCurrentStateForScrollableHud(), !newCurrentHistory.isEmpty {
            OARootViewController.instance().mapPanel.openTargetViewWithGPX(fromTracksList: gpx,
                                                                           navControllerHistory: newCurrentHistory,
                                                                           fromTrackMenu: false,
                                                                           selectedTab: .pointsTab)
        }
    }
    
    // MARK: Search
    
    func shouldShowSearch() -> Bool {
        !TravelObfHelper.shared.isOnlyDefaultTravelBookPresent()
    }
    
    private func setupSearchControllerWithFilter(_ isFiltered: Bool) {
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("travel_guides_search_placeholder"), attributes: [NSAttributedString.Key.foregroundColor: UIColor.textColorSecondary])
        if isFiltered {
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor.textColorPrimary
        } else {
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor.textColorSecondary
            searchController.searchBar.searchTextField.tintColor = UIColor.textColorSecondary
        }
    }
    
    func cancelSearch() {
        if let searchHelper {
            searchHelper.uiCanceled = true
            view.removeSpinner()
            searchResults = []
        }
    }
    
    func runSearch() {
        if let searchHelper {
            searchHelper.uiCanceled = false
            view.addSpinner(inCenterOfCurrentView: true)
            
            searchHelper.search(query: searchQuery) { [weak self] results in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.screenMode = .searchResults
                    self.generateData()
                    self.tableView.reloadData()
                    self.view.removeSpinner()
                }
            }
        }
    }
    
    // MARK: UISearchResultsUpdating

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        screenMode = .history
        isFiltered = true
        generateData()
        tableView.reloadData()
    }
        
    func updateSearchResults(for searchController: UISearchController) {
        generateData()
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelSearch()
        screenMode = .popularArticles
        isFiltered = false
        generateData()
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if isFiltered {
            searchResults = []
            searchQuery = searchText
            let trimmedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedSearchQuery.length == 0 {
                cancelSearch()
                screenMode = .history
            } else {
                runSearch()
                screenMode = .searchResults
                generateData()
            }
            generateData()
            tableView.reloadData()
        }
    }
}

final class LoadWikivoyageDataAsyncTask {
    weak var delegate: TravelExploreViewControllerDelegate?
    var travelHelper: TravelObfHelper
    var resetData: Bool
    
    init(resetData: Bool) {
        travelHelper = TravelObfHelper.shared
        self.resetData = resetData
    }
    
    func execute() {
        DispatchQueue.global(qos: .default).async {
            self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute()
            }
        }
    }
    
    func doInBackground() {
        travelHelper.initializeDataToDisplay(resetData: resetData)
    }
    
    func onPostExecute() {
        if let onDataLoaded = delegate?.onDataLoaded {
            onDataLoaded()
        }
    }
}

final class OATextFieldWithPadding: UITextField {
    var textPadding = UIEdgeInsets(
        top: 0,
        left: 16,
        bottom: 0,
        right: 16
    )

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}
