//
//  OADeepLinkBridge.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OADeepLinkBridge.h"
#import "OAFavoritesHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAFavoriteItem.h"
#import "OAMapLayers.h"
#import "OANativeUtilities.h"

@implementation OADeepLinkBridge

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

+ (void)moveMapToLat:(double)lat lon:(double)lon zoom:(int)zoom title:(NSString *)title rootViewController:(OARootViewController *)rootViewController
{
    Point31 pos31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon))];
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapVC = [rootViewController.mapPanel mapViewController];
        if (!mapVC || !mapVC.mapViewLoaded)
        {
            OAMapViewState *state = [[OAMapViewState alloc] init];
            state.target31 = pos31;
            state.zoom = zoom;
            state.azimuth = 0.0f;
            [OsmAndApp instance].initialURLMapState = state;
            return;
        }
        
        [rootViewController.mapPanel moveMapToLat:lat lon:lon zoom:zoom withTitle:title];
    });
}

+ (OATargetPoint *)unknownTargetPointWithLat:(double)lat lon:(double)lon rootViewController:(OARootViewController *)rootViewController
{
    OAMapViewController *mapViewController = [rootViewController.mapPanel mapViewController];
    return [mapViewController.mapLayers.contextMenuLayer getUnknownTargetPoint:lat longitude:lon];
}

@end
