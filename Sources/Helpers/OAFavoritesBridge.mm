//
//  OAFavoritesBridge.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAFavoritesBridge.h"
#import "OAFavoritesHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAFavoriteItem.h"
#import "OAMapLayers.h"

@implementation OAFavoritesBridge

+ (BOOL)openFavouriteOrMoveMapWithLat:(double)lat lon:(double)lon zoom:(int)zoom name:(NSString *)name
{
    OAFavoriteItem *point = [OAFavoritesHelper getVisibleFavByLat:lat lon:lon];
    if (point && [name isEqualToString:[point getName]])
    {
        OATargetPoint *targetPoint = [[OARootViewController instance].mapPanel.mapViewController.mapLayers.favoritesLayer getTargetPoint:point];
        targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
        [targetPoint initAdderssIfNeeded];
        targetPoint.centerMap = YES;
        [[OARootViewController instance].mapPanel showContextMenu:targetPoint saveState:NO preferredZoom:zoom];
    }
    else
    {
        [[OARootViewController instance].mapPanel moveMapToLat:lat lon:lon zoom:zoom withTitle:name];
    }
    
    return YES;
}

@end
