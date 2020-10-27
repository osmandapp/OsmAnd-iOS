//
//  OAMeasurementCommandManager.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

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
