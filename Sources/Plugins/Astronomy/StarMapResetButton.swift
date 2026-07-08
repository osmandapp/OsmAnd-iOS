//
//  StarMapResetButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapResetButton: UIButton {
    var active = false {
        didSet { applyColors() }
    }
    var nightMode = false {
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
    private func setup() {
        backgroundColor = .clear
        setImage(.icCustomRefresh, for: .normal)
        imageView?.contentMode = .scaleAspectFit
        accessibilityLabel = localizedString("shared_string_reset")
        applyColors()
    }
    private func applyColors() {
        let color = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        tintColor = color
        setTitleColor(color, for: .normal)
    }
}
