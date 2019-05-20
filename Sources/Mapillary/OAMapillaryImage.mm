//
//  OAMapillaryImage.m
//  OsmAnd
//
//  Created by Alexey on 20/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryImage.h"

@implementation OAMapillaryImage

- (instancetype) initWithLatitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    if (self) {
        _latitude = latitude;
        _longitude = longitude;
    }
    return self;
}

@end
