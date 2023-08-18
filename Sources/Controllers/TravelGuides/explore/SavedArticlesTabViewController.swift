//
//  SavedArticlesTabViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class SavedArticlesTabViewController: OABaseNavbarViewController {
    
    override func getTitle() -> String! {
        localizedString("saved_articles")
    }
    
    func update() {
        generateData()
        tableView?.reloadData()
    }
}
