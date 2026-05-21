//
//  CancelableScrollView.swift
//  OsmAnd Maps
//
//  Created by Vitaliy on 21.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// Custom UIScrollView subclass used to fine-tune touch handling behavior for interactive controls inside scrollable menus.
/// It disables touch delays and adjusts content touch cancellation rules to ensure that scrolling gestures take priority
/// over embedded UI elements such as buttons. This provides a more responsive and predictable interaction experience,
/// especially in dense UI layouts like side panels and CarPlay-style interfaces where both scrolling and tapping coexist.
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
