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
        stackView.spacing = 10
        
        // Add the widget views to the stack view
        for widgetView in widgetViews {
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
}
