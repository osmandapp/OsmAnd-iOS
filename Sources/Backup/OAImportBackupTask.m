//
//  OAImportBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAImportBackupTask.h"
#import "OABackupImporter.h"
#import "OANetworkSettingsHelper.h"

@interface OAItemProgressInfo ()

@property (nonatomic) NSString *type;
@property (nonatomic) NSString *fileName;

@end

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

@interface OAImportBackupTask () <OANetworkImportProgressListener>

@end

@implementation OAImportBackupTask
{
    OANetworkSettingsHelper *_helper;
    
    __weak id<OAImportListener> _importListener;
    __weak id<OABackupCollectListener> _collectListener;
    __weak id<OACheckDuplicatesListener> _duplicatesListener;
    OABackupImporter *_importer;
    NSArray<OASettingsItem *> *_items;
    NSArray<OASettingsItem *> *_selectedItems;
    NSArray *_duplicates;
    
    NSArray<OARemoteFile *> *_remoteFiles;
    
    NSString *_key;
    NSMutableDictionary<NSString *, OAItemProgressInfo *> *_itemsProgress;
    EOAImportType _importType;
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

// MARK: OANetworkImportProgressListener

@end
