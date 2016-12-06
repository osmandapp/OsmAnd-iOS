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
    //[FIRAnalytics logEventWithName:name parameters:nil];
}

+ (void)setUserProperty:(nullable NSString *)value forName:(nonnull NSString *)name
{
    //[FIRAnalytics setUserPropertyString:value forName:name];
}

@end
