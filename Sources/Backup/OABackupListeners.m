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
    @synchronized (self) {
        return [_deleteFilesListeners copy];
    }
}

- (void) addDeleteFilesListener:(id<OAOnDeleteFilesListener>)listener
{
    @synchronized (self) {
        [_deleteFilesListeners addObject:listener];
    }
}

- (void) removeDeleteFilesListener:(id<OAOnDeleteFilesListener>)listener
{
    @synchronized (self) {
        [_deleteFilesListeners removeObject:listener];
    }
}

- (NSArray<id<OAOnRegisterUserListener>> *) getRegisterUserListeners
{
    @synchronized (self) {
        return [_registerUserListeners copy];
    }
}

- (void) addRegisterUserListener:(id<OAOnRegisterUserListener>)listener
{
    @synchronized (self) {
        [_registerUserListeners addObject:listener];
    }
}

- (void) removeRegisterUserListener:(id<OAOnRegisterUserListener>)listener
{
    @synchronized (self) {
        [_registerUserListeners removeObject:listener];
    }
}

- (NSArray<id<OAOnRegisterDeviceListener>> *) getRegisterDeviceListeners
{
    @synchronized (self) {
        return [_registerDeviceListeners copy];
    }
}

- (void) addRegisterDeviceListener:(id<OAOnRegisterDeviceListener>)listener
{
    @synchronized (self) {
        [_registerDeviceListeners addObject:listener];
    }
}

- (void) removeRegisterDeviceListener:(id<OAOnRegisterDeviceListener>)listener
{
    @synchronized (self) {
        [_registerDeviceListeners removeObject:listener];
    }
}

- (NSArray<id<OAOnSendCodeListener>> *) getSendCodeListeners
{
    @synchronized (self) {
        return [_sendCodeListeners copy];
    }
}

- (void) addSendCodeListener:(id<OAOnSendCodeListener>)listener
{
    @synchronized (self) {
        [_sendCodeListeners addObject:listener];
    }
}

- (void) removeSendCodeListener:(id<OAOnSendCodeListener>)listener
{
    @synchronized (self) {
        [_sendCodeListeners removeObject:listener];
    }
}

- (NSArray<id<OAOnCheckCodeListener>> *) getCheckCodeListeners
{
    @synchronized (self) {
        return [_checkCodeListeners copy];
    }
}

- (void) addCheckCodeListener:(id<OAOnCheckCodeListener>)listener
{
    @synchronized (self) {
        [_checkCodeListeners addObject:listener];
    }
}

- (void) removeCheckCodeListener:(id<OAOnCheckCodeListener>)listener
{
    @synchronized (self) {
        [_checkCodeListeners removeObject:listener];
    }
}

- (NSArray<id<OAOnDeleteAccountListener>> *) getDeleteAccountListeners
{
    @synchronized (self) {
        return [_deleteAccountListeners copy];
    }
}

- (void) addDeleteAccountListener:(id<OAOnDeleteAccountListener>)listener
{
    @synchronized (self) {
        [_deleteAccountListeners addObject:listener];
    }
}

- (void) removeDeleteAccountListener:(id<OAOnDeleteAccountListener>)listener
{
    @synchronized (self) {
        [_deleteAccountListeners removeObject:listener];
    }
}

@end
