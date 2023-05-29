//
//  OABaseSegmentedControlViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 25.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class OABaseSegmentedControlViewController: OABaseButtonsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = tableView.backgroundColor
        let segmentedControl = createSegmentControl()
        if let segmentedControl {
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(segmentedControl)
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                segmentedControl.heightAnchor.constraint(equalToConstant: 30)
            ])
            topTableViewConstraint.isActive = false
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8).isActive = true
        }
    }

    func createSegmentControl() -> UISegmentedControl? {
        nil
    }

}
