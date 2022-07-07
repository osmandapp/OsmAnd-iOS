//
//  OABackupInfoGenerationTask.m
//  OsmAnd Maps
//
//  Created by Paul on 24.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupInfoGenerationTask.h"
#import "OABackupInfo.h"
#import "OAExportSettingsType.h"
#import "OARemoteFile.h"
#import "OALocalFile.h"
#import "OABackupDbHelper.h"
#import "OACollectionSettingsItem.h"

@implementation OABackupInfoGenerationTask
{
    NSDictionary<NSString *, OALocalFile *> *_localFiles;
    NSDictionary<NSString *, OARemoteFile *> *_uniqueRemoteFiles;
    NSDictionary<NSString *, OARemoteFile *> *_deletedRemoteFiles;
    void (^_onComplete)(OABackupInfo *backupInfo, NSString *error);
}

- (instancetype) initWithLocalFiles:(NSDictionary<NSString *, OALocalFile *> *)localFiles
                  uniqueRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)uniqueRemoteFiles
                 deletedRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)deletedRemoteFiles
                         onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete
{
    self = [super init];
    if (self) {
        _localFiles = localFiles;
        _uniqueRemoteFiles = uniqueRemoteFiles;
        _deletedRemoteFiles = deletedRemoteFiles;
        _onComplete = onComplete;
    }
    return self;
}

- (void)main
{
    OABackupInfo *info = [self doInBackground];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute:info];
    });
}

- (OABackupInfo *) doInBackground
{
    OABackupInfo *info = [[OABackupInfo alloc] init];
    /*
     operationLog.log("=== localFiles ===");
     for (LocalFile localFile : localFiles.values()) {
     operationLog.log(localFile.toString());
     }
     operationLog.log("=== localFiles ===");
     operationLog.log("=== uniqueRemoteFiles ===");
     for (RemoteFile remoteFile : uniqueRemoteFiles.values()) {
     operationLog.log(remoteFile.toString());
     }
     operationLog.log("=== uniqueRemoteFiles ===");
     operationLog.log("=== deletedRemoteFiles ===");
     for (RemoteFile remoteFile : deletedRemoteFiles.values()) {
     operationLog.log(remoteFile.toString());
     }
     operationLog.log("=== deletedRemoteFiles ===");
     */
    NSMutableArray<OARemoteFile *> *remoteFiles = [NSMutableArray arrayWithArray:_uniqueRemoteFiles.allValues];
    [remoteFiles addObjectsFromArray:_deletedRemoteFiles.allValues];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    for (OARemoteFile *remoteFile in remoteFiles)
    {
        OAExportSettingsType *exportType = [OAExportSettingsType getExportSettingsTypeForRemoteFile:remoteFile];
        if (exportType == nil || ![OAExportSettingsType isTypeEnabled:exportType] || remoteFile.isRecordedVoiceFile)
        {
            continue;
        }
        OALocalFile *localFile = _localFiles[remoteFile.getTypeNamePath];
        if (localFile != nil)
        {
            long remoteUploadTime = remoteFile.clienttimems;
            long localUploadTime = localFile.uploadTime;
            if (remoteFile.isDeleted)
            {
                [info.localFilesToDelete addObject:localFile];
            }
            else if (remoteUploadTime == localUploadTime)
            {
                if (localUploadTime < localFile.localModifiedTime)
                {
                    [info.filesToUpload addObject:localFile];
                    [info.filesToDownload addObject:remoteFile];
                }
            }
            else
            {
                [info.filesToMerge addObject:@[localFile, remoteFile]];
                [info.filesToDownload addObject:remoteFile];
            }
            NSDictionary *attributes = localFile.filePath ? [fileManager attributesOfItemAtPath:localFile.filePath error:NULL] : @{};
            long localFileSize = attributes.fileSize;
            long remoteFileSize = remoteFile.filesize;
            if (remoteFileSize > 0 && localFileSize > 0 && localFileSize != remoteFileSize && ![info.filesToDownload containsObject:remoteFile])
            {
                [info.filesToDownload addObject:remoteFile];
            }
        }
        if (localFile == nil && !remoteFile.isDeleted)
        {
            OAUploadedFileInfo *fileInfo = [OABackupDbHelper.sharedDatabase getUploadedFileInfo:remoteFile.type name:remoteFile.name];
            // suggest to remove only if file exists in db
            if (fileInfo != nil)
            {
                [info.filesToDelete addObject:remoteFile];
            }
            [info.filesToDownload addObject:remoteFile];
        }
    }
    for (OALocalFile *localFile in _localFiles.allValues)
    {
        OAExportSettingsType *exportType = localFile.item != nil
        ? [OAExportSettingsType getExportSettingsTypeForItem:localFile.item] : nil;
        if (exportType == nil || ![OAExportSettingsType isTypeEnabled:exportType])
            continue;
        
        BOOL hasRemoteFile = _uniqueRemoteFiles[localFile.getTypeFileName] != nil;
        if (!hasRemoteFile)
        {
            BOOL isEmpty = [localFile.item isKindOfClass:OACollectionSettingsItem.class] && ((OACollectionSettingsItem *) localFile.item).isEmpty;
            if (!isEmpty)
                [info.filesToUpload addObject:localFile];
        }
    }
    [info createItemCollections];
    
//    operationLog.log("=== filesToUpload ===");
//    for (OALocalFile *localFile in info.filesToUpload)
//    {
//        operationLog.log(localFile.toString());
//    }
//    operationLog.log("=== filesToUpload ===");
//    operationLog.log("=== filesToDownload ===");
//    for (RemoteFile remoteFile : info.filesToDownload) {
//        operationLog.log(remoteFile.toString());
//    }
//    operationLog.log("=== filesToDownload ===");
//    operationLog.log("=== filesToDelete ===");
//    for (RemoteFile remoteFile : info.filesToDelete) {
//        operationLog.log(remoteFile.toString());
//    }
//    operationLog.log("=== filesToDelete ===");
//    operationLog.log("=== filesToMerge ===");
//    for (Pair<LocalFile, RemoteFile> filePair : info.filesToMerge) {
//        operationLog.log("LOCAL=" + filePair.first.toString() + " REMOTE=" + filePair.second.toString());
//    }
//    operationLog.log("=== filesToMerge ===");
    return info;
}

- (void) onPostExecute:(OABackupInfo *)backupInfo
{
//    operationLog.finishOperation(backupInfo.toString());
    if (_onComplete)
        _onComplete(backupInfo, nil);
}

@end
