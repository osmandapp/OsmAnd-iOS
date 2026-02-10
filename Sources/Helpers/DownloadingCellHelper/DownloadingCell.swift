//
//  DownloadingCell.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 01/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class DownloadingCell: OARightIconTableViewCell {
    @IBOutlet weak var rightButton: UIButton!
    
    func rightButtonVisibility(show: Bool) {
        rightButton.isHidden = !show
        updateMargins()
    }
    
    func configurePurchasePlanButton() {
        let isRTL = isDirectionRTL()
        let arrow = isRTL ? "arrow.left" : "arrow.right"
        var config = UIButton.Configuration.plain()
        config.title = localizedString("shared_string_get")
        config.image = UIImage(systemName: arrow)
        config.imagePlacement = isRTL ? .leading : .trailing
        config.imagePadding = 6
        config.baseForegroundColor = .textColorActive
        config.background.backgroundColor = .buttonBgColorTertiary
        rightButton.configuration = config
        rightButton.layer.cornerRadius = 6
        rightButton.layer.masksToBounds = true
        rightButton.semanticContentAttribute = .forceLeftToRight
        rightButton.setContentHuggingPriority(.required, for: .horizontal)
        rightButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        // Visual-only button: tap handling is intentionally routed through cell selection.
        rightButton.isUserInteractionEnabled = false
    }
}
