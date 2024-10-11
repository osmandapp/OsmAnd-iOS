//
//  OARangeSliderFilterTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 28.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

class OARangeSliderFilterTableViewCell: UITableViewCell {
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minValueLabel: UILabel!
    @IBOutlet weak var maxValueLabel: UILabel!
    @IBOutlet weak var minTextField: UITextField!
    @IBOutlet weak var maxTextField: UITextField!
    @IBOutlet weak var rangeSlider: OARangeSlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSliderView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupSliderView() {
        if rangeSlider.isDirectionRTL() {
            rangeSlider.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        }
        
        rangeSlider.handleImage = UIImage(named: "ic_control_knob")
        rangeSlider.handleDiameter = 32
        rangeSlider.selectedHandleDiameterMultiplier = 1.0
    }
}
