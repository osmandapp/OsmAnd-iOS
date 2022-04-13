//
//  OANetworkSettingsHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OANetworkSettingsHelper.h"
#import "OABackupHelper.h"

@implementation OANetworkSettingsHelper
{
    OABackupHelper *_backupHelper;
//    NSMutableDictionary<NSString *, OAImportBackupTask *> *_importAsyncTasks;
//    NSMutableDictionary<NSString *, OAExportBackupTask *> *_exportAsyncTasks;
}

//+ (OANetworkSettingsHelper *) sharedInstance
//{
//    static OANetworkSettingsHelper *_sharedInstance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _sharedInstance = [[OANetworkSettingsHelper alloc] init];
//    });
//    return _sharedInstance;
//}
//
//- (instancetype) init
//{
//    self = [super init];
//    if (self) {
//        _backupHelper = [OABackupHelper sharedInstance];
//        _importAsyncTasks = [NSMutableDictionary dictionary];
//        _exportAsyncTasks = [NSMutableDictionary dictionary];
//    }
//    return self;
//}
//
//- (OAImportBackupTask *)getImportTask:(NSString *)key
//{
//    return _importAsyncTasks[key];
//}

@end
