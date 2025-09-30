//
//  OpenWunderLINQDatagridAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class OpenWunderLINQDatagridAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.openWunderlinqDatagridAction.rawValue, stringId: "open.wunderlinq.datagrid", cl: OpenWunderLINQDatagridAction.self)
        .name(localizedString("wunderlinq_datagrid"))
        .nameAction(localizedString("shared_string_open"))
        .iconName("ic_custom_data_grid")
        .nonEditable()
        .category(QuickActionTypeCategory.interface.rawValue)
    
    private let appStorePath = "https://apps.apple.com/app/wunderlinq/id1410462734"
    
    override class func getType() -> QuickActionType {
        type
    }

    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func execute() {
        guard !UIApplication.shared.openWunderLINQ() else { return }
        
        if let url = URL(string: appStorePath), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            debugPrint(localizedString("no_activity_for_intent"))
        }
    }
}
