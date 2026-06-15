//
//  PlanRouteAnalyzeViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteAnalyzeViewController: UIViewController, PlanRouteTabContent {
    let planRouteTab: PlanRouteTab = .analyze

    private weak var dataSource: PlanRouteAnalyzeDataSource?

    private let placeholderLabel = UILabel()

    init(dataSource: PlanRouteAnalyzeDataSource?) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlaceholder()
        reloadData()
    }

    func reloadData() {
        guard isViewLoaded else { return }
        placeholderLabel.text = planRouteTab.title
    }

    private func setupPlaceholder() {
        view.backgroundColor = .clear
        placeholderLabel.font = .preferredFont(forTextStyle: .body)
        placeholderLabel.textColor = .textColorSecondary
        placeholderLabel.textAlignment = .center
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
