//
//  WidgetPageViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

enum WidgetSizeStyle {
    case regular, small, medium, large
    
    var labelFont: UIFont {
        switch self {
#warning("regular")
        case .regular: UIFont.systemFont(ofSize: 20)
        case .small: UIFont.systemFont(ofSize: 22)
        case .medium: UIFont.systemFont(ofSize: 33)
        case .large: UIFont.systemFont(ofSize: 55)
        }
    }
    
    var valueFont: UIFont {
        switch self {
#warning("regular")
        case .regular: UIFont.systemFont(ofSize: 20)
        case .small, .medium, .large: UIFont.systemFont(ofSize: 11)
        }
    }
    
    var unitsFont: UIFont {
        switch self {
#warning("regular")
        case .regular: UIFont.systemFont(ofSize: 20)
        case .small, .medium, .large: UIFont.systemFont(ofSize: 11)
        }
    }
}

@objc(OAWidgetPageViewController)
@objcMembers
final class WidgetPageViewController: UIViewController {
    
    var widgetViews: [OABaseWidgetView] = []
    // At the moment, it's for the top panel and bottom panel
    var isMultipleWidgetsInRow = false
    
    private lazy var multipleWidgetsInRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 1
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
//    private lazy var verticalDivider: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.lightGray
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.widthAnchor.constraint(equalToConstant: 0.5).isActive = true
//        return view
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        
        // Add the widget views to the stack view
  //      var index = 0
        for widgetView in widgetViews {
            if isMultipleWidgetsInRow {
//                if index > 0 {
//                    multipleWidgetsInRowStackView.addArrangedSubview(verticalDivider)
//                }
                multipleWidgetsInRowStackView.addArrangedSubview(widgetView)
            } else {
                widgetView.adjustSize()
                let constraint = widgetView.heightAnchor.constraint(greaterThanOrEqualToConstant: widgetView.frame.size.height)
                constraint.priority = .defaultHigh
                constraint.isActive = true
                stackView.addArrangedSubview(widgetView)
            }
         //   index += 1
        }
        if isMultipleWidgetsInRow {
            stackView.addArrangedSubview(multipleWidgetsInRowStackView)
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
        let lastVisibleWidget = widgetViews.last(where: { !$0.isHidden })
        for widget in widgetViews {
            widget.showSeparator(widget != lastVisibleWidget)
            widget.translatesAutoresizingMaskIntoConstraints = false
            widget.adjustSize()
            width = max(width, widget.frame.size.width)
            if !widget.isHidden {
                height += widget.frame.size.height
            }
            /*
            let constraint = widget.heightAnchor.constraint(greaterThanOrEqualToConstant: widget.frame.size.height)
            constraint.priority = .defaultHigh
            constraint.isActive = true
             */
        }
        return (width, height)
    }
}
