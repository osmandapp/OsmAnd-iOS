//
//  AstronomyPlugin.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc final class AstronomyPlugin: OAPlugin {
    private enum PreferenceId {
        static let settings = "astronomy_settings"
        static let legacySettings = "star_watcher_settings"
        static let recent = "astronomy_recently_viewed"
    }

    let dataProvider = AstroDataDbProvider()
    
    var astroSettings: AstronomyPluginSettings { astronomySettingsStorage }
    var recentSearchChips: [StarMapRecentChip] = []

    private let settingsPref: OACommonString = OAAppSettings.sharedManager()
        .registerStringPreference(PreferenceId.settings, defValue: "")
        .makeProfile()
        .makeShared()

    private let legacySettingsPref: OACommonString = OAAppSettings.sharedManager()
        .registerStringPreference(PreferenceId.legacySettings, defValue: "")
        .makeProfile()
        .makeShared()

    private let recentPref: OACommonString = OAAppSettings.sharedManager()
        .registerStringPreference(PreferenceId.recent, defValue: "")
        .makeGlobal()

    private lazy var astronomySettingsStorage = AstronomyPluginSettings(settingsPref: settingsPref, recentPref: recentPref)

    override init() {
        super.init()
        recentSearchChips = astronomySettingsStorage.recentChips()
    }

    func saveRecentSearchChips() {
        astronomySettingsStorage.setRecentChips(recentSearchChips)
    }

    func migrateLegacyStarWatcherSettingsIfNeeded() {
        for appMode in OAApplicationMode.allPossibleValues() {
            guard legacySettingsPref.isSet(for: appMode), !settingsPref.isSet(for: appMode) else {
                continue
            }
            settingsPref.set(legacySettingsPref.get(appMode), mode: appMode)
        }
        astronomySettingsStorage.reloadFromPreference()
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
        "ic_custom_telescope"
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
