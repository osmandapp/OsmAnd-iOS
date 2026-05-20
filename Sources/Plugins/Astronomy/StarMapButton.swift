//
//  StarMapButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

class StarMapButton: UIButton {
    var active = false {
        didSet { updateTheme() }
    }
    var nightMode = false {
        didSet { updateTheme() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView?.contentMode = .scaleAspectFit
        updateTheme()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        imageView?.contentMode = .scaleAspectFit
        updateTheme()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2.0
    }

    func updateTheme() {
        tintColor = active ? .white : .systemBlue
        backgroundColor = nightMode ? UIColor(white: 0.08, alpha: 0.86) : UIColor(white: 1.0, alpha: 0.86)
        layer.cornerRadius = min(bounds.width, bounds.height) / 2.0
        layer.borderWidth = active ? 0 : 1
        layer.borderColor = UIColor(white: nightMode ? 0.35 : 0.75, alpha: 1).cgColor
    }

    func setColorFilter(_ color: UIColor) {
        tintColor = color
    }

    func setIcon(systemName: String, accessibilityLabel: String? = nil) {
        setImage(UIImage(systemName: systemName), for: .normal)
        self.accessibilityLabel = accessibilityLabel
    }
}
