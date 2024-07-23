//
//  AFNetworkReachabilityManagerWrapper.h
//  OsmAnd
//
//  Created by Max Kojin on 19/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFNetworkReachabilityManagerWrapper : NSObject

+ (BOOL) isReachable;
+ (BOOL) isReachableViaWWAN;
+ (BOOL) isReachableViaWiFi;

@end
