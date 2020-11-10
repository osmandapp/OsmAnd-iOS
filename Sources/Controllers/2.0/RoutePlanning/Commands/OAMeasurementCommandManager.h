//
//  OAMeasurementCommandManager.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/MeasurementCommandManager.java
// git revision b1d714a62c513b96bdc616ec5531cff8231c6f43

#import <Foundation/Foundation.h>
#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OAMeasurementCommandManager : NSObject

- (BOOL) hasChanges;
- (void) resetChangesCounter;

- (BOOL) canUndo;
- (BOOL) canRedo;
- (BOOL) execute:(OAMeasurementModeCommand *)command;
- (BOOL) update:(OAMeasurementModeCommand *)command;

- (EOAMeasurementCommandType) undo;
- (EOAMeasurementCommandType) redo;

- (void) setMeasurementLayer:(OAMeasurementToolLayer *)layer;
- (OAMeasurementModeCommand *) getLastCommand;


@end
