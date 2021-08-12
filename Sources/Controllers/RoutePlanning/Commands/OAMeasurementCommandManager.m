//
//  OAMeasurementCommandManager.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementCommandManager.h"
#import "OAMeasurementModeCommand.h"

@implementation OAMeasurementCommandManager
{
    NSMutableArray<OAMeasurementModeCommand *> *_undoCommands;
    NSMutableArray<OAMeasurementModeCommand *> *_redoCommands;
    
    NSInteger _changesCounter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _undoCommands = [NSMutableArray new];
        _redoCommands = [NSMutableArray new];
        _changesCounter = 0;
    }
    return self;
}

- (BOOL) hasChanges
{
    return _changesCounter != 0;
}

- (void) resetChangesCounter
{
    _changesCounter = 0;
}

- (BOOL) canUndo
{
    return _undoCommands.count > 0;
}

- (BOOL) canRedo
{
    return _redoCommands.count > 0;
}

- (BOOL) execute:(OAMeasurementModeCommand *)command
{
    if ([command execute])
    {
        [_undoCommands addObject:command];
        [_redoCommands removeAllObjects];
        _changesCounter++;
        return YES;
    }
    return NO;
}

- (BOOL) update:(OAMeasurementModeCommand *)command
{
    OAMeasurementModeCommand *prevCommand = _undoCommands.lastObject;
    return prevCommand != nil && [prevCommand update:command];
}

- (EOAMeasurementCommandType) undo
{
    if ([self canUndo])
    {
        OAMeasurementModeCommand *command = _undoCommands.lastObject;
        [_undoCommands removeLastObject];
        [_redoCommands addObject:command];
        [command undo];
        _changesCounter--;
        return [command getType];
    }
    return INVALID_TYPE;
}

- (EOAMeasurementCommandType) redo
{
    if ([self canRedo])
    {
        OAMeasurementModeCommand *command = _redoCommands.lastObject;
        [_redoCommands removeLastObject];
        [_undoCommands addObject:command];
        [command redo];
        _changesCounter++;
        return [command getType];
    }
    return INVALID_TYPE;
}

- (void) setMeasurementLayer:(OAMeasurementToolLayer *)layer
{
    for (OAMeasurementModeCommand *command in _undoCommands)
          [command setMeasurementLayer:layer];
    for (OAMeasurementModeCommand *command in _redoCommands)
        [command setMeasurementLayer:layer];
}

- (OAMeasurementModeCommand *) getLastCommand
{
    return _undoCommands.lastObject;
}

@end
