//
//  AstronomyPlugin.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc(AstronomyPlugin)
final class AstronomyPlugin: OAPlugin {
    static let pluginId = "osmand.astronomy"
    let dataProvider: AstroDataDbProvider

    override init() {
        dataProvider = AstroDataDbProvider()
        super.init()
    }

    override func getId() -> String? {
        Self.pluginId
    }

    override func isEnabled() -> Bool {
        true
    }

    override func getName() -> String {
        localizedString("astronomy_plugin_name")
    }

    override func getDescription() -> String {
        localizedString("astronomy_plugin_description")
    }

    override func getLogoResourceId() -> String? {
        "ic_action_telescope"
    }

    override func getQuickActionTypes() -> [QuickActionType] {
        [OpenAstronomyAction.getType()]
    }

    func showStarMap() {
        let controller = StarMapViewController(plugin: self)
        controller.modalPresentationStyle = .fullScreen
        OARootViewController.instance().present(controller, animated: true)
    }

    func clearCachedData() {
        dataProvider.clearCache()
    }
}
