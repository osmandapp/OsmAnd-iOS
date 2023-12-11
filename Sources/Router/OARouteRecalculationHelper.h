//
//  OARouteRecalculationHelper.h
//  OsmAnd Maps
//
//  Created by Alexey K on 10.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OARoutingHelper, OARouteCalculationParams, OARouteCalculationResult, OARouteCalculationProgressCallback, OAGPXRouteParamsBuilder;
@protocol OARouteCalculationProgressCallback;

@interface OARouteRecalculationHelper : NSObject

@property (nonatomic, readonly) OARoutingHelper *routingHelper;

@property (nonatomic) NSTimeInterval lastTimeEvaluatedRoute;
@property (nonatomic) NSString *lastRouteCalcError;
@property (nonatomic) NSString *lastRouteCalcErrorShort;
@property (nonatomic) long recalculateCountInInterval;
@property (nonatomic) NSTimeInterval evalWaitInterval;

- (instancetype) initWithRoutingHelper:(OARoutingHelper *)helper;

- (BOOL) isRouteBeingCalculated;
- (void) resetEvalWaitInterval;
- (void) startRouteCalculationThread:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged updateProgress:(BOOL)updateProgress;
- (void) addCalculationProgressCallback:(id<OARouteCalculationProgressCallback>)callback;
- (void) recalculateRouteInBackground:(CLLocation *)start end:(CLLocation *)end intermediates:(NSArray<CLLocation *> *)intermediates gpxRoute:(OAGPXRouteParamsBuilder *)gpxRoute previousRoute:(OARouteCalculationResult *)previousRoute paramsChanged:(BOOL)paramsChanged onlyStartPointChanged:(BOOL)onlyStartPointChanged;
- (void) stopCalculation;
- (void) stopCalculationIfParamsNotChanged;

@end

NS_ASSUME_NONNULL_END
