//
//  OpenWunderLINQDatagridCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OpenWunderLINQDatagridCommand: KeyEventCommand {
    static let id = "open_wunderlinq_datagrid"
    
    private let appPath = "wunderlinq://datagrid"
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let url = URL(string: appPath), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    override func toHumanString() -> String {
        localizedString("key_event_action_open_wunderlinq_datagrid")
    }
}
