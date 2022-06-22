//
//  OAImportBackupItemsTask.m
//  OsmAnd Maps
//
//  Created by Paul on 22.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAImportBackupItemsTask.h"
#import "OABackupImporter.h"
#import "OASettingsItem.h"

@implementation OAImportBackupItemsTask
{
    OABackupImporter *_importer;
    __weak id<OAImportItemsListener> _listener;
    NSArray<OASettingsItem *> *_items;
    BOOL _foreceReadData;
}

- (instancetype) initWithImporter:(OABackupImporter *)importer items:(NSArray<OASettingsItem *> *)items listener:(id<OAImportItemsListener>)listener forceReadData:(BOOL)forceReadData
{
    self = [super init];
    if (self) {
        _importer = importer;
        _items = items;
        _listener = listener;
        _foreceReadData = forceReadData;
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
        [_importer importItems:_items forceReadData:_foreceReadData];
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
