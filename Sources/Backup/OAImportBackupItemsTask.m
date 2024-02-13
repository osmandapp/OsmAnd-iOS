//
//  OAImportBackupItemsTask.m
//  OsmAnd Maps
//
//  Created by Paul on 22.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAImportBackupItemsTask.h"
#import "OABackupImporter.h"
#import "OABackupHelper.h"
#import "OAPrepareBackupResult.h"
#import "OASettingsItem.h"

@implementation OAImportBackupItemsTask
{
    OABackupImporter *_importer;
    __weak id<OAImportItemsListener> _listener;
    NSArray<OASettingsItem *> *_items;
    EOARemoteFilesType _filesType;
    BOOL _foreceReadData;
    BOOL _restoreDeleted;
}

- (instancetype) initWithImporter:(OABackupImporter *)importer
                            items:(NSArray<OASettingsItem *> *)items
                        filesType:(EOARemoteFilesType)filesType
                         listener:(id<OAImportItemsListener>)listener
                    forceReadData:(BOOL)forceReadData
                   restoreDeleted:(BOOL)restoreDeleted
{
    self = [super init];
    if (self) {
        _importer = importer;
        _items = items;
        _filesType = filesType;
        _listener = listener;
        _foreceReadData = forceReadData;
        _restoreDeleted = restoreDeleted;
    }
    return self;
}

- (void) main
{
    BOOL success = [self doInBackground];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute:success];
    });
}

- (BOOL) doInBackground
{
    @try {
        OAPrepareBackupResult *backup = [OABackupHelper sharedInstance].backup;
        NSArray<OARemoteFile *> *remoteFiles = [backup getRemoteFiles:_filesType].allValues;
        [_importer importItems:_items remoteFiles:remoteFiles forceReadData:_foreceReadData restoreDeleted:_restoreDeleted];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"Failed to import items from backup");
    }
    return NO;
}

- (void) onPostExecute:(BOOL)success
{
    if (_listener)
        [_listener onImportFinished:success];
}


@end
