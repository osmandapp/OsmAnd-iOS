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
        BOOL active = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:active onComplete:onComplete];
        });
    });
}

- (BOOL) doInBackground
{
    BOOL promoActive = NO;
    NSString *promocode = [_settings.backupPromocode get];
    if (promocode.length > 0)
        promoActive = [self checkBackupSubscription:promocode];
    if (!promoActive)
    {
        NSString *orderId = [_iapHelper getOrderIdByDeviceIdAndToken];
        if (orderId.length > 0) {
            promoActive = [self checkBackupSubscription:orderId];
        }
        return promoActive;
    }
    return NO;
}

- (BOOL) checkBackupSubscription:(NSString *)orderId
{
    NSArray *entry = [_iapHelper getSubscriptionStateByOrderId:orderId];
    if (entry)
    {
        OASubscriptionStateHolder *stateHolder = entry.lastObject;
        [_settings.proSubscriptionOrigin set:(int) stateHolder.origin];
        if (stateHolder.origin != EOASubscriptionOriginUndefined && stateHolder.origin != EOASubscriptionOriginIOS)
        {
            [_settings.backupPurchaseState set:stateHolder.state];
            [_settings.backupPurchaseStartTime set:stateHolder.startTime];
            [_settings.backupPurchaseExpireTime set:stateHolder.expireTime];
            return stateHolder.state.isActive;
        }
    }
    return NO;
}

- (void) onPostExecute:(BOOL)active onComplete:(void(^)(BOOL))onComplete
{
    [_iapHelper onBackupPurchaseRequested];
    [_settings.backupPurchaseActive set:active];
    
    if (onComplete)
        onComplete(active);
}

@end
