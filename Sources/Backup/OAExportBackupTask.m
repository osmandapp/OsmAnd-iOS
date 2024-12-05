//
//  OAExportBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAExportBackupTask.h"
#import "OAImportBackupTask.h"
#import "OABackupExporter.h"
#import "OAExportSettingsType.h"
#import "OABackupHelper.h"
#import "OAAppSettings.h"
#import "OALocalFile.h"
#import "OAFileSettingsItem.h"
#import "OAPrepareBackupResult.h"
#import "OARemoteFile.h"
#import "OAConcurrentCollections.h"
#import "OALog.h"

@interface OAExportBackupTask () <OANetworkExportProgressListener>

@end

@implementation OAExportBackupTask
{
    OANetworkSettingsHelper *_helper;
    OABackupExporter *_exporter;
    
    NSString *_key;
    OAConcurrentDictionary<NSString *, OAItemProgressInfo *> *_itemsProgress;
}

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
               itemsToDelete:(NSArray<OASettingsItem *> *)itemsToDelete
               localItemsToDelete:(NSArray<OASettingsItem *> *)localItemsToDelete
                    listener:(id<OABackupExportListener>)listener
{
    self = [super init];
    if (self)
    {
        _key = key;
        _helper = OANetworkSettingsHelper.sharedInstance;
        _listener = listener;
        _exporter = [[OABackupExporter alloc] initWithListener:self];
        _itemsProgress = [[OAConcurrentDictionary alloc] init];
        OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
        for (OASettingsItem *item in items)
        {
            [_exporter addSettingsItem:item];
            
            OAExportSettingsType *exportType = [OAExportSettingsType findBySettingsItem:item];
            if (exportType && [backupHelper getVersionHistoryTypePref:exportType].get)
            {
                [_exporter addOldItemToDelete:item];
            }
        }
        for (OASettingsItem *item in itemsToDelete)
        {
            [_exporter addItemToDelete:item];
        }
        for (OASettingsItem *item in localItemsToDelete)
        {
            [_exporter addLocalItemToDelete:item];
        }
    }
    return self;
}

- (OAItemProgressInfo *) getItemProgressInfo:(NSString *)type fileName:(NSString *)fileName
{
    return [_itemsProgress objectForKeySync:[type stringByAppendingString:fileName]];
}

- (void)main
{
    NSString *res = [self doInBackground];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute:res];
    });
}

- (NSString *)doInBackground
{
    long itemsSize = [self.class getEstimatedItemsSize:_exporter.getItems itemsToDelete:_exporter.getItemsToDelete localItemsToDelete:_exporter.getLocalItemsToDelete oldItemsToDelete:_exporter.getOldItemsToDelete];
    [self publishProgress:@(itemsSize / 1024) isUploadedKb:NO];
    
    NSString *error = nil;
    @try {
        [_exporter export];
    }
    @catch (NSException *e)
    {
        OALog(@"Failed to backup items: %@", e.reason);
        error = e.reason;
    }
    return error;
}

