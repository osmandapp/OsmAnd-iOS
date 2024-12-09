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
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

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
    [self createFilteredFilesToDownload];
    [self createFilteredFilesToUpload];
    [self createItemsToUpload];
    [self createFilteredFilesToDelete];
    [self createItemsToDelete];
    [self createFilteredFilesToMerge];
    [self createFilteredLocalFilesToDelete];
    [self createLocalItemsToDelete];
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
    _itemsToUpload = [self getSortedItems:items];
}

- (void) createItemsToDelete
{
    NSMutableSet<OASettingsItem *> *items = [NSMutableSet set];
    for (OARemoteFile *remoteFile in _filteredFilesToDelete) {
        OASettingsItem *item = remoteFile.item;
        if (item)
            [items addObject:item];
    }
    _itemsToDelete = [self getSortedItems:items];
}

- (void) createLocalItemsToDelete
{
    NSMutableSet<OASettingsItem *> *items = [NSMutableSet set];
    for (OARemoteFile *remoteFile in _filteredLocalFilesToDelete) {
        OASettingsItem *item = remoteFile.item;
        if (item)
            [items addObject:item];
    }
    _localItemsToDelete = [self getSortedItems:items];
}

- (NSMutableArray<OASettingsItem *> *)getSortedItems:(NSSet<OASettingsItem *> *)settingsItems
{
    NSMutableArray<OASettingsItem *> *items = [NSMutableArray arrayWithArray:settingsItems.allObjects];
    [items sortUsingComparator:^NSComparisonResult(OASettingsItem * _Nonnull o1, OASettingsItem * _Nonnull o2) {
        return [@(o2.lastModifiedTime) compare:@(o1.lastModifiedTime)];
    }];
    return items;
}

- (void) createFilteredFilesToDownload
{
    NSMutableArray<OARemoteFile *> *files = [NSMutableArray array];
    for (OARemoteFile *remoteFile in _filesToDownload)
    {
        OAExportSettingsType *type = [OAExportSettingsType findByRemoteFile:remoteFile];
        if (type != nil && [[BackupUtils getBackupTypePref:type] get])
        {
            [files addObject:remoteFile];
        }
    }
    _filteredFilesToDownload = files;
}

- (void) createFilteredFilesToUpload
{
    NSMutableArray<OALocalFile *> *files = [NSMutableArray array];
    for (OALocalFile *localFile in _filesToUpload)
    {
        OAExportSettingsType *type = [OAExportSettingsType findBySettingsItem:localFile.item];
        if (type != nil && [[BackupUtils getBackupTypePref:type] get] && (type.isAllowedInFreeVersion || [OAIAPHelper isOsmAndProAvailable]))
            [files addObject:localFile];
    }
    _filteredFilesToUpload = files;
}

- (void) createFilteredFilesToDelete
{
    NSMutableArray<OARemoteFile *> *files = [NSMutableArray array];
    for (OARemoteFile *remoteFile in _filesToDelete)
    {
        OAExportSettingsType *exportType = [OAExportSettingsType findByRemoteFile:remoteFile];
        if (exportType != nil && [[BackupUtils getBackupTypePref:exportType] get])
            [files addObject:remoteFile];
    }
    _filteredFilesToDelete = files;
}

- (void) createFilteredLocalFilesToDelete
{
    NSMutableArray<OALocalFile *> *files = [NSMutableArray array];
    for (OALocalFile *localFile in _localFilesToDelete)
    {
        OAExportSettingsType *exportType = [OAExportSettingsType findBySettingsItem:localFile.item];
        if (exportType != nil && [[BackupUtils getBackupTypePref:exportType] get])
            [files addObject:localFile];
    }
    _filteredLocalFilesToDelete = files;
}

- (void) createFilteredFilesToMerge
{
    NSMutableArray<NSArray *> *files = [NSMutableArray array];
    NSMutableSet<OASettingsItem *> *items = [NSMutableSet set];
    for (NSArray *pair in _filesToMerge)
    {
        OASettingsItem *item = ((OALocalFile *) pair.firstObject).item;
        if (![items containsObject:item])
        {
            OAExportSettingsType *exportType = [OAExportSettingsType findByRemoteFile:pair.lastObject];
            if (exportType != nil && [[BackupUtils getBackupTypePref:exportType] get])
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
