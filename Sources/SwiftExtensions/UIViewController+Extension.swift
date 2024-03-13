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
}
