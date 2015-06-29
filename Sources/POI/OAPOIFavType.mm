//
//  OAPOIFavType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIFavType.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>

@implementation OAPOIFavType

- (UIImage *)icon
{
    const auto allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();
    
    // create favorite groups
    for(const auto& favorite : allFavorites)
    {
        OsmAnd::LatLon latLon = favorite->getLatLon();
        if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:self.parent.longitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:self.parent.latitude])
        {
            UIColor* color = [UIColor colorWithRed:favorite->getColor().r/255.0 green:favorite->getColor().g/255.0 blue:favorite->getColor().b/255.0 alpha:1.0];
            
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];

            return favCol.icon;
        }
    }
    
    return nil;
}

@end
