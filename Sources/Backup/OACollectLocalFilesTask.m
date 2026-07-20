//
//  OAСollectLocalFilesTask.m
//  OsmAnd Maps
//
//  Created by Paul on 07.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACollectLocalFilesTask.h"
#import "OABackupDbHelper.h"
#import "OALocalFile.h"
#import "OABackupHelper.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItem.h"
#import "OAGpxSettingsItem.h"
#import "OASettingsItemType.h"
#import "OAExportSettingsType.h"
#import "OAAppSettings.h"
#import "OASettingsHelper.h"
#import "OAOperationLog.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OACollectLocalFilesTask
{
    OABackupDbHelper *_dbHelper;
    NSDictionary<NSString *, OAUploadedFileInfo *> *_infos;
    
    id<OAOnCollectLocalFilesListener> _listener;
    
    OAOperationLog *_operationLog;
}

- (instancetype) initWithListener:(id<OAOnCollectLocalFilesListener>)listener
{
    self = [super init];
    if (self) {
        _dbHelper = OABackupDbHelper.sharedDatabase;
        _listener = listener;
        _operationLog = [[OAOperationLog alloc] initWithOperationName:@"collectLocalFiles" debug:BACKUP_DEBUG_LOGS];
        [_operationLog startOperation];
    }
    return self;
}

- (void) execute
{
    CFAbsoluteTime executeStartTime = CFAbsoluteTimeGetCurrent();
    [_operationLog log:@"COLLECT_LOCAL_DIAG execute BEGIN"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG worker BEGIN queueWait=%.3f ms",
                            (CFAbsoluteTimeGetCurrent() - executeStartTime) * 1000]];

        NSMutableArray<OALocalFile *> *result = [NSMutableArray array];
        CFAbsoluteTime phaseStartTime = CFAbsoluteTimeGetCurrent();
        [_operationLog log:@"COLLECT_LOCAL_DIAG getUploadedFileInfoMap BEGIN"];
        _infos = [_dbHelper getUploadedFileInfoMap];
        [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG getUploadedFileInfoMap END duration=%.3f ms count=%ld",
                            (CFAbsoluteTimeGetCurrent() - phaseStartTime) * 1000,
                            _infos.count]];

        phaseStartTime = CFAbsoluteTimeGetCurrent();
        [_operationLog log:@"COLLECT_LOCAL_DIAG getLocalItems BEGIN"];
        NSArray<OASettingsItem *> *localItems = [self getLocalItems];
        [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG getLocalItems END duration=%.3f ms count=%ld",
                            (CFAbsoluteTimeGetCurrent() - phaseStartTime) * 1000,
                            localItems.count]];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        [_operationLog log:@"getLocalItems"];
        phaseStartTime = CFAbsoluteTimeGetCurrent();
        [_operationLog log:@"COLLECT_LOCAL_DIAG createLocalFiles loop BEGIN"];
        for (OASettingsItem *item in localItems)
        {
            NSString *fileName = [BackupUtils getItemFileName:item];
            if ([item isKindOfClass:OAFileSettingsItem.class])
            {
                OAFileSettingsItem *fileItem = (OAFileSettingsItem *) item;
                NSString *filePath = fileItem.filePath;
                BOOL isDir = NO;
                [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
                if (isDir)
                {
                    if ([item isKindOfClass:OAGpxSettingsItem.class])
                    {
                        continue;
                    }
                    // TODO: support voice imports
                    else if (fileItem.subtype == EOAFileSettingsItemFileSubtypeVoice)
                    {
                        
                        continue;
//                        File jsFile = new File(file, file.getName() + "_" + IndexConstants.TTSVOICE_INDEX_EXT_JS);
//                        if (jsFile.exists()) {
//                            fileName = jsFile.getPath().replace(app.getAppPath(null).getPath() + "/", "");
//                            createLocalFile(result, item, fileName, jsFile, jsFile.lastModified());
//                            continue;
//                        }
                    }
//                    else if (fileItem.subtype == Subtype) {
//                        String langName = file.getName().replace(IndexConstants.VOICE_PROVIDER_SUFFIX, "");
//                        File jsFile = new File(file, langName + "_" + IndexConstants.TTSVOICE_INDEX_EXT_JS);
//                        if (jsFile.exists()) {
//                            fileName = jsFile.getPath().replace(app.getAppPath(null).getPath() + "/", "");
//                            createLocalFile(result, item, fileName, jsFile, jsFile.lastModified());
//                            continue;
//                        }
//                    }
                    else if (fileItem.subtype == EOAFileSettingsItemFileSubtypeTilesMap)
                    {
                        continue;
                    }
                    NSMutableArray<NSString *> *dirs = [NSMutableArray array];
                    [dirs addObject:filePath];
                    [OAUtilities collectDirFiles:filePath list:dirs];
                    [_operationLog log:[NSString stringWithFormat:@"collectDirs %@ BEGIN", filePath.lastPathComponent]];
                    for (NSString *dir in dirs)
                    {
                        NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:dir error:nil];
                        if (files.count > 0)
                        {
                            for (NSString *f in files)
                            {
                                BOOL isDir = NO;
                                [fileManager fileExistsAtPath:f isDirectory:&isDir];
                                if (!isDir)
                                {
                                    fileName = f.lastPathComponent;
                                    NSDictionary *attrs = [fileManager attributesOfItemAtPath:f error:nil];
                                    [self createLocalFile:result
                                                     item:item
                                                 fileName:fileName
                                                 filePath:f
                                             lastModified:attrs.fileModificationDate.timeIntervalSince1970 * 1000];
                                }
                            }
                        }
                    }
                    [_operationLog log:[NSString stringWithFormat:@"collectDirs %@ END", filePath.lastPathComponent]];
                }
                else if (fileItem.subtype == EOAFileSettingsItemFileSubtypeTilesMap)
                {
                    if ([filePath.pathExtension.lowerCase isEqualToString:@"sqlitedb"])
                    {
                        NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
                        [self createLocalFile:result
                                         item:item
                                     fileName:fileName
                                     filePath:filePath
                                 lastModified:attrs.fileModificationDate.timeIntervalSince1970 * 1000];
                    }
                }
                else
                {
                    NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
                    [self createLocalFile:result
                                     item:item
                                 fileName:fileName
                                 filePath:filePath
                             lastModified:attrs.fileModificationDate.timeIntervalSince1970 * 1000];
                }
            }
            else
            {
                [self createLocalFile:result
                                 item:item
                             fileName:fileName
                             filePath:nil
                         lastModified:item.lastModifiedTime];
            }
        }
        [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG createLocalFiles loop END duration=%.3f ms files=%ld",
                            (CFAbsoluteTimeGetCurrent() - phaseStartTime) * 1000,
                            result.count]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_operationLog finishOperation:[NSString stringWithFormat:@"Files=%ld", result.count]];
            if (_listener)
                [_listener onFilesCollected:result];
        });
    });
    
}

