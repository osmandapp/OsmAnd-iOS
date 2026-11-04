//
//  OAGpxApproximationHelper.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode, OAGpxApproximationParams, OAGpxRouteApproximation, OALocationsHolder, OASGpxFile, OASWptPt;

@protocol OAGpxApproximationHelperDelegate <NSObject>

- (void)didStartProgress;
- (void)didApproximationStarted;
- (void)didUpdateProgress:(NSInteger)progress;
- (void)didFinishAllApproximationsWithResults:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points;

@end

@interface OAGpxApproximationHelper : NSObject

@property (nonatomic, weak) id<OAGpxApproximationHelperDelegate> delegate;

- (instancetype)initWithLocations:(NSArray<OALocationsHolder *> *)locations initialAppMode:(OAApplicationMode *)appMode initialThreshold:(float)threshold;

/// For a caller that starts from a gpx file rather than from locations: `approximateGpxSync:params:`
/// takes the points off the file itself. `OALocationsHolder` is a C++ header, so the initializer
/// above cannot be reached from Swift.
- (instancetype)initWithAppMode:(OAApplicationMode *)appMode threshold:(float)threshold;

- (void)calculateGpxApproximationAsync;
- (void)cancelApproximation;
- (OASGpxFile *)approximateGpxSync:(OASGpxFile *)gpxFile params:(OAGpxApproximationParams *)params;
- (void)updateAppMode:(OAApplicationMode *)appMode;
- (void)updateDistanceThreshold:(float)threshold;

@end
