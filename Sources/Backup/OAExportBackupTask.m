//
//  OAExportBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAExportBackupTask.h"
#import "OANetworkSettingsHelper.h"
#import "OAImportBackupTask.h"

#define APPROXIMATE_FILE_SIZE_BYTES (100 * 1024)

@implementation OAExportBackupTask
{
    OANetworkSettingsHelper *_helper;
//    OABackupExporter *_exporter;
    id<OABackupExportListener> _listener;
    
    NSString *key;
    NSMutableDictionary<NSString *, OAItemProgressInfo *> *_itemsProgress;
    NSInteger _generalProgress;
    NSInteger _maxProgress;
}

@end
