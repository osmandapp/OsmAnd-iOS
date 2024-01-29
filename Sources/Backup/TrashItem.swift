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
    let deletedFile: OARemoteFile?
    var synced: Bool = false

    init(oldFile: OARemoteFile, deletedFile: OARemoteFile?) {
        self.oldFile = oldFile
        self.deletedFile = deletedFile
    }

    func getTime() -> Int {
        deletedFile?.updatetimems ?? oldFile.updatetimems
    }

    func getName() -> String {
        if let item = getSettingsItem() {
            return BackupUiUtils.getItemName(item)
        } else {
            return oldFile.name
        }
    }

    func getDescription() -> String {
        let deleted = localizedString("shared_string_deleted")
        let formattedTime = BackupUiUtils.formatPassedTime(time: getTime(), longPattern: "MMM d, HH:mm", shortPattern: "HH:mm", def: "")
        return String(format: localizedString("ltr_or_rtl_combine_via_colon"), deleted, formattedTime)
    }

    func getIconName() -> UIImage? {
        if let item: OASettingsItem = getSettingsItem() {
            return BackupUiUtils.getIcon(item)
        }
        return nil
    }

    func getSettingsItem() -> OASettingsItem? {
        deletedFile?.item ?? oldFile.item
    }

    func isLocalDeletion() -> Bool {
        deletedFile == nil
    }

    func getRemoteFiles() -> [OARemoteFile] {
        var files = [oldFile]
        if let deletedFile {
            files.append(deletedFile)
        }
        return files
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
