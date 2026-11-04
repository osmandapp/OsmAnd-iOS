//
//  OAGpxRouteApproximation.h
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASGpxPoint, OASGpxRouteApproximation, OASRouteSegmentResult;

/** A track attached to the roads underneath it, as the rest of the app reads the result. */
@interface OAGpxRouteApproximation : NSObject

/** The track points the approximation kept, each with the roads that lead to the next one. */
@property (nonatomic, readonly) NSArray<OASGpxPoint *> *finalPoints;

/** The roads of the whole approximated track, in order. */
@property (nonatomic, readonly) NSArray<OASRouteSegmentResult *> *fullRoute;

- (nullable instancetype) initWithApproximation:(nullable OASGpxRouteApproximation *)approximation;
- (instancetype) initWithFinalPoints:(NSArray<OASGpxPoint *> *)finalPoints
                          fullRoute:(NSArray<OASRouteSegmentResult *> *)fullRoute;

@end

NS_ASSUME_NONNULL_END
