//
//  OADestination.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestination.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OADestination


- (instancetype)initWithDesc:(NSString *)desc latitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    if (self) {
        self.desc = desc;
        self.latitude = latitude;
        self.longitude = longitude;
    }
    return self;
}

- (NSString *) distanceStr:(double)latitude longitude:(double)longitude
{
    const auto distance = OsmAnd::Utilities::distance(longitude,
                                                      latitude,
                                                      self.longitude, self.latitude);
    
    return [[OsmAndApp instance] getFormattedDistance:distance];
}


@end
