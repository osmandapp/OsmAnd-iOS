//
//  OAApplyGpxApproximationCommand.h
//  OsmAnd Maps
//
//  Created by Paul on 17.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

NS_ASSUME_NONNULL_BEGIN

@class OAMeasurementToolLayer, OAGpxRouteApproximation, OAGpxTrkPt, OAApplicationMode;

@interface OAApplyGpxApproximationCommand : OAMeasurementModeCommand

@property (nonatomic, readonly) NSArray<NSArray<OAGpxTrkPt *> *> *originalSegmentPointsList;

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer approximations:(NSArray<OAGpxRouteApproximation *> *)approximations segmentPointsList:(NSArray<NSArray<OAGpxTrkPt *> *> *)segmentPointsList appMode:(OAApplicationMode *)appMode;

@end

NS_ASSUME_NONNULL_END
