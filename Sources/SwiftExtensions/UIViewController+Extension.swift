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
