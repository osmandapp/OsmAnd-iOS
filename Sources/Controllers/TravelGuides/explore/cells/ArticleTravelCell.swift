//
//  ArticleTravelCell.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class ArticleTravelCell: UITableViewCell {
    

    @IBOutlet weak var arcticleTitle: UILabel!
    @IBOutlet weak var arcticleDescription: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var noImageIcon: UIImageView!
    
    @IBOutlet weak var bookmarkIcon: UIImageView!
    
    weak var tabViewDelegate: TravelExploreViewControllerDelegate?
    var article: TravelArticle?
    var articleLang: String?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSaveButton()
    }
    
    func imageVisibility(_ show: Bool) {
        imagePreview.isHidden = !show
    }
    
    func noImageIconVisibility(_ show: Bool) {
        noImageIcon.isHidden = !show
    }
    
    func updateSaveButton() {
        DispatchQueue.main.async {
            let isSaved = TravelObfHelper.shared.getBookmarksHelper().isArticleSaved(article: self.article!)
            self.bookmarkIcon.image = isSaved ? UIImage.templateImageNamed("ic_custom20_bookmark") : nil
        }
    }

}
