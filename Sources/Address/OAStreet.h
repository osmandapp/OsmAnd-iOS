//
//  OAStreet.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddress.h"

#include <OsmAndCore/Data/Street.h>

@class OACity;

@interface OAStreet : OAAddress

@property (nonatomic, readonly) OACity *city;

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::Street> street;

- (instancetype)initWithStreet:(const std::shared_ptr<const OsmAnd::Street>&)street;

@end
