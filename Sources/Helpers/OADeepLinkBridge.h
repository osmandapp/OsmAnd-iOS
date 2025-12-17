//
//  OADeepLinkBridge.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARootViewController, OATargetPoint;

@interface OADeepLinkBridge : NSObject

+ (BOOL)openFavouriteOrMoveMapWithLat:(double)lat lon:(double)lon zoom:(int)zoom name:(nullable NSString *)name;
+ (void)moveMapToLat:(double)lat lon:(double)lon zoom:(int)zoom title:(nullable NSString *)title rootViewController:(nullable OARootViewController *)rootViewController;
+ (nullable OATargetPoint *)unknownTargetPointWithLat:(double)lat lon:(double)lon rootViewController:(nullable OARootViewController *)rootViewController;

@end
