//
//  CancelableScrollView.swift
//  OsmAnd Maps
//
//  Created by Vitaliy on 21.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// A UIScrollView subclass that disables touch delays
/// and prioritizes scroll gestures over embedded controls.
final class CancelableScrollView: UIScrollView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        delaysContentTouches = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delaysContentTouches = false
    }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIControl {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
}
