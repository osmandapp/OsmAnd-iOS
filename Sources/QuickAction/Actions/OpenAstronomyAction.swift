//
//  OpenAstronomyAction.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class OpenAstronomyAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.openAstronomyActionId.rawValue,
                                              stringId: "astronomy.map.open",
                                              cl: OpenAstronomyAction.self)
        .name(localizedString("star_map"))
        .nameAction(localizedString("shared_string_open"))
        .iconName("ic_action_telescope")
        .nonEditable()
        .category(QuickActionTypeCategory.configureMap.rawValue)

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

    override func getText() -> String? {
        localizedString("open_astronomy_action_description")
    }

    override func execute() {
        guard let plugin = OAPluginsHelper.getPlugin(AstronomyPlugin.self) as? AstronomyPlugin else {
            return
        }
        if !OAPluginsHelper.isEnabled(AstronomyPlugin.self) {
            OAPluginsHelper.enable(plugin, enable: true)
        }
        plugin.showStarMap()
    }
}

