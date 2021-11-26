//
//  OAOpenPlaceReviews.m
//  OsmAnd Maps
//
//  Created by nnngrach on 28.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAOpenPlaceReviews.h"
#import "OAProducts.h"

#define PLUGIN_ID kInAppId_Addon_OpenPlaceReview

@implementation OAOpenPlaceReviews

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (BOOL)isEnableByDefault
{
    return YES;
}

@end
