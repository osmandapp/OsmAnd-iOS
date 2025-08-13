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
    NSMutableArray<id<OAOnSendCodeListener>> *_sendCodeListeners;
    NSMutableArray<id<OAOnCheckCodeListener>> *_checkCodeListeners;
    NSMutableArray<id<OAOnDeleteAccountListener>> *_deleteAccountListeners;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _deleteFilesListeners = [NSMutableArray array];
        _registerUserListeners = [NSMutableArray array];
        _registerDeviceListeners = [NSMutableArray array];
        _sendCodeListeners = [NSMutableArray array];
        _checkCodeListeners = [NSMutableArray array];
        _deleteAccountListeners = [NSMutableArray array];
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

- (NSArray<id<OAOnSendCodeListener>> *) getSendCodeListeners
{
    return _sendCodeListeners;
}

- (void) addSendCodeListener:(id<OAOnSendCodeListener>)listener
{
    [_sendCodeListeners addObject:listener];
}

- (void) removeSendCodeListener:(id<OAOnSendCodeListener>)listener
{
    [_sendCodeListeners removeObject:listener];
}

- (NSArray<id<OAOnCheckCodeListener>> *) getCheckCodeListeners
{
    return _checkCodeListeners;
}

- (void) addCheckCodeListener:(id<OAOnCheckCodeListener>)listener
{
    [_checkCodeListeners addObject:listener];
}

- (void) removeCheckCodeListener:(id<OAOnCheckCodeListener>)listener
{
    [_checkCodeListeners removeObject:listener];
}

- (NSArray<id<OAOnDeleteAccountListener>> *) getDeleteAccountListeners
{
    return _deleteAccountListeners;
}

- (void) addDeleteAccountListener:(id<OAOnDeleteAccountListener>)listener
{
    [_deleteAccountListeners addObject:listener];
}

- (void) removeDeleteAccountListener:(id<OAOnDeleteAccountListener>)listener
{
    [_deleteAccountListeners removeObject:listener];
}

@end
