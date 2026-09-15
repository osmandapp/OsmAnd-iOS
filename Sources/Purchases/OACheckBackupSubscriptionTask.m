//
//  OACheckBackupSubscriptionTask.m
//  OsmAnd Maps
//
//  Created by Paul on 09.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACheckBackupSubscriptionTask.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"

@implementation OACheckBackupSubscriptionTask
{
    __weak OAIAPHelper *_iapHelper;
    OAAppSettings *_settings;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _iapHelper = OAIAPHelper.sharedInstance;
        _settings = OAAppSettings.sharedManager;
    }
    return self;
}

- (void) execute:(void(^)(BOOL))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber *active = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:active onComplete:onComplete];
        });
    });
}

/** @return nil when the state could not be verified - a request that did not reach the
    server must not be stored as "there is no subscription". */
- (NSNumber *) doInBackground
{
    BOOL anyActive = NO;
    BOOL anyUnverified = NO;

    NSString *promocode = [_settings.backupPromocode get];
    if (promocode.length > 0)
    {
        NSNumber *activeByPromocode = [self checkBackupSubscription:promocode];
        if (activeByPromocode == nil)
            anyUnverified = YES;
        else
            anyActive = activeByPromocode.boolValue;
    }
    if (!anyActive)
    {
        // Get only PRO subscriptions
        BOOL answered = NO;
        NSString *orderId = [_iapHelper getOrderIdByDeviceIdAndTokenAnswered:&answered];
        if (!answered)
        {
            // Either the request failed or the device is not registered
            anyUnverified = YES;
        }
        else if (orderId.length > 0)
        {
            NSNumber *activeByOrderId = [self checkBackupSubscription:orderId];
            if (activeByOrderId == nil)
                anyUnverified = YES;
            else
                anyActive = activeByOrderId.boolValue;
        }
    }
    if (anyActive)
        return @YES;
    // Report inactive only when every check that ran actually got an answer
    return anyUnverified ? nil : @NO;
}

- (NSNumber *) checkBackupSubscription:(NSString *)orderId
{
    BOOL answered = NO;
    NSArray *entry = [_iapHelper getSubscriptionStateByOrderId:orderId answered:&answered];
    if (!answered)
        return nil;

    if (entry)
    {
        OASubscriptionStateHolder *stateHolder = entry.lastObject;

        [_settings.backupPurchaseSku set:stateHolder.sku];
        [_settings.proSubscriptionOrigin set:(int) stateHolder.origin];
        [_settings.backupPurchaseState set:stateHolder.state];
        [_settings.backupPurchaseStartTime set:stateHolder.startTime];
        [_settings.backupPurchaseExpireTime set:stateHolder.expireTime];
        [_settings.proSubscriptionDuration set:(int)stateHolder.duration];
        return @(stateHolder.state.isActive);
    }
    return @NO;
}

- (void) onPostExecute:(NSNumber *)active onComplete:(void(^)(BOOL))onComplete
{
    if (active != nil)
    {
        // Leave both the stored state and the check time untouched when nothing was
        // verified, so that a failed check does not postpone the next attempt
        [_iapHelper onBackupPurchaseRequested];
        [_settings.backupPurchaseActive set:active.boolValue];
    }

    if (onComplete)
        onComplete(active.boolValue);
}

@end
