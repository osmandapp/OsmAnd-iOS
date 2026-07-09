//
//  StarMapTimeControlButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapTimeControlButton: UIButton {
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
        titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        setImage(AstroIcon.template("ic_action_time"), for: .normal)
        imageView?.contentMode = .scaleAspectFit
        applyColors()
    }
    private func applyColors() {
        let color = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        tintColor = color
        setTitleColor(color, for: .normal)
    }
}
