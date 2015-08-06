//
//  OAHistoryItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryItem.h"

@implementation OAHistoryItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _hType = OAHistoryTypeUnknown;
    }
    return self;
}

-(UIImage *)icon
{
    return (self.hType == OAHistoryTypeParking ? [UIImage imageNamed:@"ic_parking_pin_small"] : [UIImage imageNamed:@"ic_map_pin_small"]);
}

@end
