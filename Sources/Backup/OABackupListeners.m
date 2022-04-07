//
//  OABackupListeners.m
//  OsmAnd Maps
//
//  Created by Paul on 24.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupListeners.h"

@implementation OABackupListeners
{
    NSMutableArray<id<OAOnDeleteFilesListener>> *_deleteFilesListeners;
    NSMutableArray<id<OAOnRegisterUserListener>> *_registerUserListeners;
    NSMutableArray<id<OAOnRegisterDeviceListener>> *_registerDeviceListeners;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _deleteFilesListeners = [NSMutableArray array];
        _registerUserListeners = [NSMutableArray array];
        _registerDeviceListeners = [NSMutableArray array];
    }
    return self;
}

- (NSArray<id<OAOnDeleteFilesListener>> *) getDeleteFilesListeners
{
    return _deleteFilesListeners;
}

- (void) addDeleteFilesListener:(id<OAOnDeleteFilesListener>)listener
{
    [_deleteFilesListeners addObject:listener];
}

- (void) removeDeleteFilesListener:(id<OAOnDeleteFilesListener>)listener
{
    [_deleteFilesListeners removeObject:listener];
}

- (NSArray<id<OAOnRegisterUserListener>> *) getRegisterUserListeners
{
    return _registerUserListeners;
}

- (void) addRegisterUserListener:(id<OAOnRegisterUserListener>)listener
{
    [_registerUserListeners addObject:listener];
}

- (void) removeRegisterUserListener:(id<OAOnRegisterUserListener>)listener
{
    [_registerUserListeners removeObject:listener];
}

- (NSArray<id<OAOnRegisterDeviceListener>> *) getRegisterDeviceListeners
{
    return _registerDeviceListeners;
}

- (void) addRegisterDeviceListener:(id<OAOnRegisterDeviceListener>)listener
{
    [_registerDeviceListeners addObject:listener];
}

- (void) removeRegisterDeviceListener:(id<OAOnRegisterDeviceListener>)listener
{
    [_registerDeviceListeners removeObject:listener];
}

@end
