//
//  StarMapPlainIconButton.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 09.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapPlainButton: UIButton {
    var onHighlightChange: ((Bool) -> Void)?
    
    private var active = false
    private var nightMode = false
    
    var customColorTintActive: UIColor?
    
    override var isHighlighted: Bool {
        didSet {
            onHighlightChange?(isHighlighted)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func updateTheme(nightmod: Bool, active: Bool) {
        self.nightMode = nightmod
        self.active = active
        applyColors()
    }
    
    func setIcon(_ iconName: String, accessibilityLabel: String) {
        setImage(AstroIcon.template(iconName), for: .normal)
        self.accessibilityLabel = accessibilityLabel
        applyColors()
    }
    
    private func setup() {
        backgroundColor = .clear
        imageView?.contentMode = .scaleAspectFit

        applyColors()
    }
    
    private func applyColors() {
        let color: UIColor
        if isHighlighted {
            color = customColorTintActive ?? StarMapControlTheme.foreground(active: false, nightMode: nightMode).withAlphaComponent(0.4)
        } else if active, let customColorTintActive {
            color = customColorTintActive
        } else {
            color = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        }
        print(color, active, isHighlighted)
        
        tintColor = color
        setTitleColor(color, for: .normal)
    }
}
