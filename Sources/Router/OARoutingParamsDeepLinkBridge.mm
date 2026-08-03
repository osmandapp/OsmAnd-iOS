//
//  OARoutingParamsDeepLinkBridge.m
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 30.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OARoutingParamsDeepLinkBridge.h"
#import "OARoutingHelperUtils.h"

@implementation OARoutingParamsDeepLinkBridge

+ (NSString *)routingParamsQueryValueForAppMode:(OAApplicationMode *)mode
{
    return [OARoutingHelperUtils routingParamsQueryValueForAppMode:mode];
}

+ (void)applyRoutingParamsQueryValue:(NSString *)params forAppMode:(OAApplicationMode *)mode
{
    [OARoutingHelperUtils applyRoutingParamsQueryValue:params forAppMode:mode];
}

@end
