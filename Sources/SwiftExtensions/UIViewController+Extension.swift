//
//  UIViewController+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 31.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@nonobjc extension UIViewController {
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)
        
        if let frame {
            child.view.frame = frame
        }
        
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension UINavigationItem {
    @objc (setRightBarButtonItemsisEnabled:tintColor:)
    func setRightBarButtonItems(isEnabled: Bool, with tintColor: UIColor? = nil) {
        rightBarButtonItems?.forEach {
            if let button = $0.customView as? UIButton {
                $0.isEnabled = isEnabled
                button.isEnabled = isEnabled
                button.tintColor = tintColor
                button.setTitleColor(tintColor, for: .normal)
            }
        }
    }
}

extension UINavigationController {
    @objc func pushViewController(_ viewController: UIViewController,
                                  animated: Bool,
                                  completion: (() -> Void)?) {
      CATransaction.begin()
      CATransaction.setCompletionBlock(completion)
      pushViewController(viewController, animated: animated)
      CATransaction.commit()
    }

    @objc func saveCurrentStateForScrollableHud() -> [UIViewController] {
        var newCurrentHistory = viewControllers
        guard !viewControllers.isEmpty else {
            return newCurrentHistory
        }

        var newHistory = [UIViewController]()
        var rootViewControllerIndex = 0
        for i in 0...newCurrentHistory.count - 1 {
            let vc = newCurrentHistory[i]
            if vc is OARootViewController {
                rootViewControllerIndex = i
            } else {
                newHistory.append(vc)
            }
        }
        newHistory.append(newCurrentHistory[rootViewControllerIndex])
        newCurrentHistory.insert(newCurrentHistory.remove(at: rootViewControllerIndex), at: 0)
        setViewControllers(newHistory, animated: true)

        // Example:
        // Show track context menu above the map.
        // [MyPlacesTabBar, Folder1, Folder2, RootVC, TrackContectMenu]
        return newCurrentHistory
    }

    @objc func restoreForceHidingScrollableHud() {
        guard !viewControllers.isEmpty else { return }

        var newHistory = [UIViewController]()
        for i in 0...viewControllers.count - 1 {
            let vc = viewControllers[i]
            if vc is OARootViewController {
                newHistory.append(vc)
                break
            }
        }
        setViewControllers(newHistory, animated: true)
    }
}
