//
//  OANetworkWriter.m
//  OsmAnd Maps
//
//  Created by Paul on 08.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OANetworkWriter.h"
#import "OABackupHelper.h"
#import "OABackupListeners.h"
#import "OASettingsItem.h"
#import "OASettingsItemWriter.h"
#import "OAFileSettingsItem.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/ArchiveWriter.h>

@interface OANetworkWriter () <OAOnUploadFileListener>

@end

@implementation OANetworkWriter
{
    OABackupHelper *_backupHelper;
    __weak id<OAOnUploadItemListener> _listener;
    
    OASettingsItem *_item;
    NSString *_itemFileName;
    NSInteger _itemWork;
    
    BOOL _isDirListener;
    NSInteger _itemProgress;
    NSInteger _deltaProgress;
    BOOL _uploadStarted;
    
    NSString *_tmpDir;
}

- (instancetype)initWithListener:(id<OAOnUploadItemListener>)listener
{
    self = [super init];
    if (self) {
        _listener = listener;
        _backupHelper = OABackupHelper.sharedInstance;
        _tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"backup_upload"];
        [NSFileManager.defaultManager createDirectoryAtPath:_tmpDir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSFileManager.defaultManager removeItemAtPath:_tmpDir error:nil];
}

- (void)write:(OASettingsItem *)item
{
    NSString *error = nil;
    NSString *fileName = [BackupUtils getItemFileName:item];
    OASettingsItemWriter *itemWriter = item.getWriter;
    if (itemWriter != nil)
    {
        @try {
            error = [self uploadEntry:itemWriter fileName:fileName];
            if (error == nil)
                error = [self uploadItemInfo:item fileName:[fileName stringByAppendingPathExtension:OABackupHelper.INFO_EXT]];
        }
        @catch (NSException *e)
        {
            @throw [NSException exceptionWithName:@"IOException" reason:e.reason userInfo:nil];
        }
    }
    else
    {
        error = [self uploadItemInfo:item fileName:[fileName stringByAppendingPathExtension:OABackupHelper.INFO_EXT]];
    }
    if (_listener != nil)
    {
        if (!error && [item isKindOfClass:OAFileSettingsItem.class])
            [[LocalFileHashHelper shared] setHashWithFileItem:(OAFileSettingsItem *) item];
        [_listener onItemUploadDone:item fileName:fileName error:error];
    }
    if (error != nil)
    {
        NSLog(@"OANetworkWriter error: %@", error);
        @throw [NSException exceptionWithName:@"IOException" reason:error userInfo:nil];
    }
}

- (NSString *) uploadEntry:(OASettingsItemWriter *)itemWriter
                  fileName:(NSString *)fileName
{
    if ([itemWriter.item isKindOfClass:OAFileSettingsItem.class])
    {
        return [self uploadDirWithFiles:itemWriter fileName:fileName];
    }
    else
    {
        _item = itemWriter.item;
        _isDirListener = NO;
        return [self uploadItemFile:itemWriter fileName:fileName listener:self];
    }
}

- (NSString *) uploadItemInfo:(OASettingsItem *)item fileName:(NSString *)fileName
{
    @try
    {
        MutableOrderedDictionary *json = [MutableOrderedDictionary new];
        [item writeToJson:json];
        BOOL hasFile = json[@"file"] != nil;
        BOOL hasSubtype = json[@"subtype"] != nil;
        if (json.count > (hasFile ? 2 + (hasSubtype ? 1 : 0) : 1))
        {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
            NSString *path = [_tmpDir stringByAppendingPathComponent:fileName];
            [jsonData writeToFile:path atomically:NO];
            BOOL ok = YES;
            QString filePath = QString::fromNSString([path stringByAppendingPathExtension:@"gz"]);
            OsmAnd::ArchiveWriter archiveWriter;
            archiveWriter.createArchive(&ok, filePath, {QString::fromNSString(path)}, QString::fromNSString(_tmpDir), true);
            
            if (!error && ok)
            {
                _item = item;
                _isDirListener = NO;
                return [_backupHelper uploadFile:fileName type:[OASettingsItemType typeName:item.type] data:[NSData dataWithContentsOfFile:filePath.toNSString() options:NSDataReadingMappedAlways error:NULL] size:-1 lastModifiedTime:item.lastModifiedTime * 1000 listener:self];
            }
        }
        return nil;
    }
    @catch (NSException* e)
    {
        @throw [NSException exceptionWithName:@"IOException" reason:e.reason userInfo:nil];
    }
}

