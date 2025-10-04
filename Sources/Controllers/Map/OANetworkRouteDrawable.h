//
//  OANetworkRouteDrawable.h
//  OsmAnd Maps
//
//  Created by Paul on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OARouteKey, OAPOI;

@interface OANetworkRouteDrawable : NSObject

- (instancetype)initWithRouteKey:(OARouteKey *)routeKey;

- (nullable UIImage *) getIcon;
- (void)setTextSize:(float)textSize;

+ (UIImage *) getIconByAmenityShieldTags:(OAPOI *)amenity textSize:(float)textSize;

@end

NS_ASSUME_NONNULL_END
