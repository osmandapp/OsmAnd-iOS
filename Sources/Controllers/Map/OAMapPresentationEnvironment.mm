//
//  OAMapPresentationEnvironment.m
//  OsmAnd Maps
//
//  Created by Paul on 15.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAMapPresentationEnvironment.h"

@implementation OAMapPresentationEnvironment

- (instancetype) initWithEnvironment:(const std::shared_ptr<OsmAnd::MapPresentationEnvironment> &)env
{
    self = [super init];
    if (self) {
        _mapPresentationEnvironment = env;
    }
    return self;
}

@end
