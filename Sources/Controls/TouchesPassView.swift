//
//  TouchesPassView.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 25.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

class TouchesPassView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view === self {
            return nil
        }
        return view
    }
}
