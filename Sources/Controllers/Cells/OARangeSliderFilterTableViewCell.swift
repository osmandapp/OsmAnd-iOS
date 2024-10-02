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
    
    var unit: String = "" {
        didSet {
            updateLabels()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSliderView()
        setupSliderCallbacks()
        setupTextFields()
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
        rangeSlider.selectedHandleDiameterMultiplier = 1.2
    }
    
    private func setupTextFields() {
        minTextField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        maxTextField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        minTextField.delegate = self
        maxTextField.delegate = self
    }
    
    private func setupSliderCallbacks() {
        rangeSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    private func updateLabels() {
        let formattedMin = String(format: "%d", Int(rangeSlider.selectedMinimum))
        let formattedMax = String(format: "%d", Int(rangeSlider.selectedMaximum))
        minValueLabel.text = formattedMin + (unit.isEmpty ? "" : " \(unit)")
        maxValueLabel.text = formattedMax + (unit.isEmpty ? "" : " \(unit)")
    }
    
    @objc private func sliderValueChanged(_ slider: OARangeSlider) {
        updateLabels()
    }
    
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        if textField == minTextField, let value = Int(textField.text ?? "") {
            rangeSlider.selectedMinimum = Float(value)
            updateLabels()
        } else if textField == maxTextField, let value = Int(textField.text ?? "") {
            if value > Int(rangeSlider.maxValue) {
                rangeSlider.maxValue = Float(value)
            }
            rangeSlider.selectedMaximum = Float(value)
            updateLabels()
        }
    }
}

extension OARangeSliderFilterTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
