//
//  AstroBottomSheetBehavior.swift
//  OsmAnd Maps
//
//  Ported from Android AstroBottomSheetBehavior.kt.
//  UIKit owns the actual sheet sizing on iOS; this object keeps the Android
//  behavior state names available to the migrated context menu.
//

import UIKit

final class AstroBottomSheetBehavior<ViewType: UIView> {
    enum State {
        case hidden
        case collapsed
        case expanded
    }

    private weak var view: ViewType?
    private(set) var state: State = .collapsed
    var isHideable = true
    var skipCollapsed = false
    var isFitToContents = true
    var expandedOffset: CGFloat = 0
    var isDraggable = true
    var peekHeight: CGFloat = 0

    init(view: ViewType) {
        self.view = view
    }

    func setLockedNestedScrollTargetId(_ id: String) {
    }

    func setState(_ state: State) {
        self.state = state
        switch state {
        case .hidden:
            view?.isHidden = true
        case .collapsed, .expanded:
            view?.isHidden = false
        }
    }
}

