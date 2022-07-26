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
        _collectListener = collectListener;
        _importType = readData ? EOAImportTypeCollectAndRead : EOAImportTypeCollect;
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
              importListener:(id<OAImportListener>)importListener
               forceReadData:(BOOL)forceReadData
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _key = key;
        _importListener = importListener;
        _items = items;
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
        _duplicatesListener = duplicatesListener;
        _selectedItems = selectedItems;
        _importType = EOAImportTypeCheckDuplicates;
    }
    return self;
}

- (void) commonInit
{
    _helper = OANetworkSettingsHelper.sharedInstance;
    _importer = [[OABackupImporter alloc] initWithListener:self];
}

- (void)main
{
    NSArray<OASettingsItem *> *res = [self doInBackground];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute:res];
    });
}

- (NSArray<OASettingsItem *> *) doInBackground
{
    switch (_importType) {
        case EOAImportTypeCollect:
        case EOAImportTypeCollectAndRead:
        {
            @try
            {
                OACollectItemsResult *result = [_importer collectItems:_importType == EOAImportTypeCollectAndRead];
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
            if (_items.count > 0)
            {
                OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
                OAPrepareBackupResult *backup = backupHelper.backup;
                for (OASettingsItem *item in _items)
                {
                    [item apply];
                    NSString *fileName = item.fileName;
                    if (fileName)
                    {
                        OARemoteFile *remoteFile = [backup getRemoteFile:[OASettingsItemType typeName:item.type] fileName:fileName];
                        if (remoteFile)
                            [backupHelper updateFileUploadTime:remoteFile.type fileName:remoteFile.name uploadTime:remoteFile.clienttimems];
                    }
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
            [_collectListener onBackupCollectFinished:items != nil empty:NO items:_items remoteFiles:_remoteFiles];
            [_helper.importAsyncTasks removeObjectForKey:_key];
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
                OAImportBackupItemsTask *task = [[OAImportBackupItemsTask alloc] initWithImporter:_importer items:items listener:self forceReadData:forceReadData];
                
                [OABackupHelper.sharedInstance.executor addOperation:task];
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

// MARK: OANetworkImportProgressListener

- (void)itemExportDone:(nonnull NSString *)type fileName:(nonnull NSString *)fileName {
    
}

- (void)itemExportStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work {
    
}

- (void)updateItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName progress:(NSInteger)progress {
    
}

// MARK: OAImportItemsListener

- (void)onImportFinished:(BOOL)succeed
{
    [_helper.importAsyncTasks removeObjectForKey:_key];
    [_helper finishImport:_importListener success:succeed items:_items];
}

@end
