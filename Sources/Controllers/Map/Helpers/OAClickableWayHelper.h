//
//  OAClickableWayHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ClickableWay, OARenderedObject, OAClickableWayMenuProvider, OAPOI;

@interface OAClickableWayHelper : NSObject

- (OAClickableWayMenuProvider *)getContextMenuProvider;

- (BOOL)isClickableWayTags:(NSString *)name tags:(NSDictionary<NSString *, NSString *> *)tags;

- (ClickableWay *)loadClickableWay:(OAPOI *)amenity;

@end

NS_ASSUME_NONNULL_END
