//
//  OAGenerateBackupInfoTask.m
//  OsmAnd Maps
//
//  Created by Paul on 24.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAGenerateBackupInfoTask.h"
#import "OABackupInfo.h"
#import "OAExportSettingsType.h"
#import "OARemoteFile.h"
#import "OALocalFile.h"
#import "OABackupDbHelper.h"
#import "OACollectionSettingsItem.h"
#import "OABackupHelper.h"
#import "OAFavoritesBackupMerger.h"
#import "OAOperationLog.h"
#import "OAFileSettingsItem.h"

static const NSInteger kMaxDeflateRatio = 1032;

@implementation OAGenerateBackupInfoTask
{
    NSDictionary<NSString *, OALocalFile *> *_localFiles;
    NSDictionary<NSString *, OALocalFile *> *_localFilesWithNormalizedNames;
    NSDictionary<NSString *, OARemoteFile *> *_remoteFilesWithNormalizedNames;
    void (^_onComplete)(OABackupInfo *backupInfo, NSString *error);
    
    OAOperationLog *_operationLog;
}

- (instancetype) initWithLocalFiles:(NSDictionary<NSString *, OALocalFile *> *)localFiles
                  uniqueRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)uniqueRemoteFiles
                 deletedRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)deletedRemoteFiles
                         onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete
{
    self = [super init];
    if (self)
    {
        _localFiles = localFiles;
        NSMutableDictionary<NSString *, OALocalFile *> *normalizedLocalFiles = [NSMutableDictionary dictionaryWithCapacity:_localFiles.count];
        for (NSString *originalKey in _localFiles)
        {
            NSString *normalizedKey = originalKey.precomposedStringWithCanonicalMapping;
            normalizedLocalFiles[normalizedKey] = _localFiles[originalKey];
        }
        _localFilesWithNormalizedNames = normalizedLocalFiles;
        NSMutableDictionary<NSString *, OARemoteFile *>* localMap = [NSMutableDictionary dictionaryWithCapacity:uniqueRemoteFiles.count + deletedRemoteFiles.count];
        for (NSDictionary<NSString *, OARemoteFile *> *files in @[uniqueRemoteFiles, deletedRemoteFiles])
        {
            for (NSString *originalKey in files)
            {
                NSString *normalizedKey = originalKey.precomposedStringWithCanonicalMapping;
                OARemoteFile *remoteFile = files[originalKey];
                OARemoteFile *existing = localMap[normalizedKey];
                if (!existing || [self.class isRemoteFile:remoteFile preferredTo:existing])
                    localMap[normalizedKey] = remoteFile;
            }
        }
        _remoteFilesWithNormalizedNames = localMap;
        _onComplete = onComplete;
        _operationLog = [[OAOperationLog alloc] initWithOperationName:@"generateBackupInfo" debug:BACKUP_DEBUG_LOGS logThreshold:0.2];
        [_operationLog startOperation];
    }
    return self;
}

- (void)main
{
    OABackupInfo *info = [self doInBackground];
    [_operationLog finishOperation:[info toString]];
    NSString *subscriptionError = [self checkSubscriptions];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute:info subscriptionError:subscriptionError];
    });
}

