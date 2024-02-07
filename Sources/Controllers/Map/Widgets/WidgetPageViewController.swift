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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the stack view
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        
        if isMultipleWidgetsInRow {
            stackView.distribution = .equalSpacing
            for (index, items) in simpleWidgetViews.enumerated() {
                if items.count > 1 {
                    let multipleWidgetsInRowStackView = createMultipleWidgetsInRowStackView()
                    items.forEach {
                        $0.isFullRow = false
                        configureSimple(widget: $0)
                        multipleWidgetsInRowStackView.addArrangedSubview($0)
                    }
                    stackView.addArrangedSubview(multipleWidgetsInRowStackView)
                } else {
                    if let widget = items.first {
                        widget.isFullRow = true
                        configureSimple(widget: widget)
                        stackView.addArrangedSubview(widget)
                    }
                }
                if index != simpleWidgetViews.count - 1 {
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
            updateSimpleWidget()
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
}

extension WidgetPageViewController {
    private func createMultipleWidgetsInRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func configureSimple(widget: OABaseWidgetView) {
        widget.translatesAutoresizingMaskIntoConstraints = false
        if !WidgetType.isComplexWidget(widget.widgetType?.id ?? "") {
            widget.isSimpleLayout = true
            widget.updateSimpleLayout()
            widget.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        } else {
            widget.isSimpleLayout = false
            // NOTE: not isComplex widget has static height (waiting redesign)
            widget.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        }
        widget.showBottomSeparator(false)
        widget.showRightSeparator(false)
    }
    
    private func updateSimpleWidget() {
        simpleWidgetViews.enumerated().forEach { index, items in
            let visibleWidgets = items.filter { !$0.isHidden }
            if visibleWidgets.count == 1, let firstWidget = visibleWidgets.first {
                // NOTE: use adjustSize for Complex widget
                if WidgetType.isComplexWidget(firstWidget.widgetType?.id ?? "") {
                    firstWidget.adjustSize()
                    firstWidget.heightConstraint?.constant = firstWidget.frame.height
                }
                firstWidget.isFullRow = true
                if let widget = firstWidget as? OATextInfoWidget {
                    widget.configureSimpleLayout()
                }
            } else {
                visibleWidgets.forEach {
                    $0.isFullRow = false
                    if let widget = $0 as? OATextInfoWidget {
                       widget.configureSimpleLayout()
                    }
                }
            }
            // show horizontal separator for visible items in row
            if index != simpleWidgetViews.count - 1, stackView.subviews.count - 1 > index {
                let horizontalSeparator = stackView.subviews[index + 1]
                horizontalSeparator.isHidden = visibleWidgets.isEmpty
                if !horizontalSeparator.isHidden {
                    // update color for horizontal separator
                    let traitCollection = UITraitCollection(userInterfaceStyle: OAAppSettings.sharedManager().nightMode ? .dark : .light)
                    horizontalSeparator.backgroundColor = .widgetSeparator.resolvedColor(with: traitCollection)
                }
            }
            // show right separator
            items.enumerated().forEach { idx, widget in
                widget.showRightSeparator(idx != items.count - 1)
            }
        }
    }
}
