//
//  StarMapResetButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapResetButton: StarMapButton {
    override func updateTheme() {
        super.updateTheme()
        setImage(.icCustomRefresh, for: .normal)
        accessibilityLabel = localizedString("shared_string_reset")
    }
}
