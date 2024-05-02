//
//  OAGeoTiffCollectionEnvironment.m
//  OsmAnd Maps
//
//  Created by Skalii on 02.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAGeoTiffCollectionEnvironment.h"

@implementation OAGeoTiffCollectionEnvironment

- (instancetype) initWithGeoTiffCollection:(const std::shared_ptr<OsmAnd::IGeoTiffCollection>&)geoTiffCollection
{
    self = [super init];
    if (self)
    {
        _geoTiffCollection = geoTiffCollection;
    }
    return self;
}

@end
