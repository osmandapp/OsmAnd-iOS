//
//  UIView+SceneLayout.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.10.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.

import UIKit

// Use a view from the presenting interface so geometry comes from its window scene.
extension UIView {
    @objc var sceneLayoutWidth: CGFloat {
        bounds.width
    }

    @objc var sceneLayoutHeight: CGFloat {
        bounds.height
    }

    @objc var sceneLeftInset: CGFloat {
        window?.safeAreaInsets.left ?? 0
    }

    @objc var sceneBottomInset: CGFloat {
        window?.safeAreaInsets.bottom ?? 0
    }

    @objc var sceneStatusBarHeight: CGFloat {
        window?.windowScene?.statusBarManager?.statusBarFrame.height ?? OAUtilities.getStatusBarHeight()
    }

    @objc var isWindowedInScene: Bool {
        guard let window, let scene = window.windowScene else {
            return OAUtilities.isWindowed()
        }
        let windowSize = window.bounds.size
        let screenSize = scene.screen.bounds.size
        return !OAUtilities.isiOSAppOnMac() && OAUtilities.isIPad() &&
            (windowSize.width != screenSize.width || windowSize.height != screenSize.height)
    }

    @objc var isLandscapeInScene: Bool {
        guard let orientation = window?.windowScene?.interfaceOrientation else {
            return OAUtilities.isLandscape()
        }
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }
}
