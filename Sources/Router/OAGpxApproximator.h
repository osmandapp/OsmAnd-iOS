//
//  OAGpxApproximator.h
//  OsmAnd Maps
//
//  Created by Paul on 12.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAResultMatcher.h"

NS_ASSUME_NONNULL_BEGIN

@class OAGpxRouteApproximation, OALocationsHolder;

@class OAApplicationMode, OAGpxApproximator, OALocationsHolder;

@protocol OAGpxApproximationProgressDelegate

- (void) start:(OAGpxApproximator *)approximator;
- (void) updateProgress:(OAGpxApproximator *)approximator progress:(NSInteger)progress;
- (void) finish:(OAGpxApproximator *)approximator;

@end

@interface OAGpxApproximator : NSObject

@property (nonatomic) OAApplicationMode *mode;
@property (nonatomic, assign) double pointApproximation;
@property (nonatomic, readonly) OALocationsHolder *locationsHolder;

@property (nonatomic, weak) id<OAGpxApproximationProgressDelegate> progressDelegate;

- (instancetype) initWithLocationsHolder:(OALocationsHolder *)locationsHolder;
- (instancetype) initWithApplicationMode:(OAApplicationMode *)mode pointApproximation:(double)pointApproximation locationsHolder:(OALocationsHolder *)locationsHolder;

- (void) calculateGpxApproximation:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

- (BOOL) isCancelled;
- (void) cancelApproximation;

@end

NS_ASSUME_NONNULL_END
