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
//    var canceled = false
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
        searchView?.frame = CGRect(x: 0, y: super.getNavbarHeight(), width: view.frame.width, height: 46 + offset)
        searchTextField?.frame = CGRect(x: 8 + OAUtilities.getLeftMargin(), y: offset, width: searchView!.frame.width - 16 - 2 * OAUtilities.getLeftMargin(), height: 38)
    }
    
    func setupSearchView() {
        let offset: CGFloat = OAUtilities.isLandscape() ? 0 : 8
        searchView = UIView()
        searchView?.backgroundColor = UIColor(rgb: color_primary_table_background)
        searchView?.frame = CGRect(x: 0, y: super.getNavbarHeight(), width: view.frame.width, height: 46 + offset)
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
                resultRow.cellType = OAValueTableViewCell.getIdentifier()
                resultRow.title = item.getArticleTitle()
                resultRow.descr = item.isPartOf
                resultRow.setObj(item.articleId, forKey: "articleId")
                
                
                if (item.imageTitle != nil && item.imageTitle!.length > 0) {
                    resultRow.iconName = TravelArticle.getImageUrl(imageTitle: item.imageTitle ?? "", thumbnail: true)
                }
                
                if let langs = item.langs  {
                    var langsString = ""
                    for i in 0..<3 {
                        if langs.count > i {
                            langsString += langs[i].capitalized + ", "
                        }
                    }
                    if langsString.hasPrefix(", ") {
                        langsString = langsString.substring(to: langsString.count - 2)
                    }
                    resultRow.setObj(langsString, forKey: "langs")
                }
            }
            
        } else {
            let section = tableData.createNewSection()
            section.headerText = localizedString("shared_string_history")
            
            //TODO: Add history items
        }
        
        tableView.reloadData()
    }
    
    
    //MARK: Actions
    
    private func startAsyncImageDownloading(_ iconName: String, _ cell: OAValueTableViewCell) {
        if let imageUrl = URL(string: iconName) {
            if let cachedImage = cachedPreviewImages.get(url: iconName) {
                if cachedImage.count != Data().count {
                    cell.leftIconView.image = UIImage(data: cachedImage)
                    cell.leftIconVisibility(true)
                } else {
                    cell.leftIconVisibility(false)
                }
            } else {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: imageUrl) {
                        DispatchQueue.main.async {
                            self.cachedPreviewImages.set(url: iconName, imageData: data)
                            cell.leftIconView.image = UIImage(data: data)
                            cell.leftIconVisibility(true)
                        }
                    } else {
                        self.cachedPreviewImages.set(url: iconName, imageData: Data())
                        cell.leftIconVisibility(false)
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
        if item.cellType == OAValueTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.getIdentifier()) as? OAValueTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed("OAValueTableViewCell", owner: self, options: nil)
                cell = nib?.first as? OAValueTableViewCell
                cell?.descriptionVisibility(true)
                cell?.leftIconView.contentMode = .scaleAspectFill
                cell?.leftIconView.layer.cornerRadius = cell!.leftIconView.frame.width / 2
            }
            if let cell {
                cell.valueLabel.text = item.title
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                cell.leftIconView.tintColor = UIColor(rgb: item.iconTint)
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                cell.valueLabel.text = item.string(forKey: "langs")
                if let iconName = item.iconName {
                    cell.leftIconVisibility(true)
                    startAsyncImageDownloading(iconName, cell)
                } else {
                    cell.leftIconVisibility(false)
                }
                outCell = cell
            }
        }
        
        return outCell;
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.getIdentifier() {
            if let articleId = item.obj(forKey: "articleId") as? TravelArticleIdentifier {
                let language = lang == "en" ? "" : lang
                if let article = TravelObfHelper.shared.getArticleById(articleId: articleId, lang: language, readGpx: false, callback: nil) {
                    dismiss()
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
