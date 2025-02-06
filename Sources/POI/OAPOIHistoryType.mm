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

- (OAColoredImage *)icon
{
    NSString *name = self.hType == OAHistoryTypeParking ? @"ic_parking_pin_small" : @"ic_map_pin_small";
    return [[OAColoredImage alloc] initWithName:name color:[UIColor colorNamed:ACColorNameIconColorSelected]];
}

@end
