//
//  OAMeasurementModeCommand.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"

@implementation OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer
{
    self = [super init];
    if (self) {
        _measurementLayer = measurementLayer;
    }
    return self;
}

-(BOOL) update:(id<OACommand>)command
{
    return NO;
}

- (BOOL)execute
{
    return NO;
}


- (void)redo
{
    return;
}


- (void)undo
{
    return;
}

- (EOAMeasurementCommandType)getType
{
    return INVALID_TYPE; // override
}

- (OAMeasurementEditingContext *) getEditingCtx
{
    return _measurementLayer.editingCtx;
}

- (void) refreshMap
{
    [_measurementLayer updateLayer];
}

@end
