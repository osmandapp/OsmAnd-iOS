//
//  OARouteKey.h
//  OsmAnd Maps
//
//  Created by Paul on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsmAndCore/NetworkRouteContext.h>

@interface OARouteKey : NSObject

@property (nonatomic, readonly) OsmAnd::NetworkRouteKey routeKey;

+ (OARouteKey *) fromGpx:(NSDictionary<NSString *, NSString *> *)gpx;
- (NSString *) getActivityTypeTitle;
- (NSString *) getLocalizedTitle;

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key;

@end
