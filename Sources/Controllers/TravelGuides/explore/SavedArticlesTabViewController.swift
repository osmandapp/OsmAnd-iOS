//
//  SavedArticlesTabViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class SavedArticlesTabViewController: OABaseNavbarViewController {
    
    weak var tabViewDelegate: TravelExploreViewControllerDelegate?
    
    var savedArticlesObserver: OAAutoObserverProxy = OAAutoObserverProxy()
    
    override func viewDidLoad() {
        savedArticlesObserver = OAAutoObserverProxy(self, withHandler: #selector(update), andObserve: TravelObfHelper.shared.getBookmarksHelper().observable)
        super.viewDidLoad()
    }
    
    override func getTitle() -> String! {
        localizedString("saved_articles")
    }
    
    @objc func update() {
        DispatchQueue.main.async {
            self.generateData()
            self.tableView?.reloadData()
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        let savedArticles = TravelObfHelper.shared.getBookmarksHelper().getSavedArticles()
        
        let section = tableData.createNewSection()
        section.headerText = localizedString("saved_articles")

        
        for article in savedArticles {
            let row = section.createNewRow()
            row.cellType = OARightIconTableViewCell.getIdentifier()
            row.title = article.title
            row.descr = article.isPartOf
            row.setObj(article, forKey: "article")
        }
    }
    
    //MARK: TableView
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OARightIconTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.getIdentifier()) as? OARightIconTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OARightIconTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OARightIconTableViewCell
                cell?.leftIconVisibility(false)
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
            }
            outCell = cell
        }
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let article = item.obj(forKey: "article") as? TravelArticle {
            tabViewDelegate!.openArticle(article: article, lang: article.lang)
        }
        
    }
}
