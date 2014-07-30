//
//  OAHUDRegularButton.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAHUDRegularButton.h"

#import "OsmAndApp.h"

@implementation OAHUDRegularButton

- (UIImage*)backgroundImage
{
    return [[OsmAndApp instance].appearance hudButtonBackgroundForStyle:OAButtonStyleRegular];
}

@end
