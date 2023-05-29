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
class WidgetsListViewController: OABaseSegmentedControlViewController {
    
    let panels = WidgetsPanel.values
    
    var widgetPanel: WidgetsPanel! {
        didSet {
            navigationItem.title = getTitle()
        }
    }
    
    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
    
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
    }
    
    override func createSegmentControl() -> UISegmentedControl? {
        let segmentedControl = UISegmentedControl(items: [
            UIImage(named: "ic_custom20_screen_side_left")!,
            UIImage(named: "ic_custom20_screen_side_right")!,
            UIImage(named: "ic_custom20_screen_side_top")!,
            UIImage(named: "ic_custom20_screen_side_bottom")!])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        return segmentedControl
    }
    
    func segmentedControlValueChanged(_ control: UISegmentedControl) {
        widgetPanel = panels[control.selectedSegmentIndex]
    }
    
    override func generateData() {
        
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
        return localizedString("add_widget")
    }

    override func getBottomButtonTitle() -> String {
        return localizedString("shared_string_edit")
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }
}
