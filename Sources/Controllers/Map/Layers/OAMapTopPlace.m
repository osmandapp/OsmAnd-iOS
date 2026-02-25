//
//  OAMapTopPlace.m
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 17.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapTopPlace.h"

@implementation OAMapTopPlace

- (instancetype)initWithPlaceId:(int32_t)placeId
                       position:(const OsmAnd::PointI &)position
                          image:(UIImage *)image
                  alreadyExists:(BOOL)alreadyExists {
    self = [super init];
    if (self) {
        _placeId = placeId;
        _position = position;
        _image = image;
        _alreadyExists = alreadyExists;
    }
    return self;
}

@end
