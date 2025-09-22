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

extension UIViewController {
    func showMediumSheetViewController(viewController: UIViewController, isLargeAvailable: Bool) {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = isLargeAvailable
            ? [.medium(), .large()]
            : [.medium()]
            sheet.prefersGrabberVisible = isLargeAvailable
            sheet.preferredCornerRadius = 20
        }
        
        present(navigationController, animated: true, completion: nil)
    }
}

extension UIViewController {
    @objc func showActivity(_ items: [Any],
                            sourceView: UIView,
                            barButtonItem: UIBarButtonItem?,
                            completionWithItemsHandler: (() -> Void)? = nil) {
        showActivity(items, applicationActivities: nil, excludedActivityTypes: nil, sourceView: sourceView, sourceRect: CGRect(), barButtonItem: barButtonItem, permittedArrowDirections: .any, completionWithItemsHandler: completionWithItemsHandler)
    }
    
    @objc func showActivity(_ items: [Any],
                            applicationActivities: [UIActivity]? = nil,
                            excludedActivityTypes: [UIActivity.ActivityType]? = nil,
                            sourceView: UIView,
                            sourceRect: CGRect = CGRect(),
                            barButtonItem: UIBarButtonItem?,
                            permittedArrowDirections: UIPopoverArrowDirection = .any,
                            completionWithItemsHandler: (() -> Void)? = nil) {
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
        activityViewController.excludedActivityTypes = excludedActivityTypes
        
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            if let barButtonItem {
                popoverPresentationController.barButtonItem = barButtonItem
            } else if sourceRect != CGRectZero {
                popoverPresentationController.sourceRect = sourceRect
                popoverPresentationController.permittedArrowDirections = permittedArrowDirections
            }
        }
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            completionWithItemsHandler?()
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
}

extension UIViewController {
    @objc var isDarkMode: Bool { traitCollection.userInterfaceStyle == .dark }
}

extension UINavigationItem {
    @objc(setRightBarButtonItemsIsEnabled:tintColor:)
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
    /// Saves the current state for the scrollable HUD by performing two distinct reordering actions:
    /// 1. Rearranges the navigation stack (`setViewControllers`) to place `OARootViewController` at the **end**.
    /// 2. Returns a new array of `UIViewController`s where `OARootViewController` is at the **beginning**.
    ///
    /// This assumes there's always one and only one instance of `OARootViewController` in the `viewControllers` stack.
    ///
    /// - Returns: An array of `UIViewController`s with `OARootViewController` as its first element.
    @objc func saveCurrentStateForScrollableHud() -> [UIViewController] {
        guard !viewControllers.isEmpty else {
            return []
        }
        
        guard let rootViewController = viewControllers.first(where: { $0 is OARootViewController }) else {
            NSLog("Warning: OARootViewController not found in the current navigation stack. Returning current stack without modification.")
            return viewControllers
        }
        
        var stackForNavController = viewControllers.filter { $0 !== rootViewController }
        stackForNavController.append(rootViewController)
        
        setViewControllers(stackForNavController, animated: true)
        
        var returnedHistory: [UIViewController] = [rootViewController]
        returnedHistory.append(contentsOf: viewControllers.filter { $0 !== rootViewController })
        
        // Example:
        // Show track context menu above the map.
        // [MyPlacesTabBar, Folder1, Folder2, RootVC, TrackContextMenu]
        return returnedHistory
    }
    
    /// Restores the navigation stack to contain only the first `OARootViewController` instance,
    @objc func restoreForceHidingScrollableHud() {
        guard !viewControllers.isEmpty else {
            return
        }
        guard let rootViewControllerToKeep = viewControllers.first(where: { $0 is OARootViewController }) else {
            NSLog("Warning: No OARootViewController found in the navigation stack to restore to.")
            return
        }
        
        setViewControllers([rootViewControllerToKeep], animated: true)
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
}

extension UINavigationController {
    
    func setDefaultNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .viewBg
        // swiftlint:disable all
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: UIFont.scaledSystemFont(ofSize: 17, weight: .semibold, maximumSize: 22)
        ]
        // swiftlint:enable all
        
        let blurAppearance = UINavigationBarAppearance()
        blurAppearance.shadowColor = nil
        blurAppearance.shadowImage = nil
        
        navigationBar.standardAppearance = blurAppearance
        navigationBar.scrollEdgeAppearance = appearance
        
        navigationBar.tintColor = .iconColorActive
    }
}

extension UIViewController {
    @objc func canPresentAlertController(_ alert: UIAlertController,
                                         completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  UIApplication.shared.applicationState != .background else {
                completion(false)
                return
            }
            if let presented = presentedViewController, presented is UIAlertController {
                completion(false)
                return
            }
            completion(true)
        }
    }
}

extension UIViewController {
    
    func createNavbarButton(title: String?, icon: UIImage?, color: UIColor, action: Selector?, target: AnyObject?, menu: UIMenu?) -> UIBarButtonItem {
        let button = UIButton(frame: .init(x: 0, y: 0, width: 44, height: 30))
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.tintColor = color
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color.withAlphaComponent(0.3), for: .highlighted)
        
        if let title {
            button.setTitle(title, for: .normal)
        }
        
        if let icon {
            button.setImage(icon, for: .normal)
        }
        
        button.removeTarget(nil, action: nil, for: .allEvents)
        if let action {
            button.addTarget(target, action: action, for: .touchUpInside)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if let menu {
            button.showsMenuAsPrimaryAction = true
            button.menu = menu
        }
        
        let rightNavbarButton = UIBarButtonItem(customView: button)
        
        if let title {
            rightNavbarButton.accessibilityLabel = title
        }
        
        return rightNavbarButton
    }
}
