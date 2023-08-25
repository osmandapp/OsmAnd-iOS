//
//  TravelGuidesContentsViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelGuidesContentsViewController : OABaseButtonsViewController {
    
    var article: TravelArticle
    var selectedLang: String
    var items: TravelContentItem
    
    required init?(coder: NSCoder) {
        self.article = TravelArticle()
        self.selectedLang = ""
        self.items = TravelContentItem(name: "", link: nil)
        super.init(coder: coder)
    }
    
    init(article: TravelArticle, selectedLang: String) {
        self.article = article
        self.selectedLang = selectedLang
        self.items = TravelJsonParser.parseJsonContents(jsonText: article.contentsJson ?? "")
        super.init()
    }
    
    //MARK: Base UI setup
    
    override func getTitle() -> String! {
        return localizedString("shared_string_contents")
    }
    
    override func getBottomButtonTitle() -> String! {
        return localizedString("shared_string_close")
    }
    
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        
        for headerItem in items.subItems {
            let headerRow = section.createNewRow()
            
            print("!!! " + headerItem.name)
            
            if headerItem.subItems.count > 0 {
                for subheaderItem in headerItem.subItems {
                    print("!!! ----  " + subheaderItem.name)
                }
            }
        }
    }
    
    
    
    //MARK: Actions
    
    override func onBottomButtonPressed() {
        self.dismiss()
    }
}
