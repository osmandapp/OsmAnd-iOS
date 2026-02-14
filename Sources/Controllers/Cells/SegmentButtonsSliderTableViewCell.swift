//
//  SegmentButtonsSliderTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 24.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

protocol SegmentButtonsSliderTableViewCellDelegate: AnyObject {
    func onPlusTapped(_ selectedMark: Int, sender: UISlider)
    func onMinusTapped(_ selectedMark: Int, sender: UISlider)
    func onSliderValueChanged(_ selectedMark: Int, sender: UISlider)
}

final class SegmentButtonsSliderTableViewCell: UITableViewCell {
    @IBOutlet weak var sliderView: OASegmentedSlider!
    @IBOutlet weak var topLeftLabel: UILabel!
    @IBOutlet weak var topRightLabel: UILabel!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var minusButton: UIButton!
    
    weak var delegate: SegmentButtonsSliderTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        plusButton.setImage(UIImage.templateImageNamed("ic_custom_map_zoom_in"), for: .normal)
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        plusButton.tintColor = .iconColorActive
        minusButton.setImage(UIImage.templateImageNamed("ic_custom_map_zoom_out"), for: .normal)
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        minusButton.tintColor = .iconColorActive
        sliderView.delegate = self
    }
    
    func setupButtonsEnabling() {
        let isPlusButtonEnabled = sliderView.selectingMark < (sliderView.getMarksCount() - 1)
        let isMinusButtonEnabled = sliderView.selectingMark > 0
        plusButton.tintColor = isPlusButtonEnabled ? .iconColorActive : .iconColorDisabled
        plusButton.isEnabled = isPlusButtonEnabled
        minusButton.tintColor = isMinusButtonEnabled ? .iconColorActive : .iconColorDisabled
        minusButton.isEnabled = isMinusButtonEnabled
    }
    
    @objc private func plusTapped(_ sender: Any) {
        guard sliderView.selectedMark < (sliderView.getMarksCount() - 1) else { return }
        sliderView.selectedMark = sliderView.selectedMark + 1
        delegate?.onPlusTapped(sliderView.selectedMark, sender: sliderView)
    }
    
    @objc private func minusTapped(_ sender: Any) {
        guard sliderView.selectedMark > 0 else { return }
        sliderView.selectedMark = sliderView.selectedMark - 1
        delegate?.onMinusTapped(sliderView.selectedMark, sender: sliderView)
    }
}

// MARK: - OASegmentedSliderDelegate
extension SegmentButtonsSliderTableViewCell: OASegmentedSliderDelegate {
    func onSliderValueChanged() {
        delegate?.onSliderValueChanged(sliderView.selectingMark, sender: sliderView)
    }
    
    func onSliderFinishEditing() {
        setupButtonsEnabling()
    }
}
