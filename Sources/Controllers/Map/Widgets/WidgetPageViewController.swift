//
//  WidgetPageViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

//extension UIStackView {
//    func addVerticalSeparators(color : UIColor, multiplier: CGFloat = 0.5) {
//        var i = self.arrangedSubviews.count - 1
//        while i > 0 {
//            let separator = createSeparator(color: color)
//            insertArrangedSubview(separator, at: i)
//            separator.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: multiplier).isActive = true
//            i -= 1
//        }
//    }
//
//    private func createSeparator(color: UIColor) -> UIView {
//        let separator = UIView()
//        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
//        separator.backgroundColor = color
//        return separator
//    }
//}

extension UIStackView {
    
    func addSeparators(at positions: [Int], color: UIColor = UIColor.widgetSeparator) {
        for position in positions {
            let separator = UIView()
            separator.backgroundColor = color
            
            insertArrangedSubview(separator, at: position)
            switch self.axis {
            case .horizontal:
                separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
                separator.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            case .vertical:
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                separator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
            @unknown default:
                fatalError("Unknown UIStackView axis value.")
            }
        }
    }
}

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
        // .
        stackView.distribution = .fillProportionally//.fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
//    private lazy var verticalDivider: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.widgetSeparator
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.widthAnchor.constraint(equalToConstant: 0.5).isActive = true
//        return view
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the stack view
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        
        if isMultipleWidgetsInRow {
            stackView.distribution = .equalSpacing
         //   stackView.translatesAutoresizingMaskIntoConstraints = false
//            stackView.setContentHuggingPriority(.required, for: .vertical)
//            stackView.setContentCompressionResistancePriority(.required, for: .vertical)
            for (index, items) in simpleWidgetViews.enumerated() {
                if items.count > 1 {
                    let multipleWidgetsInRowStackView = createMultipleWidgetsInRowStackView()
                    for (idx, widget) in items.enumerated() {
                        configureSimple(widget: widget)
                        widget.translatesAutoresizingMaskIntoConstraints = false
                        
                        multipleWidgetsInRowStackView.addArrangedSubview(widget)
                        if idx != items.count {
                            multipleWidgetsInRowStackView.addSeparators(at: [multipleWidgetsInRowStackView.subviews.count - 1])
                        }
                    }
                    stackView.addArrangedSubview(multipleWidgetsInRowStackView)
                } else {
                    if let widget = items.first {
                        configureSimple(widget: widget)
                        widget.translatesAutoresizingMaskIntoConstraints = false
                       // widget.layoutIfNeeded()
                        stackView.addArrangedSubview(widget)
                    }
                }
                if index != simpleWidgetViews.count {
                    stackView.addSeparators(at: [stackView.subviews.count - 1])
                }
            }
        }
        
        // Add the widget views to the stack view
  //      var index = 0
//        for widgetView in widgetViews {
//            widgetView.isSimpleLayout = isMultipleWidgetsInRow
//            if isMultipleWidgetsInRow {
//                widgetView.updateSimpleLayout()
////                if index > 0 {
////                    multipleWidgetsInRowStackView.addArrangedSubview(verticalDivider)
////                }
//                multipleWidgetsInRowStackView.addArrangedSubview(widgetView)
//            } else {
//                widgetView.adjustSize()
//                let constraint = widgetView.heightAnchor.constraint(greaterThanOrEqualToConstant: widgetView.frame.size.height)
//                constraint.priority = .defaultHigh
//                constraint.isActive = true
//                stackView.addArrangedSubview(widgetView)
//            }
//         //   index += 1
//        }
//        if isMultipleWidgetsInRow {
//            stackView.addArrangedSubview(multipleWidgetsInRowStackView)
//        }
        
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
//            for items in simpleWidgetViews {
//                if let widget = items.first {
//                    let hh = widget.getHeightSimpleLayout()
//                    height += hh
//                }
//            }
            
           // let stackViewHeightq = stackView.intrinsicContentSize.height
            let fittingSize = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
           // height = fittingSize.height
//            let targetSize = CGSize(width: view.frame.width, height: UIView.layoutFittingCompressedSize.height)
//            let stackViewHeight = stackView.systemLayoutSizeFitting(targetSize).height
            height = fittingSize.height
           // stackView.layoutIfNeeded()
//            let tt = stackView.bounds
//            for items in simpleWidgetViews {
////                let fittingSize = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
////                 height = fittingSize.height + 30
//             //   let tt = items.first?.adjustSize()
//             //   height += items.first!.frame.height
////                if items.count > 1 {
////                    height += items.first!.frame.height
////                } else {
////                    height += items.first!.frame.height
////                }
//               // item.first!.showSeparator(true)
//               // var stackViewS = stackView.subviews
//               // height += 70
//            }
        } else {
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
        }
        return (width, height)
    }
    
    private func configureSimple(widget: OABaseWidgetView) {
        widget.isSimpleLayout = true
        widget.showSeparator(false)
        widget.updateSimpleLayout()
        widget.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
