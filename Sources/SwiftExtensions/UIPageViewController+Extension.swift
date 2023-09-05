//
//  UIPageViewController+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 29.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension UIPageViewController {
    var scrollView: UIScrollView? {
        view.subviews
            .lazy
            .compactMap { $0 as? UIScrollView }
            .first
    }
}
