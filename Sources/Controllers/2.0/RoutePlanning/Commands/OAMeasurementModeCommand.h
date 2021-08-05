//
//  OAMeasurementModeCommand.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/MeasurementModeCommand.java
// git revision 17fe5589712362fb66b10be2dd73f7b00cf381ec

#import <Foundation/Foundation.h>

@class OAMeasurementToolLayer, OAMeasurementEditingContext;

typedef NS_ENUM(NSInteger, EOAMeasurementCommandType)
{
    INVALID_TYPE = -1,
    ADD_POINT = 0,
    CLEAR_POINTS,
    MOVE_POINT,
    REMOVE_POINT,
    REORDER_POINT,
    SNAP_TO_ROAD,
    CHANGE_ROUTE_MODE,
    APPROXIMATE_POINTS,
    REVERSE_POINTS,
    SPLIT_POINTS,
    JOIN_POINTS
};

@protocol OACommand <NSObject>

- (BOOL) execute;
- (BOOL) update:(id<OACommand>)command;

- (void) undo;
- (void) redo;

@end

@interface OAMeasurementModeCommand : NSObject<OACommand>

@property (nonatomic) OAMeasurementToolLayer *measurementLayer;

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer;
- (void) setMeasurementLayer:(OAMeasurementToolLayer *)layer;
- (EOAMeasurementCommandType) getType;
- (OAMeasurementEditingContext *) getEditingCtx;
- (void) refreshMap;

@end
