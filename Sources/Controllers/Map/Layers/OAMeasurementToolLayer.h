//
//  OAMeasurementToolLayer.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

@class OAMeasurementEditingContext, OAGpxTrkPt;

@protocol OAMeasurementLayerDelegate <NSObject>

- (void) onMeasue:(double)distance bearing:(double)bearing;

@end

@interface OAMeasurementToolLayer : OASymbolMapLayer

@property (nonatomic) OAMeasurementEditingContext *editingCtx;
@property (nonatomic, weak) id<OAMeasurementLayerDelegate> delegate;

- (OAGpxTrkPt *) addCenterPoint:(BOOL)addPointBefore;

- (void) enterMovingPointMode;
- (void) exitMovingMode;

- (OAGpxTrkPt *) getMovedPointToApply;

@end

