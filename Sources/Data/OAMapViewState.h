//
//  OAMapViewState.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"

@interface OAMapViewState : NSObject <NSCoding>

@property Point31 target31;
@property float zoom;
@property float azimuth;
@property float elevationAngle;

@end
