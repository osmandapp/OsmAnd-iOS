//
//  ExploreTabViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class ExploreTabViewController: OABaseNavbarViewController {
    
    weak var tabViewDelegate: TravelExploreViewControllerDelegate?
    
    var downloadingCellHelper: OADownloadingCellHelper = OADownloadingCellHelper()
    var dataLock: NSObject = NSObject()
    var downloadingResources: [OAResourceSwiftItem] = []
    var cachedPreviewImages: ImageCache = ImageCache(itemsLimit: 100)
    var lastSelectedIndexPath: IndexPath?
    
    
    override func viewDidLoad() {
        cachedPreviewImages = ImageCache(itemsLimit: 100)
        downloadingResources = []
        setupDownloadingCellHelper()
        super.viewDidLoad()
    }
    
    func update() {
        generateData()
        tableView.reloadData()
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
    
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_explore")
    }
    
    func headerCellsCountInResourcesSection() -> Int {
        return 2
    }
    
    override func generateData() {
        
        downloadingCellHelper.fetchResourcesBlock()
        
        tableData.clearAllData()
        
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
        
        //TODO:  add EditWiki card
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
    }
    
    
    //MARK: Actions
    
    @objc func onShowMoreMapsClicked() {
        if ((tabViewDelegate) != nil) {
            tabViewDelegate!.populateData(resetData: false)
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
            }
            if let cell {
                if let title = item.title {
                    cell.titleLabel.text = title
                    cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
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
                
                cell!.imagePreview.contentMode = .scaleAspectFill
                cell!.imagePreview.layer.cornerRadius = cell!.imagePreview.frame.width / 2
                cell!.leftButtonIcon.image = UIImage.templateImageNamed("ic_custom_clear_list")
                cell!.rightButtonIcon.image = UIImage.templateImageNamed("ic_custom_save_to_file")
                cell!.leftButtonIcon.tintColor = UIColor(rgb: color_purple_border)
                cell!.rightButtonIcon.tintColor = UIColor(rgb: color_purple_border)
                cell!.leftButtonLabel.textColor = UIColor(rgb: color_purple_border)
                cell!.rightButtonLabel.textColor = UIColor(rgb: color_purple_border)
            }
            cell!.tabViewDelegate = tabViewDelegate
            cell!.article = item.obj(forKey: "article") as? TravelArticle
            cell!.articleLang = item.string(forKey: "lang")
            
            cell!.arcticleTitle.text = item.title
            cell!.arcticleDescription.text = item.descr
            cell!.regionLabel.text = item.string(forKey: "isPartOf")
            
            cell!.leftButtonLabel.text = localizedString("shared_string_read")
            cell!.rightButtonLabel.text = localizedString("shared_string_bookmark")
            
            cell?.imageVisibility(true)
            if let iconName = item.iconName {
                startAsyncImageDownloading(iconName, cell)
            } else {
                cell?.imageVisibility(false)
            }
            
            outCell = cell
            
        } else if item.cellType == GpxTravelCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: GpxTravelCell.getIdentifier()) as? GpxTravelCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("GpxTravelCell", owner: self, options: nil)
                cell = nib?.first as? GpxTravelCell
                cell!.usernameIcon.contentMode = .scaleAspectFit
                cell!.usernameIcon.image = UIImage.templateImageNamed("ic_custom_user_profile")
                cell!.usernameIcon.tintColor = UIColor(rgb: color_purple_border)
                cell!.usernameLabel.textColor = UIColor(rgb: color_purple_border)
                cell!.usernameView.layer.borderColor = UIColor(rgb: color_slider_gray).cgColor
                cell!.usernameView.layer.borderWidth = 1
                cell!.usernameView.layer.cornerRadius = 4
                
                cell!.leftButtonIcon.image = UIImage.templateImageNamed("ic_custom_clear_list")
                cell!.rightButtonIcon.image = UIImage.templateImageNamed("ic_custom_save_to_file")
                cell!.leftButtonIcon.tintColor = UIColor(rgb: color_purple_border)
                cell!.rightButtonIcon.tintColor = UIColor(rgb: color_purple_border)
                cell!.leftButtonLabel.textColor = UIColor(rgb: color_purple_border)
                cell!.rightButtonLabel.textColor = UIColor(rgb: color_purple_border)
            }
            cell!.tabViewDelegate = tabViewDelegate
            cell!.arcticleTitle.text = item.title
            cell!.usernameLabel.text = item.descr
            cell!.travelGpx = item.obj(forKey: "article") as? TravelGpx
            cell!.leftButtonLabel.text = localizedString("shared_string_view")
            cell!.rightButtonLabel.text = localizedString("shared_string_save")
            if let statisticsCells = item.obj(forKey: "statistics_cells") as? [OAGPXTableCellData] {
                cell!.statisticsCells = statisticsCells
            }
            
            outCell = cell
        }
        
        return outCell
    }
    
    private func startAsyncImageDownloading(_ iconName: String, _ cell: ArticleTravelCell?) {
        if let imageUrl = URL(string: iconName) {
            if let cachedImage = cachedPreviewImages.get(url: iconName) {
                if cachedImage.count != Data().count {
                    cell!.imagePreview.image = UIImage(data: cachedImage)
                    cell?.imageVisibility(true)
                } else {
                    cell?.imageVisibility(false)
                }
            } else {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: imageUrl) {
                        DispatchQueue.main.async {
                            self.cachedPreviewImages.set(url: iconName, imageData: data)
                            cell!.imagePreview.image = UIImage(data: data)
                            cell?.imageVisibility(true)
                        }
                    } else {
                        self.cachedPreviewImages.set(url: iconName, imageData: Data())
                        cell?.imageVisibility(false)
                    }
                }
            }
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        lastSelectedIndexPath = indexPath
        if item.cellType == "kDownloadCellKey" {
            downloadingCellHelper.onItemClicked(indexPath)
            
        } else if item.cellType == ArticleTravelCell.getIdentifier() || item.cellType == GpxTravelCell.getIdentifier()  {
            if let article = item.obj(forKey: "article") as? TravelArticle {
                let lang = item.string(forKey: "lang") ?? ""
                if tabViewDelegate != nil {
                    tabViewDelegate!.openArticle(article: article, lang: lang)
                }
            }
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
