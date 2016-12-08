//
//  OAFirebaseHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/11/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAFirebaseHelper.h"
#import "Firebase.h"

@implementation OAFirebaseHelper

+ (void)logEvent:(nonnull NSString *)name
{
#if !defined(OSMAND_IOS_DEV)
    [FIRAnalytics logEventWithName:name parameters:nil];
#endif // defined(OSMAND_IOS_DEV)
}

+ (void)setUserProperty:(nullable NSString *)value forName:(nonnull NSString *)name
{
#if !defined(OSMAND_IOS_DEV)
    [FIRAnalytics setUserPropertyString:value forName:name];
#endif // defined(OSMAND_IOS_DEV)
}

@end
