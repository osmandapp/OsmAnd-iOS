//
//  BackupUiUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 29.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OABackupUiUtils)
@objcMembers
final class BackupUiUtils: NSObject {

    private static let minDurationForDateFormat = 48 * 60 * 60
    private static let minDurationForYesterdayDateFormat = 24 * 60 * 60

    static func getItemName(_ item: OASettingsItem) -> String {
        var name: String
        if let profileItem = item as? OAProfileSettingsItem {
            name = profileItem.appMode.toHumanString()
        } else {
            name = item.getPublicName()
            if let fileItem = item as? OAFileSettingsItem {
                switch fileItem.subtype {
                case .subtypeTTSVoice:
                    name = String(format: localizedString("ltr_or_rtl_combine_via_space"), name, localizedString("tts_title"))
                case .subtypeVoice:
                    name = String(format: localizedString("ltr_or_rtl_combine_via_space"), name, localizedString("shared_string_record"))
                default:
                    break
                }
            }
        }
        return !name.isEmpty ? name : localizedString("res_unknown")
    }

    static func getIcon(_ item: OASettingsItem) -> UIImage? {
        if let profileItem = item as? OAProfileSettingsItem {
            return profileItem.appMode.getIcon()
        }
        let type: OAExportSettingsType? = OAExportSettingsType.find(by: item)
        return type?.icon
    }

    static func getLastBackupTimeDescription(_ def: String) -> String {
        let lastUploadedTime = OAAppSettings.sharedManager().backupLastUploadedTime.get()
        return getFormattedPassedTime(time: lastUploadedTime, def: def, showTime: false)
    }

    static func getFormattedPassedTime(time: Int, def: String, showTime: Bool) -> String {
        guard time > 0 else {
            return def
        }
        let duration = Int((Date().timeIntervalSince1970 - Double(time)) / 1000)
        if duration > minDurationForDateFormat {
            return showTime ? OAOsmAndFormatter.getFormattedDateTime(TimeInterval(time)) : OAOsmAndFormatter.getFormattedDate(TimeInterval(time))
        } else {
            let formattedDuration: String = OAOsmAndFormatter.getFormattedDuration(TimeInterval(duration))
            return formattedDuration.isEmpty ? localizedString("duration_moment_ago") : String(format: localizedString("duration_ago"), formattedDuration)
        }
    }

    static func generateTimeString(summary: String, time: Int) -> String {
        String(format: localizedString("ltr_or_rtl_combine_via_colon"), summary, getTimeString(time))
    }

    static func getTimeString(_ time: Int) -> String {
        formatPassedTime(time: time, longPattern: "d MMM yyyy, HH:mm:ss", shortPattern: "HH:mm:ss", def: localizedString("shared_string_never"))
    }

    static func formatPassedTime(time: Int, longPattern: String, shortPattern: String, def: String) -> String {
        guard time > 0 else {
            return def
        }
        let duration = Int((Date().timeIntervalSince1970 - Double(time)))
        if duration > minDurationForDateFormat {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = longPattern
            dateFormatter.locale = Locale.current
            let date = Date(timeIntervalSince1970: Double(time))
            return dateFormatter.string(from: date)
        } else if duration > minDurationForYesterdayDateFormat {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = shortPattern
            dateFormatter.locale = Locale.current
            let date = Date(timeIntervalSince1970: Double(time))
            return localizedString("yesterday") + ", " + dateFormatter.string(from: date)
        } else {
            let formattedDuration: String = OAOsmAndFormatter.getFormattedDuration(TimeInterval(duration))
            return formattedDuration.isEmpty ? localizedString("duration_moment_ago") : String(format: localizedString("duration_ago"), formattedDuration)
        }
    }
}
