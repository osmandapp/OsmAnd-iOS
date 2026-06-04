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
    let dataProvider: AstroDataDbProvider

    override init() {
        dataProvider = AstroDataDbProvider()
        super.init()
    }

    override func getId() -> String? {
        kInAppId_Addon_Astronomy
    }

    override func isEnabled() -> Bool {
        super.isEnabled() && (OAIAPHelper.isOsmAndProAvailable() || OAIAPHelper.isMapsPlusAvailable())
    }

    override func getName() -> String {
        String(format: localizedString("ltr_or_rtl_combine_with_brackets"), localizedString("astronomy_plugin_name"), localizedString("shared_string_beta"))
    }

    override func getDescription() -> String {
        localizedString("purchases_feature_desc_astronomy")
    }

    override func getLogoResourceId() -> String? {
        "ic_action_telescope"
    }

    override func getQuickActionTypes() -> [QuickActionType] {
        [OpenAstronomyAction.getType()]
    }

    @objc func showStarMap() {
        let controller = StarMapViewController(plugin: self)
        controller.modalPresentationStyle = .fullScreen
        OARootViewController.instance().present(controller, animated: true)
    }

    @objc func clearCachedData() {
        dataProvider.clearCache()
    }
}
