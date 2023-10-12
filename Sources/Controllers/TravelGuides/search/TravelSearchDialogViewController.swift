//
//  TravelSearchDialogViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelSearchDialogViewController : OABaseNavbarViewController, UITextFieldDelegate {
    
    weak var tabViewDelegate: TravelExploreViewControllerDelegate?
    
    var searchView: UIView?
    var searchTextField: UITextField?
    
    var searchHelper: TravelSearchHelper?
    var searchQuery = ""
    var searchResults = [TravelSearchResult]()
    
    var cachedPreviewImages: ImageCache = ImageCache(itemsLimit: 100)
    
    var lang = ""
    
    override func commonInit() {
        super.commonInit()
        searchQuery = ""
        searchHelper = TravelSearchHelper()
        searchHelper!.uiCanceled = false
        searchResults = []
        cachedPreviewImages = ImageCache(itemsLimit: 100)
    }
    
    override func viewDidLoad() {
        commonInit()
        setupSearchView()
        searchTextField?.becomeFirstResponder()
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        let offset: CGFloat = OAUtilities.isLandscape() ? 0 : 8
        let navbarHeight = navigationController!.navigationBar.frame.height + OAUtilities.getTopMargin()
        searchView?.frame = CGRect(x: 0, y: navbarHeight, width: view.frame.width, height: 46 + offset)
        searchTextField?.frame = CGRect(x: 8 + OAUtilities.getLeftMargin(), y: offset, width: searchView!.frame.width - 16 - 2 * OAUtilities.getLeftMargin(), height: 38)
    }
    
    func setupSearchView() {
        let offset: CGFloat = OAUtilities.isLandscape() ? 0 : 8
        let navbarHeight = navigationController!.navigationBar.frame.height + OAUtilities.getTopMargin()
        searchView = UIView()
        searchView?.backgroundColor = UIColor(rgb: color_primary_table_background)
        searchView?.frame = CGRect(x: 0, y: navbarHeight, width: view.frame.width, height: 46 + offset)
        view.addSubview(searchView!)
        
        searchTextField = OATextFieldWithPadding()
        searchTextField?.frame = CGRect(x: 8 + OAUtilities.getLeftMargin(), y: offset, width: searchView!.frame.width - 16 - 2 * OAUtilities.getLeftMargin(), height: 38)
        searchTextField?.layer.cornerRadius = 8
        searchTextField?.backgroundColor = .white
        searchTextField?.placeholder = localizedString("shared_string_search")
        searchTextField?.clearButtonMode = .whileEditing
        searchTextField?.delegate = self
        searchTextField?.becomeFirstResponder()
        searchView?.addSubview(searchTextField!)
    }
    
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_search")
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        if searchResults.count > 0 && searchQuery.length > 0 {
            let section = tableData.createNewSection()
            section.headerText = localizedString("shared_string_result")
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
            
        } else {
            let section = tableData.createNewSection()
            section.headerText = localizedString("shared_string_history")
            
            let historyItems = TravelObfHelper.shared.getBookmarksHelper().getAllHistory()
            for item in historyItems.reversed() {
                let resultRow = section.createNewRow()
                resultRow.cellType = SearchTravelCell.getIdentifier()
                resultRow.title = item.articleTitle
                resultRow.descr = item.isPartOf
                resultRow.setObj("ic_custom_history", forKey: "noImageIcon")
            }
        }
        
        tableView.reloadData()
    }
    
    
    //MARK: Actions
    
    private func startAsyncImageDownloading(_ iconName: String, _ cell: SearchTravelCell) {
        if let imageUrl = URL(string: iconName) {
            if let cachedImage = cachedPreviewImages.get(url: iconName) {
                if cachedImage.count != Data().count {
                    cell.imagePreview.image = UIImage(data: cachedImage)
                    cell.noImageIcon.isHidden = true
                } else {
                    cell.noImageIcon.isHidden = false
                }
            } else {
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        if let data = try? Data(contentsOf: imageUrl) {
                            self.cachedPreviewImages.set(url: iconName, imageData: data)
                            cell.imagePreview.image = UIImage(data: data)
                            cell.noImageIcon.isHidden = true
                        } else {
                            self.cachedPreviewImages.set(url: iconName, imageData: Data())
                            cell.noImageIcon.isHidden = false
                        }
                    }
                }
            }
        }
    }
    
    func cancelSearch() {
        searchHelper!.uiCanceled = true
        self.view.removeSpinner()
        searchResults = []
        generateData()
    }
    
    func runSearch() {
        searchHelper!.uiCanceled = false
        self.view.addSpinner()
        
        searchHelper!.search(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.generateData()
                self.view.removeSpinner()
            }
        }
    }
    
    
    //MARK: TableView
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == SearchTravelCell.getIdentifier() {
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
        }
        
        return outCell;
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.cellType == SearchTravelCell.getIdentifier() {
            var articleId = item.obj(forKey: "articleId") as? TravelArticleIdentifier
            if articleId == nil {
                articleId = TravelObfHelper.shared.getArticleId(title: item.title ?? "", lang: lang)
            }
            if let articleId {
                let language = lang == "en" ? "" : lang
                if let article = TravelObfHelper.shared.getArticleById(articleId: articleId, lang: language, readGpx: false, callback: nil) {
                    dismiss()
                    TravelObfHelper.shared.getBookmarksHelper().addToHistory(article: article)
                    tabViewDelegate?.openArticle(article: article, lang: lang)
                }
            }
        }
    }
    
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        return super.getCustomHeight(forHeader: section) + 84
    }
    
    
    //MARK: UITextFieldDelegate
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        searchResults = []
        searchQuery = textField.text ?? ""
        let trimmedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearchQuery.length == 0 {
            cancelSearch()
        } else {
            runSearch()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        cancelSearch()
    }
    
}
