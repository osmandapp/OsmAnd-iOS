//
//  OAMeasurementToolLayer.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

@class OAMeasurementEditingContext, OASWptPt;

@protocol OAMeasurementLayerDelegate <NSObject>

- (void) onMeasure:(double)distance bearing:(double)bearing;

- (void) onTouch:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress;

@end

@interface OAMeasurementToolLayer : OASymbolMapLayer

@property (nonatomic) OAMeasurementEditingContext *editingCtx;
@property (nonatomic, weak) id<OAMeasurementLayerDelegate> delegate;

@property (nonatomic) CLLocation *pressPointLocation;

- (OASWptPt *) addCenterPoint:(BOOL)addPointBefore;
- (OASWptPt *) addPoint:(BOOL)addPointBefore;

- (void) enterMovingPointMode;
- (void) exitMovingMode;

- (OASWptPt *) getMovedPointToApply;

- (void) onMapPointSelected:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress;

- (void) moveMapToPoint:(NSInteger)pos;

@end