- (void) createLocalFile:(NSMutableArray<OALocalFile *> *)result item:(OASettingsItem *)item
                fileName:(NSString *)fileName
                filePath:(NSString *)filePath
            lastModified:(long)lastModifiedTime
{
    OALocalFile *localFile = [[OALocalFile alloc] init];
    localFile.filePath = filePath;
    localFile.item = item;
    localFile.fileName = fileName;
    localFile.localModifiedTime = lastModifiedTime;
    
    if (_infos != nil)
    {
        OAUploadedFileInfo *fileInfo = _infos[[NSString stringWithFormat:@"%@___%@", [OASettingsItemType typeName:item.type], fileName]];
        if (!fileInfo)
            fileInfo = _infos[[NSString stringWithFormat:@"%@___%@", [OASettingsItemType typeName:item.type], fileName.precomposedStringWithCanonicalMapping]];
        if (fileInfo)
        {
            localFile.uploadTime = fileInfo.uploadTime;
            NSString *lastMd5 = fileInfo.md5Digest;
            BOOL needM5Digest = [item isKindOfClass:OAFileSettingsItem.class]
                && ((OAFileSettingsItem *) item).needMd5Digest
                && localFile.uploadTime < lastModifiedTime
                && lastMd5.length > 0;
            if (needM5Digest && filePath && [NSFileManager.defaultManager fileExistsAtPath:filePath])
            {
                CFAbsoluteTime md5StartTime = CFAbsoluteTimeGetCurrent();
                NSString *md5 = [OAUtilities fileMD5:filePath];
                CFAbsoluteTime md5DurationMs = (CFAbsoluteTimeGetCurrent() - md5StartTime) * 1000;
                if (md5DurationMs >= 50)
                {
                    [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG slow fileMD5 duration=%.3f ms file=%@",
                                        md5DurationMs,
                                        fileName]];
                }
                if ([md5 isEqualToString:lastMd5])
                {
                    item.localModifiedTime = localFile.uploadTime;
                    localFile.localModifiedTime = localFile.uploadTime;
                }
            }
        }
    }
    [result addObject:localFile];
    [self publishProgress:localFile];
}

- (NSArray<OASettingsItem *> *) getLocalItems
{
    CFAbsoluteTime phaseStartTime = CFAbsoluteTimeGetCurrent();
    NSArray<OAExportSettingsType *> *types = [self getEnabledExportTypes];
    [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG getEnabledExportTypes END duration=%.3f ms count=%ld",
                        (CFAbsoluteTimeGetCurrent() - phaseStartTime) * 1000,
                        types.count]];

    phaseStartTime = CFAbsoluteTimeGetCurrent();
    NSArray<OASettingsItem *> *items = [OASettingsHelper.sharedInstance getFilteredSettingsItems:types addProfiles:YES doExport:YES];
    [_operationLog log:[NSString stringWithFormat:@"COLLECT_LOCAL_DIAG getFilteredSettingsItems END duration=%.3f ms count=%ld",
                        (CFAbsoluteTimeGetCurrent() - phaseStartTime) * 1000,
                        items.count]];
    return items;
}

- (NSArray<OAExportSettingsType *> *)getEnabledExportTypes
{
    NSMutableArray<OAExportSettingsType *> *result = [NSMutableArray array];
    for (OAExportSettingsType *exportType in [OAExportSettingsType getEnabledTypes])
    {
        if ([[BackupUtils getBackupTypePref:exportType] get])
            [result addObject:exportType];
    }
    return result;
}

- (void) publishProgress:(OALocalFile *)localFile
{
    if (_listener != nil)
        [_listener onFileCollected:localFile];
}


@end
