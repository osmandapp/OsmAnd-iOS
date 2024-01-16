//
//  WidgetPageViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAWidgetPageViewController)
@objcMembers
final class WidgetPageViewController: UIViewController {
    
    var widgetViews: [OABaseWidgetView] = []
    // At the moment, it's for the top panel and bottom panel
    var isMultipleWidgetsInRow = false
    var simpleWidgetViews: [[OABaseWidgetView]] = []
    var stackView: UIStackView!
    
    private func createMultipleWidgetsInRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
           // .fillProportionally/
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the stack view
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        
        if isMultipleWidgetsInRow {
            stackView.distribution = .equalSpacing
            /*
             stackView.translatesAutoresizingMaskIntoConstraints = false
             stackView.setContentHuggingPriority(.required, for: .vertical)
             stackView.setContentCompressionResistancePriority(.required, for: .vertical)
             */
            for (index, items) in simpleWidgetViews.enumerated() {
                if items.count > 1 {
                    let multipleWidgetsInRowStackView = createMultipleWidgetsInRowStackView()
                    items.forEach {
                   // for (idx, widget) in items.enumerated() {
                       // widget.translatesAutoresizingMaskIntoConstraints = false
                        $0.isFullRow = false
                        configureSimple(widget: $0)
                        multipleWidgetsInRowStackView.addArrangedSubview($0)
//                        if idx != items.count - 1, !widget.isHidden {
//                        //    widget.showRightSeparator(true)
////                            multipleWidgetsInRowStackView.addSeparators(at: [multipleWidgetsInRowStackView.subviews.count])
//                        }
                    }
                    stackView.addArrangedSubview(multipleWidgetsInRowStackView)
                } else {
                    if let widget = items.first {
                      //  widget.translatesAutoresizingMaskIntoConstraints = false
                        widget.isFullRow = true
                        configureSimple(widget: widget)
                        stackView.addArrangedSubview(widget)
                    }
                }
                if index != 0, index != simpleWidgetViews.count - 1 {
                    stackView.addSeparators(at: [stackView.subviews.count])
                }
            }
        } else {
            for widgetView in widgetViews {
                widgetView.isSimpleLayout = false
                widgetView.adjustSize()
                let constraint = widgetView.heightAnchor.constraint(greaterThanOrEqualToConstant: widgetView.frame.size.height)
                constraint.priority = .defaultHigh
                constraint.isActive = true
                stackView.addArrangedSubview(widgetView)
            }
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
        if isMultipleWidgetsInRow {
            simpleWidgetViews.forEach { items in
                // text Alignment for visibleWidgets
                let visibleWidgets = items.filter { !$0.isHidden }
                if visibleWidgets.count == 1, let firstWidget = visibleWidgets.first {
                    firstWidget.valueLabel?.textAlignment = .center
                } else {
                    visibleWidgets.forEach { $0.valueLabel?.textAlignment = .natural }
                }
                // show Right Separator
                items.enumerated().forEach { idx, widget in
                    widget.showRightSeparator(idx != items.count - 1)
                }
            }
            
            let fittingSize = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            height = fittingSize.height
        } else {
            let lastVisibleWidget = widgetViews.last(where: { !$0.isHidden })
            for widget in widgetViews {
                widget.showBottomSeparator(widget != lastVisibleWidget)
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
        }
        return (width, height)
    }
    
    private func configureSimple(widget: OABaseWidgetView) {
        widget.translatesAutoresizingMaskIntoConstraints = false
        widget.isSimpleLayout = true
        widget.updateSimpleLayout()
        widget.showBottomSeparator(false)
        widget.showRightSeparator(false)
        widget.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
