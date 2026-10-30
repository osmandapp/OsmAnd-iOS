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
#import "OAManageResourcesViewController.h"
#import "OAOutdatedResourcesViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OARendererRegistry.h"
#import "OAIndexConstants.h"
#import "OAMapSource.h"

#include <OsmAndCore/Map/UnresolvedMapStyle.h>

static NSString * const kResourcesStoryboardName = @"Resources";
static NSString * const kOutdatedResourcesStoryboardIdentifier = @"OutdatedResourcesViewController";
static NSInteger const kLocalResourcesScope = 1;

@implementation OADeepLinkBridge

+ (BOOL)openFavouriteOrMoveMapWithLat:(double)lat lon:(double)lon zoom:(int)zoom name:(NSString *)name
{
    OAFavoriteItem *point = [OAFavoritesHelper getVisibleFavByLat:lat lon:lon];
    if (point && ([name isEqualToString:[point getName]] || [point isSpecialPoint]))
    {
        OATargetPoint *targetPoint = [[OARootViewController instance].mapPanel.mapViewController.mapLayers.favoritesLayer getTargetPoint:point touchLocation:nil];
        targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
        targetPoint.shouldFetchAddress = YES;
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
    return [mapViewController.mapLayers.contextMenuLayer unknownTargetPoint:lat longitude:lon];
}

+ (BOOL)isMapsAndResourcesController:(UIViewController *)controller
{
    OAManageResourcesViewController *resourcesController = [controller isKindOfClass:OAManageResourcesViewController.class] ? (OAManageResourcesViewController *) controller : nil;
    return resourcesController && [resourcesController currentScope] != kLocalResourcesScope;
}

+ (BOOL)isMapsAndResourcesLocalController:(UIViewController *)controller
{
    OAManageResourcesViewController *resourcesController = [controller isKindOfClass:OAManageResourcesViewController.class] ? (OAManageResourcesViewController *) controller : nil;
    return resourcesController && [resourcesController currentScope] == kLocalResourcesScope;
}

+ (BOOL)isMapsAndResourcesUpdatesController:(UIViewController *)controller
{
    return [controller isKindOfClass:OAOutdatedResourcesViewController.class];
}

+ (UIViewController *)mapsAndResourcesViewController
{
    return [[UIStoryboard storyboardWithName:kResourcesStoryboardName bundle:nil] instantiateInitialViewController];
}

+ (UIViewController *)mapsAndResourcesLocalViewController
{
    UIViewController *controller = [self mapsAndResourcesViewController];
    if (![controller isKindOfClass:OAManageResourcesViewController.class])
        return nil;
    
    OAManageResourcesViewController *resourcesController = (OAManageResourcesViewController *) controller;
    [resourcesController configureForLocalResources];
    return resourcesController;
}

+ (UIViewController *)mapsAndResourcesUpdatesViewController
{
    return [[UIStoryboard storyboardWithName:kResourcesStoryboardName bundle:nil] instantiateViewControllerWithIdentifier:kOutdatedResourcesStoryboardIdentifier];
}

+ (OAMapSource *)offlineMapSourceWithStyleName:(NSString *)styleName
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
    const auto localResources = app.resourcesManager->getLocalResources();
    for (const auto& resource : localResources)
    {
        if (resource->type != OsmAnd::ResourcesManager::ResourceType::MapStyle)
            continue;

        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        if (mapStyle->name.endsWith(QStringLiteral(".addon")))
            continue;

        NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:mapStyle->title.toNSString()];
        if (![mapStyleInfo[@"title"] isEqualToString:styleName])
            continue;

        OAMapSource *mapSource = [app.data lastMapSourceByResourceId:resource->id.toNSString()];
        if (!mapSource)
        {
            mapSource = [[OAMapSource alloc] initWithResource:[[mapStyleInfo[@"id"] lowercaseString] stringByAppendingString:RENDERER_INDEX_EXT]
                                                   andVariant:mode.variantKey
                                                         name:mapStyleInfo[@"title"]];
        }
        else if (![mapSource.name isEqualToString:mapStyleInfo[@"title"]])
        {
            mapSource.name = mapStyleInfo[@"title"];
        }
        return mapSource;
    }
    return nil;
}

@end
