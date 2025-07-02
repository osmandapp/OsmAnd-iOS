//
//  LocaleHelper.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
class LocaleHelper: NSObject {
    
    static func getPreferredPlacesLanguage() -> String {
        let locale = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        if let locale, !locale.isEmpty {
            return locale
        } else {
            return OAUtilities.currentLang()
        }
    }
}
