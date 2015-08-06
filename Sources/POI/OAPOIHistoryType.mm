//
//  OAPOIHistoryType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHistoryType.h"
#import "OAUtilities.h"

@implementation OAPOIHistoryType

- (UIImage *)icon
{
    return (self.hType == OAHistoryTypeParking ? [UIImage imageNamed:@"ic_parking_pin_small"] : [UIImage imageNamed:@"ic_map_pin_small"]);
}

@end
