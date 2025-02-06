//
//  OAPOIMyLocationType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIMyLocationType.h"
#import "GeneratedAssetSymbols.h"

@implementation OAPOIMyLocationType

- (OAColoredImage *)icon
{
    return [[OAColoredImage alloc] initWithName:@"ic_action_location_color.png" color:[UIColor colorNamed:ACColorNameIconColorSelected]];
}

@end
