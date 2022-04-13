//
//  OAImportBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAImportBackupTask.h"
#import "OANetworkSettingsHelper.h"

@implementation OAImportBackupTask
{
    OANetworkSettingsHelper *_helper;
    
    id<OAImportListener> _importListener;
    id<OABackupCollectListener> _collectListener;
//    id<OACheckDuplicatesListener> _duplicatesListener;
//    OABackupImporter *_importer;
//    
//    NSArray<OASettingsItem *> *_items;
//    NSArray<OASettingsItem *> *_selectedItems;
//    NSArray *_duplicates;
//    
//    NSArray<OARemoteFile *> *_remoteFiles;
//    
//    NSString *_key;
//    NSMutableDictionary<NSString *, OAItemProgressInfo *> *_itemsProgress;
//    EOAImportType _importType;
}

@end
