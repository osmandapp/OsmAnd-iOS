//
//  StarMapTimeControlButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapTimeControlButton: StarMapButton {
    override func updateTheme() {
        backgroundColor = .clear
        layer.borderWidth = 0
        layer.cornerRadius = 0
        tintColor = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        setTitleColor(tintColor, for: .normal)
    }
}
