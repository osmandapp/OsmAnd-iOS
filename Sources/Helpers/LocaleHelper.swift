//
//  LocaleHelper.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class LocaleHelper: NSObject {
        
    static func getPreferredNameLocale(_ localeIds: [String]) -> String? {
        var preferredLocaleId = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        if preferredLocaleId.isEmpty {
            preferredLocaleId = "en"
        }
        let availablePreferredLocale = getAvailablePreferredLocale(localeIds)
        
        return localeIds.contains(preferredLocaleId) ? preferredLocaleId : availablePreferredLocale
    }
         
    static func getAvailablePreferredLocale(_ availableLocales: [String]) -> String? {
        // this function is different from android, beause ios lang codes are different from our map data short lang codes.
        
        let prefferedLocales = NSLocale.preferredLanguages
        
        for prefferedLocale in prefferedLocales {
            guard !prefferedLocale.isEmpty else { continue }
            let prefferedLocaleTrimmed = prefferedLocale.components(separatedBy: "-")[0].lowercased() // "En-US" -> "en"
            
            for availableLocale in availableLocales {
                guard !availableLocale.isEmpty else { continue }
                let availableLocaleTrimmed = availableLocale.components(separatedBy: "-")[0].lowercased()
                
                if availableLocaleTrimmed == prefferedLocaleTrimmed {
                    return availableLocale // return original unchanged string
                }
            }
        }
        return nil
    }
    
    static func getPreferredPlacesLanguage() -> String {
        let locale = OAAppSettings.sharedManager().settingPrefMapLanguage.get()
        if !locale.isEmpty {
            return locale
        } else {
            return OAUtilities.currentLang() ?? ""
        }
    }
}
