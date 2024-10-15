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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSMutableArray<OALocalFile *> *result = [NSMutableArray array];
        _infos = [_dbHelper getUploadedFileInfoMap];
        NSArray<OASettingsItem *> *localItems = [self getLocalItems];
        NSFileManager *fileManager = NSFileManager.defaultManager;
        [_operationLog log:@"getLocalItems"];
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
                    else if (fileItem.subtype == EOASettingsItemFileSubtypeVoice)
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
                    else if (fileItem.subtype == EOASettingsItemFileSubtypeTilesMap)
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
                                    [self createLocalFile:result item:item fileName:fileName filePath:f lastModified:attrs.fileModificationDate.timeIntervalSince1970];
                                }
                            }
                        }
                    }
                    [_operationLog log:[NSString stringWithFormat:@"collectDirs %@ END", filePath.lastPathComponent]];
                }
                else if (fileItem.subtype == EOASettingsItemFileSubtypeTilesMap)
                {
                    if ([filePath.pathExtension.lowerCase isEqualToString:@"sqlitedb"])
                    {
                        NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
                        [self createLocalFile:result item:item fileName:fileName filePath:filePath lastModified:attrs.fileModificationDate.timeIntervalSince1970];
                    }
                }
                else
                {
                    NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
                    [self createLocalFile:result item:item fileName:fileName filePath:filePath lastModified:attrs.fileModificationDate.timeIntervalSince1970];
                }
            }
            else
            {
                [self createLocalFile:result item:item fileName:fileName filePath:nil lastModified:item.lastModifiedTime];
            }
        }
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
        if (fileInfo)
        {
            localFile.uploadTime = fileInfo.uploadTime;
            [self checkM5Digest:localFile fileInfo:fileInfo lastModifiedTime:lastModifiedTime];
        }
    }
    [result addObject:localFile];
    [self publishProgress:localFile];
}

- (void)checkM5Digest:(OALocalFile *)localFile
             fileInfo:(OAUploadedFileInfo *)fileInfo
     lastModifiedTime:(long)lastModifiedTime
{
    NSString *lastMd5 = fileInfo.md5Digest;
    OASettingsItem *item = localFile.item;
    BOOL needM5Digest = [item isKindOfClass:OAFileSettingsItem.class]
        && ((OAFileSettingsItem *) item).needMd5Digest
        && localFile.uploadTime < lastModifiedTime
        && lastMd5.length > 0;
    if (needM5Digest && localFile.filePath && [NSFileManager.defaultManager fileExistsAtPath:localFile.filePath])
    {
        NSString *md5 = [OAUtilities fileMD5:localFile.filePath];
        if ([md5 isEqualToString:lastMd5])
        {
            item.localModifiedTime = localFile.uploadTime;
            localFile.localModifiedTime = localFile.uploadTime;
        }
    }
}

- (NSArray<OASettingsItem *> *) getLocalItems
{
    NSMutableArray<OAExportSettingsType *> *types = [NSMutableArray arrayWithArray:[OAExportSettingsType getEnabledTypes]];
    NSMutableArray<OAExportSettingsType *> *toDelete = [NSMutableArray array];
    for (OAExportSettingsType *type in types)
    {
        if (![BackupUtils getBackupTypePref:type].get)
            [toDelete addObject:type];
    }
    return [OASettingsHelper.sharedInstance getFilteredSettingsItems:types addProfiles:YES doExport:YES];
}

- (void) publishProgress:(OALocalFile *)localFile
{
    if (_listener != nil)
        [_listener onFileCollected:localFile];
}


@end
