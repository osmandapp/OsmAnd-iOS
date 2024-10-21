//
//  FileHashesHelper.swift
//  OsmAnd Maps
//
//  Created by Skalii on 14.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class LocalFileHashHelper: NSObject {

    static let shared = LocalFileHashHelper()
    private static let key = "localFilesHashes"

    private var fileHashes: ConcurrentDictionary<String, String>

    private override init() {
        let defaults = UserDefaults.standard
        if let dict = defaults.dictionary(forKey: Self.key) as? [String: String] {
            fileHashes = ConcurrentDictionary(with: dict)
        } else {
            fileHashes = ConcurrentDictionary<String, String>()
            defaults.set(fileHashes.asDictionary(), forKey: Self.key)
        }
        
        super.init()
    }

    func setHash(_ filePath: String) {
        if let md5 = OAUtilities.fileMD5(filePath), !md5.isEmpty {
            fileHashes.setValue(md5, forKey: filePath)
        } else {
            debugPrint("Error generating md5 for file: \(filePath)")
        }
    }

    func setHash(withFileItem fileItem: OAFileSettingsItem) {
        guard fileItem.subtype == .subtypeColorPalette else { return }

        if let md5 = OAUtilities.fileMD5(fileItem.filePath), !md5.isEmpty {
            fileHashes.setValue(md5, forKey: fileItem.filePath)
        } else {
            debugPrint("Error generating md5 for file: \(fileItem.filePath)")
        }
    }

    func removeHash(_ filePath: String) {
        fileHashes.removeValue(forKey: filePath)
    }

    func saveHashes() {
        UserDefaults.standard.set(fileHashes.asDictionary(), forKey: Self.key)
    }

    func isHashUpdated(_ localFile: OALocalFile) -> Bool {
        if let fileItem = localFile.item as? OAFileSettingsItem, fileItem.subtype == .subtypeColorPalette {
            return OAUtilities.fileMD5(localFile.filePath) != fileHashes.getValue(forKey: localFile.filePath)
        }
        return true
    }
}
