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
        registerObservers()
        
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
    
    private func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSimpleWidgetStyleUpdated),
                                               name: .SimpleWidgetStyleUpdated,
                                               object: nil)
    }
    
    private func getWidgetsInRowWithoutCurrent(widget: OABaseWidgetView) -> [OABaseWidgetView]? {
        for widgetViews in simpleWidgetViews {
            for view in widgetViews where view === widget {
                return widgetViews.filter { $0 != view }
            }
        }
        return nil
    }
    
    @objc private func onSimpleWidgetStyleUpdated(notification: Notification) {
        guard isMultipleWidgetsInRow else { return }
        guard let widget = (notification.object as? MapWidgetInfo)?.widget as? OATextInfoWidget else { return }
        // update widgetSizeStyle by currentwidget for all items in row
        if let widgetsInRow = getWidgetsInRowWithoutCurrent(widget: widget) {
            widgetsInRow.compactMap { $0 as? OATextInfoWidget }
                .forEach {
                    $0.sizeStylePref.set(Int32(widget.widgetSizeStyle.rawValue), mode: OAAppSettings.sharedManager().applicationMode.get())
                }
        }
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
        if widget.widgetType?.isComplex == false {
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
        simpleWidgetViews.forEach { items in
            // text Alignment for visibleWidgets
            let visibleWidgets = items.filter { !$0.isHidden }
            if visibleWidgets.count == 1, let firstWidget = visibleWidgets.first {
                if let widget = firstWidget as? OATextInfoWidget {
                    widget.valueLabel?.textAlignment = .center
                }
                // NOTE: use adjustSize for Complex widget
                if firstWidget.widgetType?.isComplex == true {
                    firstWidget.adjustSize()
                    firstWidget.heightConstraint?.constant = firstWidget.frame.height
                }
                firstWidget.isFullRow = true
            } else {
                visibleWidgets.forEach {
                    if let widget = $0 as? OATextInfoWidget {
                        widget.valueLabel?.textAlignment = .natural
                    }
                    $0.isFullRow = false
                }
            }
            // show Right Separator
            items.enumerated().forEach { idx, widget in
                widget.showRightSeparator(idx != items.count - 1)
            }
        }
    }
}
