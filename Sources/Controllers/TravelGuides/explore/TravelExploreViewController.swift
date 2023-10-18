//
//  TravelExploreViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

protocol TravelExploreViewControllerDelegate : AnyObject {
    func populateData(resetData: Bool)
    func onDataLoaded()
    func openArticle(article: TravelArticle, lang: String?)
    func onOpenArticlePoints()
    func close()
}


@objc(OATravelExploreViewController)
@objcMembers
class TravelExploreViewController: OABaseNavbarViewController, TravelExploreViewControllerDelegate, GpxReadDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    enum ScreenModes {
        case popularArticles
        case history
        case searchResults
    }
  
    var searchController: UISearchController!
    var downloadingCellHelper: OADownloadingCellHelper = OADownloadingCellHelper()
    var dataLock: NSObject = NSObject()
    var downloadingResources: [OAResourceSwiftItem] = []
    var cachedPreviewImages: ImageCache = ImageCache(itemsLimit: 100)
    var lastSelectedIndexPath: IndexPath?
    var savedArticlesObserver: OAAutoObserverProxy = OAAutoObserverProxy()
    var isGpxReading = false
    var isPointsReadingMode = false
    var searchHelper: TravelSearchHelper?
    var searchQuery = ""
    var searchResults = [TravelSearchResult]()
    var isFiltered = false
    var screenMode: ScreenModes = .popularArticles
    var isInited = false
    
    override func commonInit() {
        super.commonInit()
        searchQuery = ""
        searchHelper = TravelSearchHelper()
        searchHelper!.uiCanceled = false
        searchResults = []
        cachedPreviewImages = ImageCache(itemsLimit: 100)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        setupSearchControllerWithFilter(false)
        isInited = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        screenMode = .popularArticles
        cachedPreviewImages = ImageCache(itemsLimit: 100)
        downloadingResources = []
        setupDownloadingCellHelper()
        savedArticlesObserver = OAAutoObserverProxy(self, withHandler: #selector(update), andObserve: TravelObfHelper.shared.getBookmarksHelper().observable)
        
        if OAAppSettings.sharedManager().travelGuidesState.wasWatchingGpx {
            restoreState()
        } else {
            populateData(resetData: true)
        }
    }
    
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        return localizedString("shared_string_back")
    }
    
    override func forceShowShevron() -> Bool {
        return true
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let optionsButton = createRightNavbarButton(nil, iconName: "ic_navbar_overflow_menu_stroke", action: #selector(onOptionsButtonClicked), menu: nil)
        optionsButton?.accessibilityLabel = localizedString("shared_string_options")
        return [optionsButton!]
    }
    
    func populateData(resetData: Bool) {
        self.view.addSpinner(inCenterOfCurrentView: true)
        let task = LoadWikivoyageDataAsyncTask(resetData: resetData)
        task.delegate = self;
        task.execute()
    }
    
    func saveState() {
        if let state = OAAppSettings.sharedManager().travelGuidesState {
            state.downloadingResources = downloadingResources
            state.cachedPreviewImages = cachedPreviewImages
            state.exploreTabTableData = tableData
            state.lastSelectedIndexPath = lastSelectedIndexPath
        }
    }
    
    func restoreState() {
        if let state = OAAppSettings.sharedManager().travelGuidesState {
            setupDownloadingCellHelper()
            downloadingResources = state.downloadingResources
            cachedPreviewImages = state.cachedPreviewImages!
            lastSelectedIndexPath = state.lastSelectedIndexPath
            
            tableData.clearAllData()
            for i in 0..<state.exploreTabTableData!.sectionCount() {
                tableData.addSection(state.exploreTabTableData!.sectionData(for: i))
            }
            tableView.reloadData()
            tableView.scrollToRow(at: state.lastSelectedIndexPath!, at: .middle, animated: false)
        }
        
        let wasOpenedTravelGpx = OAAppSettings.sharedManager().travelGuidesState.article == nil
        if wasOpenedTravelGpx  {
            OAAppSettings.sharedManager().travelGuidesState.resetData()
        } else {
            let vc = TravelArticleDialogViewController.init()
            vc.delegate = self
            self.show(vc)
        }
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
                downloadHeaderRow.setObj(NSNumber(booleanLiteral: true), forKey: "kHideSeparator")
                
                let downloadDescrRow = downloadSection.createNewRow()
                downloadDescrRow.cellType = OARightIconTableViewCell.getIdentifier()
                downloadDescrRow.descr = localizedString("travel_card_download_descr")
                downloadDescrRow.setObj(NSNumber(booleanLiteral: false), forKey: "kHideSeparator")
                
                for _ in downloadingResources {
                    let row = downloadSection.createNewRow()
                    row.cellType = "kDownloadCellKey"
                }
                
            } else {
                
                //        if (!Version.isPaidVersion(app) && !OpenBetaTravelCard.isClosed()) {
                //            items.add(new OpenBetaTravelCard(activity, nightMode));
                //        }
                
                //TODO:  add TravelNeededMaps Card for bookmarks
            
                
                let articles = TravelObfHelper.shared.getPopularArticles()
                if articles.count > 0 {
                    
                    let articlesSection = tableData.createNewSection()
                    articlesSection.headerText = localizedString("popular_destinations")
                    
                    for article in articles {
                        if article is TravelGpx {
                            let item: TravelGpx = article as! TravelGpx
                            let gpxRow = articlesSection.createNewRow()
                            let title = (item.descr != nil && item.descr!.count > 0) ? item.descr! : item.title
                            item.title = title
                            gpxRow.cellType = GpxTravelCell.getIdentifier()
                            gpxRow.title = title
                            gpxRow.descr = item.user
                            gpxRow.setObj(item, forKey: "article")
                            
                            let analysis = item.getAnalysis()
                            let statisticsCells = OATrackMenuHeaderView.generateGpxBlockStatistics(analysis, withoutGaps: false)
                            gpxRow.setObj(statisticsCells, forKey: "statistics_cells")
                            
                        } else {
                            
                            let item: TravelArticle = article
                            let articleRow = articlesSection.createNewRow()
                            articleRow.cellType = ArticleTravelCell.getIdentifier()
                            articleRow.title = item.title ?? "nil"
                            articleRow.descr = OATravelGuidesHelper.getPatrialContent(item.content)
                            articleRow.setObj(item.getGeoDescription() ?? "", forKey: "isPartOf")
                            articleRow.setObj(item, forKey: "article")
                            articleRow.setObj(item.lang, forKey: "lang")
                            if (item.imageTitle != nil && item.imageTitle!.length > 0) {
                                articleRow.iconName = TravelArticle.getImageUrl(imageTitle: item.imageTitle ?? "", thumbnail: false)
                            }
                        }
                    }
                    
                    let showMoreButtonRow = articlesSection.createNewRow()
                    showMoreButtonRow.cellType = OAFilledButtonCell.getIdentifier()
                    showMoreButtonRow.title = localizedString("show_more")
                    showMoreButtonRow.setObj("onShowMoreMapsClicked", forKey: "actionName")
                }
            }
            
        } else if screenMode == .history {
            
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
                
            } else {
                
                let historyItems = TravelObfHelper.shared.getBookmarksHelper().getAllHistory()
                for item in historyItems.reversed() {
                    let resultRow = section.createNewRow()
                    resultRow.cellType = SearchTravelCell.getIdentifier()
                    resultRow.title = item.articleTitle
                    resultRow.descr = item.isPartOf
                    resultRow.setObj("ic_custom_history", forKey: "noImageIcon")
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
            
            if searchResults.count > 0 && searchQuery.length > 0 {
                for item in searchResults {
                    let resultRow = section.createNewRow()
                    resultRow.cellType = SearchTravelCell.getIdentifier()
                    resultRow.title = item.getArticleTitle()
                    resultRow.descr = item.isPartOf
                    resultRow.setObj(item.articleId, forKey: "articleId")
                    
                    resultRow.setObj("ic_custom_photo", forKey: "noImageIcon")
                    if (item.imageTitle != nil && item.imageTitle!.length > 0) {
                        resultRow.iconName = TravelArticle.getImageUrl(imageTitle: item.imageTitle ?? "", thumbnail: true)
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
        weak var weakself = self
        
        downloadingCellHelper.fetchResourcesBlock = {
            var downloadingResouces = OAResourcesUISwiftHelper.getResourcesInRepositoryIds(byRegionId: "travel", resourceTypeNames: ["travel"])
            if (downloadingResouces != nil) {
                downloadingResouces!.sort(by: { a, b in
                    a.title() < b.title()
                })
                weakself!.downloadingResources = downloadingResouces!
            }
        }
        
        downloadingCellHelper.getSwiftResourceByIndexBlock = { (indexPath: IndexPath?) -> OAResourceSwiftItem? in
            
            let headerCellsCountInResourcesSection = weakself!.headerCellsCountInResourcesSection()
            if (indexPath != nil && indexPath!.row >= headerCellsCountInResourcesSection) {
                return weakself!.downloadingResources[indexPath!.row - headerCellsCountInResourcesSection]
            }
            return nil
        }
        
        downloadingCellHelper.getTableDataModelBlock = {
            return weakself!.tableData
        }
    }
    
    func headerCellsCountInResourcesSection() -> Int {
        return 2
    }
    
    
    //MARK: Actions
    
    @objc func update() {
        DispatchQueue.main.async {
            self.generateData()
            self.tableView.reloadData()
        }
    }
    
    func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
        let vc = OABaseNavbarViewController()
        showModalViewController(vc)
    }
    
    func openArticle(article: TravelArticle, lang: String?) {
        if article is TravelGpx {
            self.view.addSpinner(inCenterOfCurrentView: true)
            openGpx(gpx: article as! TravelGpx)
        } else {
            let vc = TravelArticleDialogViewController.init(articleId: article.generateIdentifier(), lang: lang!)
            vc.delegate = self
            self.show(vc)
        }
    }
    
    func openGpx(gpx: TravelGpx) {
        isPointsReadingMode = false
        self.view.addSpinner(inCenterOfCurrentView: true)
        TravelObfHelper.shared.getArticleById(articleId: gpx.generateIdentifier(), lang: nil, readGpx: true, callback: self)
    }
    
    @objc func onShowMoreMapsClicked() {
        populateData(resetData: false)
    }
    
    func showClearHistoryAlert() {
        let alert = UIAlertController(title: localizedString("search_history"), message: localizedString("clear_travel_search_history"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .default, handler: { a in
            TravelObfHelper.shared.getBookmarksHelper().clearHistory()
            self.screenMode = .popularArticles
            self.generateData()
            self.tableView.reloadData()
        }))
        self.present(alert, animated: true)
    }
    
    private func startAsyncImageDownloading(_ iconName: String, _ cell: TravelGuideCellCashable?) {
        if let imageUrl = URL(string: iconName) {
            if let cachedImage = cachedPreviewImages.get(url: iconName) {
                if cachedImage.count != Data().count {
                    cell?.setImage(data: cachedImage)
                    cell?.noImageIconVisibility(false)
                } else {
                    cell?.noImageIconVisibility(true)
                }
            } else {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: imageUrl) {
                        DispatchQueue.main.async {
                            self.cachedPreviewImages.set(url: iconName, imageData: data)
                            cell?.setImage(data: data)
                            cell?.noImageIconVisibility(false)
                        }
                    } else {
                        self.cachedPreviewImages.set(url: iconName, imageData: Data())
                        cell?.noImageIconVisibility(true)
                    }
                }
            }
        }
    }
    
    
    //MARK: TableView
    
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
                cell!.imagePreview.contentMode = .scaleAspectFill
                cell!.imagePreview.layer.cornerRadius = 11
            }
            cell!.article = item.obj(forKey: "article") as? TravelArticle
            cell!.articleLang = item.string(forKey: "lang")
            
            cell!.arcticleTitle.text = item.title
            cell!.arcticleDescription.text = item.descr
            cell!.regionLabel.text = item.string(forKey: "isPartOf")

            cell?.imageVisibility(true)
            if let iconName = item.iconName {
                startAsyncImageDownloading(iconName, cell)
            } else {
                cell?.noImageIconVisibility(true)
            }
            cell?.updateSaveButton()
            
            outCell = cell
            
        } else if item.cellType == GpxTravelCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: GpxTravelCell.getIdentifier()) as? GpxTravelCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("GpxTravelCell", owner: self, options: nil)
                cell = nib?.first as? GpxTravelCell
                cell!.usernameIcon.contentMode = .scaleAspectFit
                cell!.usernameIcon.image = UIImage.templateImageNamed("ic_custom_user_profile")
                cell!.usernameIcon.tintColor = UIColor.iconColorActive
                cell!.usernameLabel.textColor = UIColor.iconColorActive
                cell!.usernameView.layer.borderColor = UIColor.textColorTertiary.cgColor
                cell!.usernameView.layer.borderWidth = 1
                cell!.usernameView.layer.cornerRadius = 4

            }
            cell!.arcticleTitle.text = item.title
            cell!.usernameLabel.text = item.descr
            cell!.travelGpx = item.obj(forKey: "article") as? TravelGpx
            if let statisticsCells = item.obj(forKey: "statistics_cells") as? [OAGPXTableCellData] {
                cell!.statisticsCells = statisticsCells
            }
            
            outCell = cell
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
                    cell.noImageIcon.image = UIImage.templateImageNamed(noImageIconName)
                }

                if let iconName = item.iconName {
                    startAsyncImageDownloading(iconName, cell)
                } else {
                    cell.noImageIcon.isHidden = false
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
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
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
                    let readAction = UIAction(title: localizedString("shared_string_read"), image: UIImage(systemName: "newspaper")) { _ in
                        self.openArticle(article: article, lang: lang)
                    }
                    let bookmarkAction = UIAction(title: localizedString("shared_string_bookmark"), image: UIImage(systemName: "bookmark")) { _ in
                        let isSaved = TravelObfHelper.shared.getBookmarksHelper().isArticleSaved(article: article)
                        if isSaved {
                            TravelObfHelper.shared.getBookmarksHelper().removeArticleFromSaved(article: article)
                        } else {
                            TravelObfHelper.shared.getBookmarksHelper().addArticleToSaved(article: article)
                        }
                        self.generateData()
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                    //shared_string_gpx_points
                    let pointsAction = UIAction(title: localizedString("shared_string_gpx_points"), image: UIImage.templateImageNamed("point.topleft.filled.down.to.point.bottomright.curvepath")) { _ in
                        self.isPointsReadingMode = true
                        self.view.addSpinner(inCenterOfCurrentView: true)
                        let article = TravelObfHelper.shared.getArticleById(articleId: article.generateIdentifier(), lang: lang, readGpx: true, callback: self)
                    }
                    return UIMenu(title: "", children: [readAction, bookmarkAction, pointsAction])
                }
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
            }
        }
        return nil
    }

    
    //MARK: TravelExploreViewControllerDelegate
    
    func onDataLoaded() {
        DispatchQueue.main.async {
            self.generateData()
            self.tableView.reloadData()
            self.view.removeSpinner()
        }
    }
    
    func close() {
        self.dismiss()
    }
    
    func onOpenArticlePoints() {
        saveState()
    }
    
    
    //MARK: GpxReadDelegate
    
    func onGpxFileReading() {
    }
    
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle) {
        //Open TravelGpx track
        article.gpxFile = gpxFile
        let filename = TravelObfHelper.shared.createGpxFile(article: article)
        OATravelGuidesHelper.createGpxFile(article, fileName: filename)
        let gpx = OATravelGuidesHelper.buildGpx(filename, title: article.title, document: gpxFile)
        
        self.view.removeSpinner()
        if isPointsReadingMode && (gpx == nil || gpx?.wptPoints == 0) {
            OAUtilities.showToast(nil, details: localizedString("article_has_no_points") , duration: 4, in: self.view)
            return
        }
        
        saveState()
        OAAppSettings.sharedManager().travelGuidesState.wasWatchingGpx = true
        
        OAAppSettings.sharedManager().showGpx([filename], update: true)
        let tab: EOATrackMenuHudTab = isPointsReadingMode ? .pointsTab : .overviewTab
        OARootViewController.instance().mapPanel.openTargetView(with: gpx, selectedTab: tab, selectedStatisticsTab: .overviewTab, openedFromMap: false)
        self.dismiss()
    }
    
    
    //MARK: Search
    
    func shouldShowSearch() -> Bool {
        return !TravelObfHelper.shared.isOnlyDefaultTravelBookPresent()
    }
    
    private func setupSearchControllerWithFilter(_ isFiltered: Bool) {
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("travel_guides_search_placeholder"), attributes: [NSAttributedString.Key.foregroundColor: UIColor(rgb: color_text_footer)])
        searchController.searchBar.searchTextField.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        if isFiltered {
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor(white: 0, alpha: 0.8)
        } else {
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor(white: 0, alpha: 0.3)
            searchController.searchBar.searchTextField.tintColor = UIColor.gray
        }
    }
    
    func cancelSearch() {
        searchHelper!.uiCanceled = true
        self.view.removeSpinner()
        searchResults = []
    }
    
    func runSearch() {
        searchHelper!.uiCanceled = false
        self.view.addSpinner(inCenterOfCurrentView: true)
        
        searchHelper!.search(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.screenMode = .searchResults
                self.generateData()
                self.tableView.reloadData()
                self.view.removeSpinner()
            }
        }
    }
    
    
    //MARK: UISearchResultsUpdating

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


class LoadWikivoyageDataAsyncTask {
    weak var delegate: TravelExploreViewControllerDelegate?
    var travelHelper: TravelObfHelper
    var resetData: Bool
    
    init (resetData: Bool) {
        travelHelper = TravelObfHelper.shared;
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
        if delegate != nil {
            delegate!.onDataLoaded()
        }
    }
}


class ImageCache {
    
    private var cache: [String : Data]
    private var itemsLimit: Int
    
    init(itemsLimit: Int) {
        cache = [:]
        self.itemsLimit = itemsLimit
    }
    
    func get(url: String) -> Data? {
        return cache[url]
    }
    
    func set(url: String, imageData: Data) {
        if cache.count > itemsLimit {
            cache.removeAll()
        }
        cache[url] = imageData
    }
}


class OATextFieldWithPadding: UITextField {
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
