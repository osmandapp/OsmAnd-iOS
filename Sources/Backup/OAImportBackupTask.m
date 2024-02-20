//
//  OAImportBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAImportBackupTask.h"
#import "OABackupImporter.h"
#import "OAProfileSettingsItem.h"
#import "OACollectionSettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OAPrepareBackupResult.h"
#import "OABackupHelper.h"
#import "OARemoteFile.h"
#import "OASettingsHelper.h"
#import "OAImportBackupItemsTask.h"
#import "OASettingsImporter.h"
#import "OABackupInfo.h"

@implementation OAItemProgressInfo

- (instancetype) initWithType:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress work:(NSInteger)work finished:(BOOL)finished
{
    self = [super init];
    if (self)
    {
        _type = type;
        _fileName = fileName;
        _work = work;
        _value = progress;
        _finished = finished;
    }
    return self;
}

@end

@interface OAImportBackupTask () <OANetworkImportProgressListener, OAImportItemsListener>

@end

@implementation OAImportBackupTask
{
    OANetworkSettingsHelper *_helper;

    __weak id<OABackupCollectListener> _collectListener;
    OABackupImporter *_importer;
    EOARemoteFilesType _filesType;
    BOOL _shouldReplace;
    BOOL _restoreDeleted;

    NSArray<OARemoteFile *> *_remoteFiles;
    
    NSString *_key;
    NSMutableDictionary<NSString *, OAItemProgressInfo *> *_itemsProgress;
}

- (instancetype) initWithKey:(NSString *)key
             collectListener:(id<OABackupCollectListener>)collectListener
                    readData:(BOOL)readData
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _key = key;
        _filesType = EOARemoteFilesTypeUnique;
        _collectListener = collectListener;
        _importType = readData ? EOAImportTypeCollectAndRead : EOAImportTypeCollect;
        _shouldReplace = YES;
        _restoreDeleted = NO;
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
                   filesType:(EOARemoteFilesType)filesType
              importListener:(id<OAImportListener>)importListener
               forceReadData:(BOOL)forceReadData
               shouldReplace:(BOOL)shouldReplace
              restoreDeleted:(BOOL)restoreDeleted
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _key = key;
        _filesType = filesType;
        _importListener = importListener;
        _items = items;
        _shouldReplace = shouldReplace;
        _restoreDeleted = restoreDeleted;
        _importType = forceReadData ? EOAImportTypeImportForceRead : EOAImportTypeImport;
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
               selectedItems:(NSArray<OASettingsItem *> *)selectedItems
          duplicatesListener:(id<OACheckDuplicatesListener>)duplicatesListener
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _key = key;
        _items = items;
        _filesType = EOARemoteFilesTypeUnique;
        _duplicatesListener = duplicatesListener;
        _selectedItems = selectedItems;
        _importType = EOAImportTypeCheckDuplicates;
        _shouldReplace = YES;
        _restoreDeleted = NO;
    }
    return self;
}

- (void) commonInit
{
    _helper = OANetworkSettingsHelper.sharedInstance;
    _importer = [[OABackupImporter alloc] initWithListener:self];
    _itemsProgress = [NSMutableDictionary dictionary];
    _maxProgress = [self.class calculateMaxProgress];
}

+ (NSInteger) calculateMaxProgress
{
    NSInteger maxProgress = 0;
    OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
    OAPrepareBackupResult *backup = backupHelper.backup;
    for (OARemoteFile *file in backup.backupInfo.filesToDownload)
        maxProgress += [backupHelper calculateFileSize:file];
    return maxProgress;
}

- (OAItemProgressInfo *) getItemProgressInfo:(NSString *)type fileName:(NSString *)fileName
{
    return _itemsProgress[[type stringByAppendingString:fileName]];
}

- (void)main
{
    NSArray<OASettingsItem *> *res = [self doInBackground];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute:res];
    });
}

- (void)fetchRemoteFileInfo:(OARemoteFile *)remoteFile itemsJson:(NSMutableArray *)itemsJson
{
    NSString *filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"backupTmp"] stringByAppendingPathComponent:remoteFile.name];
    NSString *errStr = [OABackupHelper.sharedInstance downloadFile:filePath remoteFile:remoteFile listener:nil];
    if (!errStr)
    {
        
        NSError *err = nil;
        NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&err];
        if (!err && data)
        {
            NSError *jsonErr = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonErr];
            if (json && !jsonErr)
                [itemsJson addObject:json];
            else
                NSLog(@"importBackupTask error: filePath:%@ %@", filePath, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        else
        {
            @throw [NSException exceptionWithName:@"IOException" reason:[NSString stringWithFormat:@"Error reading item info: %@", filePath.lastPathComponent] userInfo:nil];
        }
    }
}

- (void)updateFileUploadTime:(OAPrepareBackupResult *)backup backupHelper:(OABackupHelper *)backupHelper fileName:(NSString *)fileName item:(OASettingsItem *)item {
    if (fileName)
    {
        OARemoteFile *remoteFile = [backup getRemoteFile:[OASettingsItemType typeName:item.type] fileName:fileName];
        if (remoteFile)
            [backupHelper updateFileUploadTime:remoteFile.type fileName:remoteFile.name uploadTime:remoteFile.clienttimems];
    }
}

