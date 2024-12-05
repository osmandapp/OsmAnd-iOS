//
//  OAOperationLog.m
//  OsmAnd Maps
//
//  Created by Paul on 25.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOperationLog.h"
#import "OALog.h"

@implementation OAOperationLog
{
    NSString *_operationName;
    BOOL _debug;
    NSTimeInterval _logThreshold;
    
    NSTimeInterval _startTime;
    BOOL _startLogged;
}

- (instancetype) initWithOperationName:(NSString *)operationName
{
    self = [super init];
    if (self) {
        _operationName = operationName;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithOperationName:(NSString *)operationName debug:(BOOL)debug
{
    self = [super init];
    if (self) {
        _operationName = operationName;
        _debug = debug;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithOperationName:(NSString *)operationName debug:(BOOL)debug logThreshold:(NSTimeInterval)logThreshold
{
    self = [super init];
    if (self) {
        [self commonInit];
        _operationName = operationName;
        _debug = debug;
        _logThreshold = logThreshold;
    }
    return self;
}

- (void) commonInit
{
    _logThreshold = 0.1; // 100 ms by default
    _startTime = NSDate.date.timeIntervalSince1970;
}

- (void) startOperation
{
    [self startOperation:nil];
}

- (void) startOperation:(NSString *)message
{
    _startTime = NSDate.date.timeIntervalSince1970;
    [self logImpl:[NSString stringWithFormat:@"%@ BEGIN %@", _operationName, (message.length > 0 ? message : @"")] forceLog:_debug];
    _startLogged = _debug;
}

- (void) finishOperation
{
    [self finishOperation:nil];
}

- (void) finishOperation:(NSString *)message
{
    NSTimeInterval elapsedTime = NSDate.date.timeIntervalSince1970 - _startTime;
    if (_startLogged || _debug || elapsedTime > _logThreshold)
    {
        [self logImpl:[NSString stringWithFormat:@"%@ END (%f ms) %@", _operationName, (elapsedTime * 1000), message.length > 0 ? message : @""] forceLog:YES];
    }
}

- (void) log:(NSString *)message
{
    [self log:message forceLog:NO];
}

- (void) log:(NSString *)message forceLog:(BOOL)forceLog
{
    if (_debug || forceLog)
    {
        OALog(@"%@", [NSString stringWithFormat:@"%@ %@", _operationName, message.length > 0 ? message : @""]);
    }
}

- (void) logImpl:(NSString *)message forceLog:(BOOL)forceLog
{
    if (_debug || forceLog)
        OALog(@"%@", message);
}

@end
