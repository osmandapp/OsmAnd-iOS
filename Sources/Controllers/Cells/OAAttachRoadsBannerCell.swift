//
//  OAAttachRoadsBannerCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 19.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAAttachRoadsBannerCell)
@objcMembers
final class OAAttachRoadsBannerCell: UITableViewCell {
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