- (OABackupInfo *) doInBackground
{
    OABackupInfo *info = [[OABackupInfo alloc] init];
    NSDictionary<NSString *, OAUploadedFileInfo *> *uploadedFileInfos = [OABackupDbHelper.sharedDatabase getUploadedFileInfoMap];
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
    for (OARemoteFile *remoteFile in _remoteFilesWithNormalizedNames.allValues)
    {
        OAExportSettingsType *exportType = [OAExportSettingsType findByRemoteFile:remoteFile];
        if (exportType == nil || ![OAExportSettingsType isTypeEnabled:exportType] || remoteFile.isRecordedVoiceFile)
            continue;
        NSString* normalizedRemoteName = remoteFile.getTypeNamePath.precomposedStringWithCanonicalMapping;
        OALocalFile *localFile = _localFilesWithNormalizedNames[normalizedRemoteName];
        if (localFile != nil)
        {
            BOOL fileChangedLocally = localFile.localModifiedTime > localFile.uploadTime;
            BOOL fileChangedRemotely = remoteFile.updatetimems > localFile.uploadTime;
            if (fileChangedRemotely && fileChangedLocally)
            {
                if ([self isServerMapReference:localFile remoteFile:remoteFile])
                {
                    // Cloud stores only the map name, nothing to merge
                    long syncTime = MAX(localFile.localModifiedTime, remoteFile.updatetimems);
                    [OABackupHelper.sharedInstance updateFileUploadTime:remoteFile.type fileName:remoteFile.name uploadTime:syncTime];
                    localFile.uploadTime = syncTime;
                }
                else
                {
                    [info.filesToMerge addObject:@[localFile, remoteFile]];
                }
            }
            else if (fileChangedLocally)
            {
                [info.filesToUpload addObject:localFile];
            }
            else if (fileChangedRemotely)
            {
                if (remoteFile.isDeleted)
                    [info.localFilesToDelete addObject:localFile];
                else
                    [info.filesToDownload addObject:remoteFile];
            }
        }
        else if (!remoteFile.isDeleted)
        {
            OAUploadedFileInfo *fileInfo = uploadedFileInfos[[OABackupDbHelper getUploadedFileInfoKey:remoteFile.type name:remoteFile.name]];
            // suggest to remove only if file exists in db
            if (fileInfo != nil && fileInfo.uploadTime >= remoteFile.updatetimems)
            {
                // conflicts not supported yet
                // info.filesToMerge.add(new Pair<>(null, remoteFile));
                [info.filesToDelete addObject:remoteFile];
            }
            else
            {
                [info.filesToDownload addObject:remoteFile];
            }
        }
    }

    for (OALocalFile *localFile in _localFiles.allValues)
    {
        OAExportSettingsType *exportType = localFile.item != nil
            ? [OAExportSettingsType findBySettingsItem:localFile.item]
            : nil;
        if (exportType == nil || ![OAExportSettingsType isTypeEnabled:exportType])
            continue;
        NSString *normalizedLocalKey = localFile.getTypeFileName.precomposedStringWithCanonicalMapping;
        BOOL hasRemoteFile = _remoteFilesWithNormalizedNames[normalizedLocalKey] != nil;
        BOOL fileToDelete = [info.localFilesToDelete containsObject:localFile];
        if (!hasRemoteFile && !fileToDelete)
        {
            BOOL isEmpty = [localFile.item isKindOfClass:OACollectionSettingsItem.class] && ((OACollectionSettingsItem *) localFile.item).isEmpty;
            if (!isEmpty)
                [info.filesToUpload addObject:localFile];
        }
    }
    [OAFavoritesBackupMerger prepareMergeUploads:info backupHelper:OABackupHelper.sharedInstance];
    [info createItemCollections];
    
    [_operationLog log:@"=== filesToUpload ==="];
    for (OALocalFile *localFile in info.filesToUpload)
    {
        [_operationLog log:localFile.toString];
    }
    [_operationLog log:@"=== filesToUpload ==="];
    [_operationLog log:@"=== filesToDownload ==="];
    for (OARemoteFile *remoteFile in info.filesToDownload)
    {
        OALocalFile *localFile = _localFilesWithNormalizedNames[remoteFile.getTypeNamePath.precomposedStringWithCanonicalMapping];
        if (localFile)
            [_operationLog log:[NSString stringWithFormat:@"%@ localUploadTime=%ld", remoteFile.toString, localFile.uploadTime]];
        else
            [_operationLog log:remoteFile.toString];
    }
    [_operationLog log:@"=== filesToDownload ==="];
    [_operationLog log:@"=== filesToDelete ==="];
    for (OARemoteFile *remoteFile in info.filesToDelete)
    {
        [_operationLog log:remoteFile.toString];
    }
    [_operationLog log:@"=== filesToDelete ==="];
    [_operationLog log:@"=== localFilesToDelete ==="];
    for (OALocalFile *localFile in info.localFilesToDelete)
    {
        [_operationLog log:localFile.toString];
    }
    [_operationLog log:@"=== localFilesToDelete ==="];
    [_operationLog log:@"=== filesToMerge ==="];
    for (NSArray *filePair in info.filesToMerge)
    {
        [_operationLog log:[NSString stringWithFormat:@"LOCAL=%@ REMOTE=%@", ((OALocalFile *)filePair.firstObject).toString, ((OARemoteFile *)filePair.lastObject).toString]];
    }
    [_operationLog log:@"=== filesToMerge ==="];
    return info;
}

+ (BOOL) isRemoteFile:(OARemoteFile *)remoteFile preferredTo:(OARemoteFile *)other
{
    if (remoteFile.isDeleted != other.isDeleted)
        return other.isDeleted;
    return remoteFile.updatetimems > other.updatetimems;
}

- (BOOL) isServerMapReference:(OALocalFile *)localFile remoteFile:(OARemoteFile *)remoteFile
{
    if (remoteFile.isDeleted || ![localFile.item isKindOfClass:OAFileSettingsItem.class])
        return NO;
    if (![OAFileSettingsItemFileSubtype isMap:((OAFileSettingsItem *) localFile.item).subtype])
        return NO;
    // A reference stores an empty archive, too small to hold the file even at max deflate ratio
    return remoteFile.zipSize > 0 && remoteFile.zipSize * kMaxDeflateRatio < remoteFile.filesize;
}

- (NSString *) checkSubscriptions
{
    __block NSString *subscriptionError = nil;
    [[OABackupHelper sharedInstance] checkSubscriptions:^(NSInteger status, NSString *message, NSString *error) {
        if (error)
            subscriptionError = error;
    }];
    return subscriptionError;
}

- (void) onPostExecute:(OABackupInfo *)backupInfo subscriptionError:(NSString *)subscriptionError
{
    if (_onComplete)
        _onComplete(backupInfo, subscriptionError);
}

@end
