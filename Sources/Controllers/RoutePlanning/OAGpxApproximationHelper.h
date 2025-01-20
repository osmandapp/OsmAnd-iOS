//
//  OAGpxApproximationHelper.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGpxApproximator.h"
#import "OALocationsHolder.h"
#import "OAApplicationMode.h"

@protocol OAGpxApproximationHelperDelegate <NSObject>

- (void)didStartProgress;
- (void)didApproximationStarted;
- (void)didUpdateProgress:(NSInteger)progress;
- (void)didFinishProgress;
- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points;

@end

@interface OAGpxApproximationHelper : NSObject

@property (nonatomic, weak) id<OAGpxApproximationHelperDelegate> delegate;

- (instancetype)initWithLocations:(NSArray<OALocationsHolder *> *)locations initialAppMode:(OAApplicationMode *)appMode initialThreshold:(float)threshold;

- (BOOL)calculateGpxApproximation:(BOOL)newCalculation;
- (OASGpxFile *)approximateGpxSync:(OASGpxFile *)gpxFile params:(OAGpxApproximator *)params;
- (void)updateAppMode:(OAApplicationMode *)appMode;
- (void)updateDistanceThreshold:(float)threshold;

@end
