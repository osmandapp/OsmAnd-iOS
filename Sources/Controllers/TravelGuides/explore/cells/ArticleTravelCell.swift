//
//  ArticleTravelCell.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

protocol TravelGuideCellCashable {
    func setImage(data: Data)
    func noImageIconVisibility(_ show: Bool)
}

@objc(OAArticleTravelCell)
@objcMembers
final class ArticleTravelCell: UITableViewCell, TravelGuideCellCashable {

    @IBOutlet weak var arcticleTitle: UILabel!
    @IBOutlet weak var arcticleDescription: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var noImageIcon: UIImageView!
    
    @IBOutlet weak var bookmarkIcon: UIImageView!
    
    var article: TravelArticle?
    var articleLang: String?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSaveButton()
    }

    override static func getIdentifier() -> String {
        self.reuseIdentifier 
    }

    func setImage(data: Data) {
        imagePreview.image = UIImage(data: data)
    }
    
    func imageVisibility(_ show: Bool) {
        imagePreview.isHidden = !show
    }
    
    func noImageIconVisibility(_ show: Bool) {
        noImageIcon.isHidden = !show
    }

    func bookmarkIconVisibility(_ show: Bool) {
        bookmarkIcon.isHidden = !show
    }

    func updateSaveButton() {
        DispatchQueue.main.async {
            if let article = self.article {
                let isSaved = TravelObfHelper.shared.getBookmarksHelper().isArticleSaved(article: self.article!)
                self.bookmarkIcon.image = isSaved ? UIImage(named: "ic_custom20_bookmark") : nil
            }
        }
    }

}
