//
//  BackupUtils.swift
//  OsmAnd Maps
//
//  Created by SKalii on 09.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class BackupUtils: NSObject {

    static let backupTypePrefix = "backup_type_"
    static let versionHistoryPrefix = "save_version_history_"

    static func setLastModifiedTime(_ name: String) {
        setLastModifiedTime(name, lastModifiedTime: Int(NSDate().timeIntervalSince1970))
    }

    static func setLastModifiedTime(_ name: String, lastModifiedTime: Int) {
        OABackupDbHelper.sharedDatabase().setLastModifiedTime(name, lastModifiedTime: Int(lastModifiedTime))
    }

    static func getLastModifiedTime(_ name: String) -> Int {
        OABackupDbHelper.sharedDatabase().getLastModifiedTime(name)
    }

    static func isTokenValid(_ token: String) -> Bool {
        token.range(of: "^[0-9]+$", options: .regularExpression) != nil
    }

    static func getItemsForRestore(_ info: OABackupInfo?,
                                   settingsItems: [OASettingsItem]) -> [OASettingsItem] {
        guard let info, let filtered = info.filteredFilesToDownload as? [OARemoteFile] else { return [] }

        var items = [OASettingsItem]()
        let restoreItems = getRemoteFilesSettingsItems(settingsItems,
                                                       remoteFiles: filtered,
                                                       infoFiles: false)
        for restoreItem in restoreItems.values {
            if let settingsItem = restoreItem as? OACollectionSettingsItem<AnyObject> {
                settingsItem.processDuplicateItems()
                settingsItem.shouldReplace = true
            }
            items.append(restoreItem)
        }
        items.sort { $0.lastModifiedTime > $1.lastModifiedTime }
        return items
    }

    static func getItemsMapForRestore(_ info: OABackupInfo?,
                                      settingsItems: [OASettingsItem]) -> [OARemoteFile: OASettingsItem] {
        guard let info, let filtered = info.filteredFilesToDownload as? [OARemoteFile] else { return [OARemoteFile: OASettingsItem]() }

        return getRemoteFilesSettingsItems(settingsItems,
                                           remoteFiles: filtered,
                                           infoFiles: false)
    }

    static func getRemoteFilesSettingsItems(_ items: [OASettingsItem],
                                            remoteFiles: [OARemoteFile],
                                            infoFiles: Bool) -> [OARemoteFile: OASettingsItem] {
        var res = [OARemoteFile: OASettingsItem]()
        var files = remoteFiles
        for item in items {
            var processedFiles = [OARemoteFile]()
            for file in files {
                var name = file.name as NSString
                if infoFiles && name.pathExtension == OABackupHelper.info_EXT() {
                    name = name.deletingPathExtension as NSString
                }
                
                if applyItem(item, type: file.type, name: name) {
                    if file.item == nil {
                        file.item = item
                    }
                    res[file] = item
                    processedFiles.append(file)
                }
            }
            files.removeAll { processedFiles.contains($0) }
        }
        return res
    }

    static func getBackupTypePref(_ type: OAExportSettingsType) -> OACommonBoolean {
        OACommonBoolean.withKey("\(backupTypePrefix)\(type.name)", defValue: true).makeGlobal()
    }

    static func getVersionHistoryTypePref(_ type: OAExportSettingsType) -> OACommonBoolean {
        OACommonBoolean.withKey("\(versionHistoryPrefix)\(type.name)", defValue: true).makeGlobal().makeShared()
    }

    static func applyItem(_ item: OASettingsItem, type: String, name: NSString) -> Bool {
        let itemFileName = getItemFileName(item)
        let itemTypeName = OASettingsItemType.typeName(item.type)
        if itemTypeName == type {
            if name.isEqual(to: itemFileName) {
                return true
            } else if let fileItem = item as? OAFileSettingsItem {
                let subfolder = OAFileSettingsItemFileSubtype.getFolderName(fileItem.subtype)
                if name.hasPrefix(subfolder) || subfolder.isEmpty {
                    if (fileItem.filePath as NSString).pathExtension.isEmpty, !itemFileName.hasSuffix("/") {
                        return name.hasPrefix("\(itemFileName)/")
                    } else {
                        return name.hasPrefix(itemFileName)
                    }
                }
            }
        }
        return false
    }

    static func getItemFileName(_ item: OASettingsItem) -> String {
        var fileName: String
        if let fileItem = item as? OAFileSettingsItem {
            fileName = getFileItemName(fileItem)
        } else {
            fileName = item.fileName
            if fileName.isEmpty {
                fileName = item.defaultFileName
            }
        }
        if !fileName.isEmpty, fileName.first == "/" {
            fileName.removeFirst()
        }
        return fileName
    }

    static func getFileItemName(_ fileSettingsItem: OAFileSettingsItem) -> String {
        getFileItemName(nil, fileSettingsItem: fileSettingsItem)
    }

    static func getFileItemName(_ filePath: String?,
                                fileSettingsItem: OAFileSettingsItem) -> String {
        let subtypeFolder = OAFileSettingsItemFileSubtype.getFolder(fileSettingsItem.subtype)
        var fileName: String
        let filePath = filePath ?? fileSettingsItem.filePath

        if subtypeFolder.isEmpty {
            fileName = filePath.lastPathComponent()
        } else if fileSettingsItem.subtype == .subtypeGpx {
            fileName = filePath.replacingOccurrences(of: "\(subtypeFolder)/", with: "")
        } else if OAFileSettingsItemFileSubtype.isMap(fileSettingsItem.subtype) {
            fileName = filePath.lastPathComponent()
        } else {
            let index = filePath.index(of: subtypeFolder.lastPathComponent())
            if index >= 0 {
                fileName = filePath.substring(from: Int(index))
            } else {
                fileName = filePath.lastPathComponent()
            }
        }

        if !fileName.isEmpty, fileName.first == "/" {
            fileName.removeFirst()
        }

        return fileName
    }

    static func isLimitedFilesCollectionItem(_ item: OAFileSettingsItem) -> Bool {
        item.subtype == .subtypeVoice
    }

    static func isObfMapExistsOnServer(_ name: String) -> Bool {
        var exists = false
        let params = [
            "name": name,
            "type": "file"
        ]

        let operationLog = OAOperationLog(operationName: "isObfMapExistsOnServer", debug: true)
        operationLog?.startOperation(name)

        OANetworkUtilities.sendRequest(withUrl: "https://osmand.net/userdata/check-file-on-server",
                                       params: params,
                                       post: false,
                                       async: false) { data, response, _ in
            var status: Int32
            var message: String

            guard let data, let httpResponse = response as? HTTPURLResponse else {
                status = STATUS_SERVER_ERROR
                message = "Check obf map on server error: invalid response"
                operationLog?.finishOperation("(\(status)): \(message)")
                return
            }

            let result = String(data: data, encoding: .utf8) ?? ""
            var backupError: OABackupError?
            if httpResponse.statusCode != 200 {
                backupError = OABackupError(error: result)
                message = "Check obf map on server error: \(String(describing: backupError?.toString()))"
                status = STATUS_SERVER_ERROR
            } else if !result.isEmpty {
                do {
                    if let resultJson = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                       let fileStatus = resultJson["status"] as? String {
                        exists = fileStatus == "present"
                        status = STATUS_SUCCESS
                        message = "\(name) exist: \(exists)"
                    } else {
                        message = "Send code error: unknown"
                        status = STATUS_SERVER_ERROR
                    }
                } catch {
                    message = "Check obf map on server error: json parsing"
                    status = STATUS_PARSE_JSON_ERROR
                }
            } else {
                message = "Check obf map on server error: empty response"
                status = STATUS_EMPTY_RESPONSE_ERROR
            }
            operationLog?.finishOperation("(\(status)): \(message)")
        }

        return exists
    }

    static func updateCacheForItems(_ items: [OASettingsItem]) {
        var updateIndexes = false
        var updateRouting = false
        var updateRenderers = false
        var updatePoiFilters = false
        var updateColorPalette = false
        
        for item in items {
            if let fileItem = item as? OAFileSettingsItem {
                updateIndexes = updateIndexes || OAFileSettingsItemFileSubtype.isMap(fileItem.subtype)
                updateRouting = updateRouting || .subtypeRoutingConfig == fileItem.subtype
                updateRenderers = updateRenderers || .subtypeRenderingStyle == fileItem.subtype
                updateColorPalette = updateColorPalette || .subtypeColorPalette == fileItem.subtype
            } else if item is OAPoiUiFilterSettingsItem || item is OAProfileSettingsItem {
                updatePoiFilters = true
            }
        }
        let app = OsmAndApp.swiftInstance()
        if updateColorPalette {
            app?.updateGpxTracksOnMapObservable.notifyEvent()
        }
        if updateIndexes {
            app?.rescanUnmanagedStoragePaths()
            app?.localResourcesChangedObservable.notifyEvent()
        }
        if updateRouting {
            app?.loadRoutingFiles()
        }
        if updateRenderers {
            OARendererRegistry.getExternalRenderers()
        }
        if updatePoiFilters {
            OAPOIFiltersHelper.sharedInstance().loadSelectedPoiFilters()
        }
    }
}
