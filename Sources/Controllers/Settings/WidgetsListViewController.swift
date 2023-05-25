//
//  OAWidgetsListViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 24.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAWidgetsListViewController)
@objcMembers
class WidgetsListViewController: OABaseButtonsViewController {
    
    let panels = [WidgetsPanel.leftPanel, WidgetsPanel.rightPanel, WidgetsPanel.topPanel, WidgetsPanel.bottomPanel]
    
    var widgetPanel: WidgetsPanel! {
        didSet {
            applyLocalization()
        }
    }
    
    init(widgetPanel: WidgetsPanel!) {
        self.widgetPanel = widgetPanel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        widgetPanel = .leftPanel
        
        let segmentedControl = UISegmentedControl(items: [
            UIImage(named: "ic_custom20_screen_side_left")!,
            UIImage(named: "ic_custom20_screen_side_right")!,
            UIImage(named: "ic_custom20_screen_side_top")!,
            UIImage(named: "ic_custom20_screen_side_bottom")!])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Adjust the top constraint of other view elements below the segmented control
        // For example, if you have a table view
        tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8).isActive = true
        
    }
    
    func segmentedControlValueChanged(_ control: UISegmentedControl) {
        widgetPanel = panels[control.selectedSegmentIndex]
        navigationItem.title = getTitle()
    }

}

// Appearance
extension WidgetsListViewController {
    
    override func getTitle() -> String! {
        widgetPanel.title
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }
    
    override func getTopButtonTitle() -> String {
        return tableView.isEditing ? NSLocalizedString("shared_string_export", comment: "") : ""
    }

    override func getBottomButtonTitle() -> String {
        return tableView.isEditing ? NSLocalizedString("shared_string_delete", comment: "") : ""
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        return sectionsCount() == 0 || tableView.indexPathsForSelectedRows?.count == 0 ? .inactive : .graySimple
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        return sectionsCount() == 0 || tableView.indexPathsForSelectedRows?.count == 0 ? .inactive : .grayAttn
    }

    
}
