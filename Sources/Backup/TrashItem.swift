//
//  TrashItem.swift
//  OsmAnd Maps
//
//  Created by Skalii on 29.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATrashItem)
@objcMembers
final class TrashItem: NSObject {

    let oldFile: OARemoteFile
    let deletedFile: OARemoteFile

    init(oldFile: OARemoteFile, deletedFile: OARemoteFile) {
        self.oldFile = oldFile
        self.deletedFile = deletedFile
    }

    var time: Int {
        deletedFile.updatetimems / 1000
    }

    var name: String {
        if let settingsItem {
            return BackupUiUtils.getItemName(settingsItem)
        } else {
            return BackupUiUtils.getItemName(oldFile.item)
        }
    }

    var descr: String {
        let deleted = localizedString("shared_string_deleted")
        let formattedTime = BackupUiUtils.formatPassedTime(time: time, longPattern: "MMM d, HH:mm", shortPattern: "HH:mm", def: "")
        return String(format: localizedString("ltr_or_rtl_combine_via_colon"), deleted, formattedTime)
    }

    var icon: UIImage? {
        if let settingsItem {
            return BackupUiUtils.getIcon(settingsItem)
        } else {
            return BackupUiUtils.getIcon(oldFile.item)
        }
    }

    var settingsItem: OASettingsItem? {
        deletedFile.item
    }

    var remoteFiles: [OARemoteFile] {
        [oldFile, deletedFile]
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(oldFile)
        hasher.combine(deletedFile)
        return hasher.finalize()
    }

    override func isEqual(_ obj: Any?) -> Bool {
        guard let other = obj as? TrashItem else {
            return false
        }
        return oldFile == other.oldFile && deletedFile == other.deletedFile
    }
}