- (NSString *)uploadItemFile:(OASettingsItemWriter *)itemWriter
                    fileName:(NSString *)fileName
                    listener:(id<OAOnUploadFileListener>)listener
{
    if ([self isCancelled]) {
        @throw [NSException exceptionWithName:@"InterruptedIOException" reason:@"Network upload was cancelled" userInfo:nil];
    }
    else
    {
        OASettingsItem *item = itemWriter.item;
        NSString *type = [OASettingsItemType typeName:item.type];
        NSData *data = [[NSData alloc] init];
        NSInteger size = -1;
        [self onFileUploadStarted:type fileName:fileName work:0];
        if (![self shouldUseEmptyWriter:itemWriter fileName:fileName])
        {
            OASettingsItem *item = itemWriter.item;
            NSString *fileName = item.fileName;
            if ([fileName hasSuffix:kWorldMiniBasemapKey])
                return nil;
            if (!fileName || fileName.length == 0)
                fileName = item.defaultFileName;
            NSString *path = [_tmpDir stringByAppendingPathComponent:fileName];
            [NSFileManager.defaultManager removeItemAtPath:path error:nil];
            NSError *error = nil;
            [itemWriter writeToFile:path error:&error];
            BOOL ok = YES;
            QString filePath = QString::fromNSString([_tmpDir stringByAppendingPathComponent:[path.lastPathComponent stringByAppendingPathExtension:@"gz"]]);
            OsmAnd::ArchiveWriter archiveWriter;
            archiveWriter.createArchive(&ok, filePath, {QString::fromNSString(path)}, QString::fromNSString(_tmpDir), true);
            if (ok)
                data = [NSData dataWithContentsOfFile:filePath.toNSString() options:NSDataReadingMappedAlways error:NULL];
        }
        else
        {
            if ([item isKindOfClass:OAFileSettingsItem.class])
            {
                OAFileSettingsItem *flItem = (OAFileSettingsItem *) item;
                NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:flItem.filePath error:nil];
                size = attrs.fileSize / 1024;
            }
        }
        return [_backupHelper uploadFile:fileName type:type data:data size:(int) size lastModifiedTime:(item.lastModifiedTime * 1000) listener:self];
    }
}

- (BOOL) shouldUseEmptyWriter:(OASettingsItemWriter *)itemWriter fileName:(NSString *)fileName
{
    OASettingsItem *item = itemWriter.item;
    if ([item isKindOfClass:OAFileSettingsItem.class])
    {
        if ([OAFileSettingsItemFileSubtype isMap:((OAFileSettingsItem *) item).subtype])
            return [BackupUtils isObfMapExistsOnServer:fileName];
    }
    return false;
}

- (NSString *)uploadDirWithFiles:(OASettingsItemWriter *)itemWriter
                        fileName:(NSString *)fileName
{
    OAFileSettingsItem *item = (OAFileSettingsItem *) itemWriter.item;
    NSArray<NSString *> *filesToUpload = [_backupHelper collectItemFilesForUpload:item];
    if (filesToUpload.count == 0)
        return @"No files to upload";
    long size = 0;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    for (NSString *file in filesToUpload)
    {
        NSDictionary *attrs = [fileManager attributesOfItemAtPath:file error:nil];
        size += attrs.fileSize;
    }
    _item = item;
    _itemFileName = fileName;
    _isDirListener = YES;
    _uploadStarted = NO;
    _itemWork = size / 1024;
    _itemProgress = 0;
    _deltaProgress = 0;
    
    for (NSString *file in filesToUpload)
    {
        item.filePath = file;
        NSString *name = [BackupUtils getFileItemName:file fileSettingsItem:item];
        NSString *error = [self uploadItemFile:itemWriter fileName:name listener:self];
        if (error != nil)
            return error;
    }
    return nil;
}

// MARK: OAOnUploadFileListener

- (BOOL)isUploadCancelled {
    return self.isCancelled;
}

- (void)onFileUploadDone:(NSString *)type fileName:(NSString *)fileName uploadTime:(long)uploadTime error:(NSString *)error {
    if ([_item isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *fileItem = (OAFileSettingsItem *) _item;
        NSString *itemFileName = [BackupUtils getFileItemName:fileItem];
        if (itemFileName.pathExtension.length == 0)
        {
            [_backupHelper updateFileUploadTime:[OASettingsItemType typeName:_item.type] fileName:itemFileName uploadTime:uploadTime];
        }
        if (fileItem.needMd5Digest && fileItem.md5Digest.length > 0)
        {
            [_backupHelper updateFileMd5Digest:[OASettingsItemType typeName:_item.type] fileName:itemFileName md5Hex:fileItem.md5Digest];
        }
    }
    if (_listener != nil)
    {
        [_listener onItemFileUploadDone:_item fileName:fileName uploadTime:uploadTime error:error];
    }
}

- (void)onFileUploadProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork {
    if (_listener != nil)
        [_listener onItemUploadProgress:_item fileName:fileName progress:progress deltaWork:deltaWork];
}

- (void)onFileUploadStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work {
    if (_isDirListener)
    {
        _uploadStarted = YES;
        if (_listener != nil)
            [_listener onItemUploadStarted:_item fileName:fileName work:work];
    }
    else
    {
        if (_listener != nil)
            [_listener onItemUploadStarted:_item fileName:fileName work:work];
    }
}

@end
