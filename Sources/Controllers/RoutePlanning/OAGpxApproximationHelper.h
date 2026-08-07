//
//  OAGpxApproximationHelper.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode, OAGpxApproximationParams, OAGpxApproximator, OAGpxRouteApproximation, OALocationsHolder, OASGpxFile, OASWptPt;

@protocol OAGpxApproximationHelperDelegate <NSObject>

- (void)didStartProgress;
- (void)didApproximationStarted;
- (void)didUpdateProgress:(NSInteger)progress;
- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points;

@end

@interface OAGpxApproximationHelper : NSObject

@property (nonatomic, weak) id<OAGpxApproximationHelperDelegate> delegate;

- (instancetype)initWithParams:(OAGpxApproximationParams *)params;

- (void)calculateGpxApproximationAsync;
- (OAGpxApproximator *)createApproximator:(OALocationsHolder *)holder;
- (void)setAppMode:(OAApplicationMode *)appMode recalculate:(BOOL)recalculate;
- (void)setDistanceThreshold:(int)threshold recalculate:(BOOL)recalculate;
- (OAApplicationMode *)getAppMode;
- (NSString *)getModeKey;
- (int)getDistanceThreshold;
- (BOOL)isSameApproximator:(OAGpxApproximator *)approximator;
- (BOOL)canApproximate;
- (void)cancelApproximationIfPossible;
- (OASGpxFile *)approximateGpxSync:(OASGpxFile *)gpxFile params:(OAGpxApproximationParams *)params;

@end
