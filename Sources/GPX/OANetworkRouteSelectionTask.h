//
//  OANetworkRouteSelectionTask.h
//  OsmAnd Maps
//
//  Created by Paul on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASGpxFile, OARouteKey;

@interface OANetworkRouteSelectionTask : NSObject

@property (nonatomic, assign) BOOL cancelled;

- (instancetype) initWithRouteKey:(OARouteKey *)key area:(NSArray *)area;

- (void) execute:(void(^)(OASGpxFile *gpxFile))onComplete;

@end

NS_ASSUME_NONNULL_END
