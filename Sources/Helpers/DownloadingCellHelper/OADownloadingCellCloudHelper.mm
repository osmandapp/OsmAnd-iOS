//
//  OADownloadingCellCloudHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 08/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellCloudHelper.h"
#import "OAResourcesUIHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OADownloadingCellCloudHelper

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupItemStarted:) name:kBackupItemStartedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupItemProgress:) name:kBackupItemProgressNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupProgressItemFinished:) name:kBackupItemFinishedNotification object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Resource methods

- (NSString *) getResourceId:(NSString *)typeName filename:(NSString *)filename
{
    return [typeName stringByAppendingString:filename];
}

#pragma mark - Downloading cell progress observer's methods

- (void)onBackupItemStarted:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *resourceId = [self getResourceId:info[@"type"] filename:info[@"name"]];
    if ([self helperHasItemFor:resourceId])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setCellProgress:resourceId progress:0. status:EOAItemStatusStartedType];
        });
    }
}

- (void)onBackupItemProgress:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *resourceId = [self getResourceId:info[@"type"] filename:info[@"name"]];
    if ([self helperHasItemFor:resourceId])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = [info[@"value"] floatValue] / 100;
            [self setCellProgress:resourceId progress:progress status:EOAItemStatusInProgressType];
        });
    }
}

- (void)onBackupProgressItemFinished:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *resourceId = [self getResourceId:info[@"type"] filename:info[@"name"]];
    if ([self helperHasItemFor:resourceId])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setCellProgress:resourceId progress:1. status:EOAItemStatusFinishedType];
            
            OADownloadingCell *cell = [self getOrCreateCell:resourceId];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        });
    }
}

@end
