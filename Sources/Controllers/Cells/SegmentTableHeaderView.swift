//
//  SegmentTableHeaderView.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 11/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class SegmentTableHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak private var segmentControl: UISegmentedControl!
    @IBOutlet weak private var separatorViewHeight: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        separatorViewHeight.constant = 1 / UIScreen.main.scale
    }
}
