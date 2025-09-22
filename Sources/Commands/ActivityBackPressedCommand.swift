//
//  ActivityBackPressedCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class ActivityBackPressedCommand: KeyEventCommand {
    static let id = "activity_back_pressed"
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if OABottomSheetViewStack.sharedInstance().bottomSheetViews.count > 0,
           let bottomSheetViewController = OABottomSheetViewStack.sharedInstance().bottomSheetViews.lastObject as? OABottomSheetViewController {
            bottomSheetViewController.goBack()
        } else {
            OARootViewController.instance().mapPanel.navigationController?.goBack()
        }
    }
    
    override func toHumanString() -> String {
        localizedString("key_event_action_activity_back_pressed")
    }
}
