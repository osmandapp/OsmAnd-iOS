//
//  OAPOIHistoryType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHistoryType.h"
#import "OAUtilities.h"
#import "GeneratedAssetSymbols.h"

@implementation OAPOIHistoryType

- (UIImage *)icon
{
    return (self.hType == OAHistoryTypeParking ? [UIImage imageNamed:ACImageNameIcParkingPinSmall] : [UIImage imageNamed:ACImageNameIcMapPinSmall]);
}

@end
