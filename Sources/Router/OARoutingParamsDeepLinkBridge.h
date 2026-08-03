//
//  OARoutingParamsDeepLinkBridge.h
//  OsmAnd
//
//  Created by Vitaliy Sova on 30.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OARoutingParamsDeepLinkBridge : NSObject

+ (nullable NSString *)routingParamsQueryValueForAppMode:(OAApplicationMode *)mode;
+ (void)applyRoutingParamsQueryValue:(nullable NSString *)params forAppMode:(OAApplicationMode *)mode;

@end

NS_ASSUME_NONNULL_END
