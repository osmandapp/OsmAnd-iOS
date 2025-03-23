//
//  SegmentTextWithRightLabelTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 06.03.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class SegmentTextWithRightLabelTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var segmentedControlLeadingConstraint: NSLayoutConstraint!
    
    var didSelectSegmentIndex: ((Int) -> Void)?
    
    private var titles: [String]?
    private var selectedTitles: [String]?
    private var selectedSegmentIndex = 0
    
    func configureTitle(title: String?) {
        titleLabel.text = title
        let hasTitle = title != nil
        segmentedControlLeadingConstraint.priority = UILayoutPriority(hasTitle ? 1 : 1000)
        titleLabel.isHidden = !hasTitle
    }
    
    func configureSegmentedControl(titles: [String], selectedSegmentIndex: Int, selectedTitles: [String]? = nil) {
        self.selectedSegmentIndex = selectedSegmentIndex
        segmentedControl.removeAllSegments()
        self.titles = titles
        self.selectedTitles = selectedTitles
        for (index, title) in titles.enumerated() {
            segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        
        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        if let selectedTitles {
            segmentedControl.setTitle(selectedTitles[selectedSegmentIndex], forSegmentAt: selectedSegmentIndex)
        }
    }
    
    @IBAction private func segmentedControlButtonClickAction(_ sender: UISegmentedControl) {
        if let selectedTitles {
            segmentedControl.setTitle(selectedTitles[sender.selectedSegmentIndex], forSegmentAt: sender.selectedSegmentIndex)
        }
        if let titles {
            segmentedControl.setTitle(titles[selectedSegmentIndex], forSegmentAt: selectedSegmentIndex)
        }
        
        selectedSegmentIndex = sender.selectedSegmentIndex
        didSelectSegmentIndex?(sender.selectedSegmentIndex)
    }
}
