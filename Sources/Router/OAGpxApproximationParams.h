//
//  OAGpxApproximationParams.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode, OALocationsHolder, OASWptPt;

@interface OAGpxApproximationParams : NSObject

@property (nonatomic, strong) OAApplicationMode *appMode;
@property (nonatomic, assign) int distanceThreshold;
@property (nonatomic, strong) NSMutableArray<OALocationsHolder *> *locationsHolders;

- (void)setTrackPoints:(NSArray<NSArray<OASWptPt *> *> *)points;
- (void)setAppMode:(OAApplicationMode *)newAppMode;
- (void)setDistanceThreshold:(int)newThreshold;
- (OAApplicationMode *)getAppMode;
- (int)getDistanceThreshold;
- (NSArray<OALocationsHolder *> *)getLocationsHolders;

@end
