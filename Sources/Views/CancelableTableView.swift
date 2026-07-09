//
//  CancelableTableView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// A UITableView subclass that disables touch delays
/// and prioritizes scroll gestures over embedded controls.
final class CancelableTableView: UITableView {

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
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