+ (long) getEstimatedItemsSize:(NSArray<OASettingsItem *> *)items
                 itemsToDelete:(NSArray<OASettingsItem *> *)itemsToDelete
                 localItemsToDelete:(NSArray<OASettingsItem *> *)localItemsToDelete
              oldItemsToDelete:(NSArray<OASettingsItem *> *)oldItemsToDelete
{
    long size = 0;
    OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (OASettingsItem *item in items)
    {
        if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            NSArray<NSString *> *filesToUpload = [backupHelper collectItemFilesForUpload:((OAFileSettingsItem *) item)];
            for (NSString *file in filesToUpload)
            {
                NSDictionary *attrs = [fileManager attributesOfItemAtPath:file error:nil];
                size += attrs.fileSize + APPROXIMATE_FILE_SIZE_BYTES;
            }
        } else {
            size += [item getEstimatedSize] + APPROXIMATE_FILE_SIZE_BYTES;
        }
    }
    NSDictionary<NSString *, OARemoteFile *> *remoteFilesMap = [backupHelper.backup getRemoteFiles:EOARemoteFilesTypeUnique];
    if (remoteFilesMap.count > 0)
    {
        for (OARemoteFile *remoteFile in remoteFilesMap.allValues)
        {
            for (OASettingsItem *item in itemsToDelete)
            {
                if ([item isEqual:remoteFile.item])
                {
                    size += APPROXIMATE_FILE_SIZE_BYTES;
                }
            }
        }
        for (OARemoteFile *remoteFile in remoteFilesMap.allValues)
        {
            for (OASettingsItem *item in oldItemsToDelete)
            {
                OASettingsItem *remoteFileItem = remoteFile.item;
                if (remoteFileItem != nil && item.type == remoteFileItem.type)
                {
                    NSString *itemFileName = item.fileName;
                    if (itemFileName != nil && [itemFileName hasPrefix:@"/"])
                    {
                        itemFileName = [itemFileName substringFromIndex:1];
                    }
                    if ([itemFileName isEqualToString:remoteFileItem.fileName])
                    {
                        size += APPROXIMATE_FILE_SIZE_BYTES;
                    }
                }
            }
        }
        NSDictionary<NSString *, OALocalFile *> *localFilesMap = backupHelper.backup.localFiles;
        if (localFilesMap.count > 0)
        {
            for (OALocalFile *localFile in localFilesMap.allValues)
            {
                for (OASettingsItem *item in localItemsToDelete)
                {
                    if ([item isEqual:localFile.item])
                    {
                        size += APPROXIMATE_FILE_SIZE_BYTES;
                    }
                }
            }
        }
    }
    return size;
}

- (void) publishProgress:(id)value isUploadedKb:(BOOL)isUploadedKb
{
    if (_listener != nil)
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            if (isUploadedKb)
            {
                _generalProgress = [((NSNumber *) value) integerValue];
                [_listener onBackupExportProgressUpdate:_generalProgress];
            }
            else
            {
                _maxProgress = [((NSNumber *) value) integerValue];
                [_listener onBackupExportStarted];
            }
        }
        else if ([value isKindOfClass:OAItemProgressInfo.class])
        {
            OAItemProgressInfo *info = (OAItemProgressInfo *) value;
            
            OAItemProgressInfo *prevInfo = [self getItemProgressInfo:info.type fileName:info.fileName];
            if (prevInfo != nil)
                info.work = prevInfo.work;
            [_itemsProgress setObjectSync:info forKey:[info.type stringByAppendingString:info.fileName]];
            
            if (info.finished)
                [_listener onBackupExportItemFinished:info.type fileName:info.fileName];
            else if (info.value == 0)
                [_listener onBackupExportItemStarted:info.type fileName:info.fileName work:info.work];
            else
                [_listener onBackupExportItemProgress:info.type fileName:info.fileName value:info.value];
        }
    }
}

- (void)cancel
{
    [super cancel];
    [self onPostExecute:nil];
}

- (void) onPostExecute:(NSString *)error
{
    [_helper.exportAsyncTasks removeObjectForKey:_key];
    
    OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
    [backupHelper.backup setError:error];
    
    if (_listener)
        [_listener onBackupExportFinished:error];
}

// MARK: OANetworkExportProgressListener

- (void)itemExportDone:(nonnull NSString *)type fileName:(nonnull NSString *)fileName {
    [self publishProgress:[[OAItemProgressInfo alloc] initWithType:type fileName:fileName progress:0 work:0 finished:YES] isUploadedKb:NO];
}

- (void)itemExportStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work {
    [self publishProgress:[[OAItemProgressInfo alloc] initWithType:type fileName:fileName progress:0 work:work finished:NO] isUploadedKb:NO];
}

- (void)networkExportDone:(nonnull NSDictionary<NSString *,NSString *> *)errors {
}

- (void)updateGeneralProgress:(NSInteger)uploadedItems uploadedKb:(NSInteger)uploadedKb {
    if (self.isCancelled)
        [_exporter cancel];
    [self publishProgress:@(uploadedKb) isUploadedKb:YES];
}

- (void)updateItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName progress:(NSInteger)progress {
    [self publishProgress:[[OAItemProgressInfo alloc] initWithType:type fileName:fileName progress:progress work:0 finished:NO] isUploadedKb:NO];
}

@end


