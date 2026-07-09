//
//  StarMapPlainIconButton.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 09.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapPlainIconButton: UIButton {
    var active = false {
        didSet { applyColors() }
    }
    var nightMode = false {
        didSet { applyColors() }
    }
    
    override var isHighlighted: Bool {
        didSet { applyColors() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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
        if isHighlighted || active {
            color = StarMapControlTheme.activeForeground(nightMode: nightMode)
        } else {
            color = StarMapControlTheme.foreground(active: false, nightMode: nightMode)
        }
        tintColor = color
    }
}
