//
//  OANetworkRouteDrawable.h
//  OsmAnd Maps
//
//  Created by Paul on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OARouteKey;

@interface OANetworkRouteDrawable : NSObject

- (instancetype)initWithRouteKey:(OARouteKey *)routeKey;

- (UIImage *) getIcon;

@end

NS_ASSUME_NONNULL_END
