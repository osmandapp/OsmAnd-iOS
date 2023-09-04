//
//  WidgetPageViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

@objc(OAWidgetPageViewController)
@objcMembers
class WidgetPageViewController: UIViewController {
    
    var widgetViews: [OABaseWidgetView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        
        // Add the widget views to the stack view
        let lastVisibleItem = widgetViews.last(where: { !$0.isHidden })
        for widgetView in widgetViews {
            if let textInfo = widgetView as? OATextInfoWidget {
                textInfo.showSeparator(widgetView != lastVisibleItem)
            }
            widgetView.adjustSize()
            let constraint = widgetView.heightAnchor.constraint(greaterThanOrEqualToConstant: widgetView.frame.size.height)
            constraint.priority = .defaultHigh
            constraint.isActive = true
            stackView.addArrangedSubview(widgetView)
        }
        
        // Add the stack view to the view controller's view and set constraints
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func layoutWidgets() -> (width: CGFloat, height: CGFloat) {
        var width: CGFloat = 0
        var height: CGFloat = 0
        for widget in widgetViews {
            widget.translatesAutoresizingMaskIntoConstraints = false
            widget.adjustSize()
            width = max(width, widget.frame.size.width)
            if !widget.isHidden {
                height += widget.frame.size.height
            }
        }
        return (width, height)
    }
}
