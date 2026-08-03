//
//  OARangeSliderFilterTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 28.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

final class OARangeSliderFilterTableViewCell: UITableViewCell {
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minValueLabel: UILabel!
    @IBOutlet weak var maxValueLabel: UILabel!
    @IBOutlet weak var minTextField: UITextField!
    @IBOutlet weak var maxTextField: UITextField!
    @IBOutlet weak var rangeSlider: OARangeSlider!
    @IBOutlet private weak var verticalDividerView: UIView!
    @IBOutlet private weak var horizontalDividerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        verticalDividerView.backgroundColor = .adaptiveSeparator
        horizontalDividerView.backgroundColor = .adaptiveSeparator
        setupSliderView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupSliderView() {
        if rangeSlider.isDirectionRTL() {
            rangeSlider.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        }
        
        rangeSlider.handleImage = .icControlKnob
        rangeSlider.handleDiameter = 32
        rangeSlider.selectedHandleDiameterMultiplier = 1.0
    }
}
