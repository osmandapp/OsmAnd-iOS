//
//  TopBottomValuesSliderTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 22.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class TopBottomValuesSliderTableViewCell: UITableViewCell {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var topLeftLabel: UILabel!
    @IBOutlet weak var topRightLabel: UILabel!
    @IBOutlet weak var bottomLeftLabel: UILabel!
    @IBOutlet weak var bottomRightLabel: UILabel!
    @IBOutlet weak var topRightButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var sliderValuesView: UIView!
    @IBOutlet private weak var segmentValuesView: UIView!
    @IBOutlet private var topRightLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var topRightButtonLeadingConstraint: NSLayoutConstraint!
    
    func topRightLabelVisibility(_ show: Bool) {
        topRightButton.isHidden = show
        topRightLabel.isHidden = !show
        topRightButtonLeadingConstraint.isActive = !show
        topRightLabelLeadingConstraint.isActive = show
    }
    
    func topRightButtonVisibility(_ show: Bool) {
        topRightButton.isHidden = !show
        topRightLabel.isHidden = show
        topRightButtonLeadingConstraint.isActive = show
        topRightLabelLeadingConstraint.isActive = !show
    }
    
    func sliderValuesVisibility(_ show: Bool) {
        sliderValuesView.isHidden = !show
        segmentValuesView.isHidden = show
    }
    
    func segmentValuesVisibility(_ show: Bool) {
        sliderValuesView.isHidden = show
        segmentValuesView.isHidden = !show
    }
}
