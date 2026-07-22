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
    var customColorTintActive: UIColor?
    
    override var isHighlighted: Bool {
        didSet {
            onHighlightChange?(isHighlighted)
        }
    }
    
    private var active = false
    private var nightMode = false
    
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
    
    func setIcon(_ icon: UIImage?, accessibilityLabel: String) {
        setImage(icon, for: .normal)
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
        
        tintColor = color
        setTitleColor(color, for: .normal)
    }
}
