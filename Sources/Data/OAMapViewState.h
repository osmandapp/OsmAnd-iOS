//
//  OAMapViewState.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"

@class OAApplicationMode;

@interface OAMapViewState : NSObject <NSCoding>

@property Point31 target31;
@property float zoom;
@property float azimuth;
@property float elevationAngle;
@property float defaultElevationAngle;

- (float)elevationAngle:(OAApplicationMode *)mode;
- (void)setElevationAngle:(float)elevationAngle mode:(OAApplicationMode *)mode;

@end
