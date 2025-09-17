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
        guard let url = URL(string: appPath), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
