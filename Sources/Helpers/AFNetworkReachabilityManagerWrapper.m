//
//  AFNetworkReachabilityManagerWrapper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 19/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "AFNetworkReachabilityManagerWrapper.h"
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

@implementation AFNetworkReachabilityManagerWrapper

+ (BOOL) isReachable
{
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

+ (BOOL) isReachableViaWWAN
{
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN];
}

+ (BOOL) isReachableViaWiFi
{
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
}

@end
