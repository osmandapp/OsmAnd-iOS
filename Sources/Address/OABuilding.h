//
//  OABuilding.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddress.h"

#include <OsmAndCore/Data/Building.h>

@class OAStreet, OACity;

@interface OABuilding : OAAddress

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::Building> building;

@property (nonatomic, readonly) OAStreet *street;
@property (nonatomic, readonly) OACity *city;

@property (nonatomic, readonly) NSString *postcode;

- (instancetype)initWithBuilding:(const std::shared_ptr<const OsmAnd::Building>&)building;

@end