- (NSArray<OASettingsItem *> *) doInBackground
{
    switch (_importType) {
        case EOAImportTypeCollect:
        case EOAImportTypeCollectAndRead:
        {
            @try
            {
                OACollectItemsResult *result = [_importer collectItems:nil readItems:_importType == EOAImportTypeCollectAndRead restoreDeleted:_restoreDeleted];
                _remoteFiles = result.remoteFiles;
                return result.items;
            }
            @catch (NSException *e)
            {
                NSLog(@"Failed to collect items for backup: %@", e.reason);
            }
            return nil;
        }
        case EOAImportTypeCheckDuplicates:
        {
            _duplicates = [self getDuplicatesData:_selectedItems];
            return _selectedItems;
        }
        case EOAImportTypeImport:
        case EOAImportTypeImportForceRead:
        {
            if (_importType == EOAImportTypeImportForceRead)
            {
                @try
                {
                    OACollectItemsResult *result = [_importer collectItems:_items readItems:YES restoreDeleted:_restoreDeleted];
                    for (OASettingsItem *item in result.items)
                    {
                        [item setShouldReplace:_shouldReplace];
                    }
                    _items = result.items;
                }
                @catch (NSException *e)
                {
                    NSLog(@"Failed to recollect items for backup import: %@", e.reason);
                    return nil;
                }
            }
            else
            {
                for (OASettingsItem *item in _items)
                {
                    [item apply];
                }
            }
            return _items;
        }
        default:
        {
            return nil;
        }
    }
}

- (void) onPostExecute:(NSArray<OASettingsItem *> *)items
{
    if (items != nil && _importType != EOAImportTypeCheckDuplicates)
        _items = items;
    else
        _selectedItems = items;
    
    switch (_importType)
    {
        case EOAImportTypeCollect:
        case EOAImportTypeCollectAndRead:
        {
            [_helper.importAsyncTasks removeObjectForKey:_key];
            [_collectListener onBackupCollectFinished:items != nil empty:NO items:_items remoteFiles:_remoteFiles];
            break;
        }
        case EOAImportTypeCheckDuplicates:
        {
            [_helper.importAsyncTasks removeObjectForKey:_key];
            if (_duplicatesListener)
                [_duplicatesListener onDuplicatesChecked:_duplicates items:_selectedItems];
            break;
        }
        case EOAImportTypeImport:
        case EOAImportTypeImportForceRead:
        {
            if (items.count > 0)
            {
                BOOL forceReadData = _importType == EOAImportTypeImportForceRead;
                OAImportBackupItemsTask *task = [[OAImportBackupItemsTask alloc] initWithImporter:_importer
                                                                                            items:items
                                                                                        filesType:_filesType
                                                                                         listener:self
                                                                                    forceReadData:forceReadData
                                                                                   restoreDeleted:_restoreDeleted];
                
                [OABackupHelper.sharedInstance.executor addOperation:task];
            }
            else {
                [_helper.importAsyncTasks removeObjectForKey:_key];
                [_helper finishImport:_importListener success:NO items:@[]];
            }
            break;
        }
        default:
        {
            return;
        }
    }
}

- (NSArray *) getDuplicatesData:(NSArray<OASettingsItem *> *)items
{
    NSMutableArray *duplicateItems = [NSMutableArray array];
    for (OASettingsItem *item in items)
    {
        if ([item isKindOfClass:OAProfileSettingsItem.class])
        {
            if (item.exists)
                [duplicateItems addObject:((OAProfileSettingsItem *) item).modeBean];
        }
        else if ([item isKindOfClass:OACollectionSettingsItem.class])
        {
            OACollectionSettingsItem *settingsItem = (OACollectionSettingsItem *) item;
            NSArray *duplicates = [settingsItem processDuplicateItems];
            if (duplicates.count > 0 && settingsItem.shouldShowDuplicates)
                [duplicateItems addObjectsFromArray:duplicates];
        }
        else if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            if (item.exists)
                [duplicateItems addObject:((OAFileSettingsItem *) item).filePath];
        }
    }
    return duplicateItems;
}

- (void) onProgressUpdate:(OAItemProgressInfo *)info
{
    if (_importListener)
    {
        OAItemProgressInfo *prevInfo = [self getItemProgressInfo:info.type fileName:info.fileName];
        if (prevInfo)
            info.work = prevInfo.work;
        
        _itemsProgress[[info.type stringByAppendingString:info.fileName]] = info;
        
        if (info.finished)
            [_importListener onImportItemFinished:info.type fileName:info.fileName];
        else if (info.value == 0)
            [_importListener onImportItemStarted:info.type fileName:info.fileName work:info.work];
        else
            [_importListener onImportItemProgress:info.type fileName:info.fileName value:info.value];
    }
}

// MARK: OANetworkImportProgressListener

- (void)itemExportDone:(nonnull NSString *)type fileName:(nonnull NSString *)fileName {
    [self onProgressUpdate:[[OAItemProgressInfo alloc] initWithType:type fileName:fileName progress:0 work:0 finished:YES]];
    if ([self isCancelled])
        _importer.cancelled = YES;
}

- (void)itemExportStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work {
    [self onProgressUpdate:[[OAItemProgressInfo alloc] initWithType:type fileName:fileName progress:0 work:work finished:NO]];
}

- (void)updateItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName progress:(NSInteger)progress {
    [self onProgressUpdate:[[OAItemProgressInfo alloc] initWithType:type fileName:fileName progress:progress work:0 finished:NO]];
}

- (void)updateGeneralProgress:(NSInteger)downloadedItems uploadedKb:(NSInteger)uploadedKb
{
    _generalProgress = uploadedKb;
    [_importListener onImportProgressUpdate:_generalProgress uploadedKb:uploadedKb];
}

// MARK: OAImportItemsListener

- (void)onImportFinished:(BOOL)succeed
{
    [_helper.importAsyncTasks removeObjectForKey:_key];
    [_helper finishImport:_importListener success:succeed items:_items];
}

@end
