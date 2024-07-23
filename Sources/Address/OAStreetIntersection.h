//
//  OAStreetIntersection.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddress.h"

#include <OsmAndCore/Data/StreetIntersection.h>

@class OAStreet;

@interface OAStreetIntersection : OAAddress

@property (nonatomic, readonly) OAStreet *street;

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::StreetIntersection> streetIntersection;

- (instancetype)initWithStreetIntersection:(const std::shared_ptr<const OsmAnd::StreetIntersection>&)streetIntersection;

@end
