//
//  TopBottomValuesSliderTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 22.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class TopBottomValuesSliderTableViewCell: UITableViewCell {
    @IBOutlet weak var slider: SteppedSlider!
    @IBOutlet weak var topLeftLabel: UILabel!
    @IBOutlet weak var topRightLabel: UILabel!
    @IBOutlet weak var bottomLeftLabel: UILabel!
    @IBOutlet weak var bottomRightLabel: UILabel!
    @IBOutlet weak var topRightButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var sliderValuesView: UIView!
    @IBOutlet private weak var segmentValuesView: UIView!
    @IBOutlet private weak var topLabelsStackView: UIStackView!
    @IBOutlet private var topLabelsTopConstraint: NSLayoutConstraint!
    @IBOutlet private var topLabelsTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private var valuesTopConstraint: NSLayoutConstraint!
    
    private let valueTopInset: CGFloat = 13
    private let buttonTopInset: CGFloat = 7
    private let valueTrailingInset: CGFloat = 20
    private let buttonTrailingInset: CGFloat = 9
    private let valueBottomSpacing: CGFloat = 13
    private let buttonBottomSpacing: CGFloat = 5
    private let valueHorizontalSpacing: CGFloat = 16
    private let buttonHorizontalSpacing: CGFloat = 5
    private let labelLineCount = 1
    private let minimumFontScaleFactor: CGFloat = 0.3
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        updateLabelsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        slider.accessibilityStep = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        topRightLabel.textAlignment = isRightToLeft ? .left : .right
        bottomLeftLabel.textAlignment = isRightToLeft ? .right : .left
        bottomRightLabel.textAlignment = isRightToLeft ? .left : .right
    }

    // scaledSystemFont caps the font at the size calculated when it is created.
    // Recreate fonts on Dynamic Type changes so they can grow beyond that initial cap.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        updateFonts()
        updateLabelsLayout()
    }

    func topRightLabelVisibility(_ show: Bool) {
        topRightButton.isHidden = show
        topRightLabel.isHidden = !show
        updateLabelsLayout()
    }
    
    func topRightButtonVisibility(_ show: Bool) {
        topRightButton.isHidden = !show
        topRightLabel.isHidden = show
        updateLabelsLayout()
    }
    
    func sliderValuesVisibility(_ show: Bool) {
        sliderValuesView.isHidden = !show
        segmentValuesView.isHidden = show
    }
    
    func segmentValuesVisibility(_ show: Bool) {
        sliderValuesView.isHidden = show
        segmentValuesView.isHidden = !show
    }

    private func updateFonts() {
        let font = UIFont.scaledSystemFont(ofSize: 17)
        for label in [topLeftLabel, topRightLabel, bottomLeftLabel, bottomRightLabel] {
            label?.font = font
            label?.adjustsFontForContentSizeCategory = true
        }
        descriptionLabel?.font = UIFont.scaledSystemFont(ofSize: 15)
        descriptionLabel?.adjustsFontForContentSizeCategory = true
    }

    private func updateLabelsLayout() {
        guard let topLabelsStackView else { return }
        let showsValue = !topRightLabel.isHidden
        topLabelsTopConstraint.constant = showsValue ? valueTopInset : buttonTopInset
        topLabelsTrailingConstraint.constant = showsValue ? valueTrailingInset : buttonTrailingInset
        valuesTopConstraint.constant = showsValue ? valueBottomSpacing : buttonBottomSpacing
        topLabelsStackView.spacing = showsValue ? valueHorizontalSpacing : buttonHorizontalSpacing
        topLabelsStackView.alignment = showsValue ? .firstBaseline : .center
        topLabelsStackView.distribution = .fillProportionally
        topRightButton.contentHorizontalAlignment = .trailing
        topRightButton.configuration?.titleLineBreakMode = .byTruncatingTail
        for label in [topLeftLabel, topRightLabel, topRightButton.titleLabel] {
            label?.numberOfLines = labelLineCount
            label?.adjustsFontSizeToFitWidth = true
            label?.minimumScaleFactor = minimumFontScaleFactor
            label?.baselineAdjustment = showsValue ? .alignBaselines : .alignCenters
        }
    }
}
