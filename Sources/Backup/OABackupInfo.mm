//
//  OABackupInfo.m
//  OsmAnd Maps
//
//  Created by Paul on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupInfo.h"
#import "OsmAndApp.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OABackupHelper.h"
#import "OAExportSettingsType.h"

@implementation OABackupInfo
{
    OsmAndAppInstance _app;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _filesToDownload = [NSMutableArray array];
        _filesToUpload = [NSMutableArray array];
        _filesToDelete = [NSMutableArray array];
        _localFilesToDelete = [NSMutableArray array];
        _filesToMerge = [NSMutableArray array];
        
        _app = OsmAndApp.instance;
    }
    return self;
}

- (void) createItemCollections
{
    [self createFilteredFilesToUpload];
    [self createItemsToUpload];
    [self createFilteredFilesToDelete];
    [self createItemsToDelete];
    [self createFilteredFilesToMerge];
}

- (void) createItemsToUpload
{
    NSMutableSet<OASettingsItem *> *items = [NSMutableSet set];
    for (OALocalFile *localFile in _filteredFilesToUpload)
    {
        OASettingsItem *item = localFile.item;
        if (item)
            [items addObject:item];
    }
    _itemsToUpload = [NSMutableArray arrayWithArray:items.allObjects];
}

- (void) createItemsToDelete
{
    NSMutableSet<OASettingsItem *> *items = [NSMutableSet set];
    for (OARemoteFile *remoteFile in _filteredFilesToDelete) {
        OASettingsItem *item = remoteFile.item;
        if (item)
            [items addObject:item];
    }
    _itemsToDelete = [NSMutableArray arrayWithArray:items.allObjects];
}

- (void) createFilteredFilesToUpload
{
    NSMutableArray<OALocalFile *> *files = [NSMutableArray array];
    OABackupHelper *helper = OABackupHelper.sharedInstance;
    for (OALocalFile *localFile in _filesToUpload)
    {
        OAExportSettingsType *type = localFile.item != nil ? [OAExportSettingsType getExportSettingsTypeForItem:localFile.item] : nil;
        if (type != nil && [helper getBackupTypePref:type].get)
        {
            [files addObject:localFile];
        }
    }
    _filteredFilesToUpload = files;
}

- (void) createFilteredFilesToDelete
{
    NSMutableArray<OARemoteFile *> *files = [NSMutableArray array];
    OABackupHelper *helper = OABackupHelper.sharedInstance;
    for (OARemoteFile *remoteFile in _filesToDelete)
    {
        OAExportSettingsType *exportType = [OAExportSettingsType getExportSettingsTypeForRemoteFile:remoteFile];
        if (exportType != nil && [helper getBackupTypePref:exportType].get)
        {
            [files addObject:remoteFile];
        }
    }
    _filteredFilesToDelete = files;
}

- (void) createFilteredFilesToMerge
{
    NSMutableArray<NSArray *> *files = [NSMutableArray array];
    NSMutableSet<OASettingsItem *> *items = [NSMutableSet set];
    OABackupHelper *helper = OABackupHelper.sharedInstance;
    for (NSArray *pair in _filesToMerge)
    {
        OASettingsItem *item = ((OALocalFile *) pair.firstObject).item;
        if (![items containsObject:item])
        {
            OAExportSettingsType *exportType = [OAExportSettingsType getExportSettingsTypeForRemoteFile:pair.lastObject];
            if (exportType != nil && [helper getBackupTypePref:exportType].get)
            {
                [files addObject:pair];
                [items addObject:item];
            }
        }
    }
    _filteredFilesToMerge = files;
}

- (NSString *) toString
{
    return [NSString stringWithFormat:@"BackupInfo { filesToDownload=%ld, filesToUpload=%ld, filesToDelete=%ld, localFilesToDelete=%ld, filesToMerge=%ld }", _filesToDownload.count, _filesToUpload.count, _filesToDelete.count, _localFilesToDelete.count, _filesToMerge.count];
}

@end
