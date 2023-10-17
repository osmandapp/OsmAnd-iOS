//
//  SearchTravelCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 12/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class SearchTravelCell : UITableViewCell, TravelGuideCellCashable {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var imagePreview: UIImageView!
    
    @IBOutlet weak var noImageIcon: UIImageView!
    
    func setImage(data: Data) {
        imagePreview.image = UIImage(data: data)
    }
    
    func noImageIconVisibility(_ show: Bool) {
        noImageIcon.isHidden = !show
    }
    
}
