//
//  OADebugSettings.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/31/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugSettings.h"

@implementation OADebugSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        _useRawSpeedAndAltitudeOnHUD = NO;
    }
    return self;
}

@synthesize useRawSpeedAndAltitudeOnHUD = _useRawSpeedAndAltitudeOnHUD;

@end
