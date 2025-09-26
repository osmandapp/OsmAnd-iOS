//
//  OpenWunderLINQDatagridAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class OpenWunderLINQDatagridAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.openWunderlinqDatagridAction.rawValue, stringId: "open.wunderlinq.datagrid", cl: OpenWunderLINQDatagridAction.self)
        .name(localizedString("wunderlinq_datagrid"))
        .nameAction(localizedString("shared_string_open"))
        .iconName("ic_custom_data_grid")
        .nonEditable()
        .category(QuickActionTypeCategory.interface.rawValue)
    
    private let appPath = "wunderlinq://datagrid"
    private let appStorePath = "https://apps.apple.com/ua/app/wunderlinq/id1410462734"
    
    override init() {
        super.init(actionType: Self.type)
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func execute() {
        if let url = [appPath, appStorePath]
            .compactMap({ URL(string: $0) })
            .first(where: { UIApplication.shared.canOpenURL($0) }) {
            UIApplication.shared.open(url)
        } else {
            debugPrint(localizedString("no_activity_for_intent"))
        }
    }
}
