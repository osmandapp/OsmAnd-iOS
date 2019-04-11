//
//  OAOsmBugsLayer.m
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmBugsLayer.h"
#import "OADefaultFavorite.h"
#import "OAFavoriteItem.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAOsmEditingPlugin.h"
#import "OAPlugin.h"
#import "OAOsmBugResult.h"
#import "OAOsmNotesMapLayerProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

#define kMaxZoom 12

static const NSString* BASE_URL = @"https://api.openstreetmap.org/";

@interface OAOsmBugsLayer ()

@end

@implementation OAOsmBugsLayer
{
    std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider> _notesMapProvider;
    OAOsmEditingPlugin *_plugin;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self) {
        _plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    }
    return self;
}

- (NSString *) layerId
{
    return kOsmBugsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                    Visibility:YES];
    
    _notesMapProvider.reset(new OAOsmNotesMapLayerProvider());
    [self.mapView addTiledSymbolsProvider:_notesMapProvider];
}


- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addTiledSymbolsProvider:_notesMapProvider];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addTiledSymbolsProvider:_notesMapProvider];
    }];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    if (const auto favLoc = reinterpret_cast<const OsmAnd::IFavoriteLocation *>(obj))
    {
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetFavorite;
        double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
        double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
        targetPoint.location = CLLocationCoordinate2DMake(favLat, favLon);
        
        UIColor* color = [UIColor colorWithRed:favLoc->getColor().r/255.0 green:favLoc->getColor().g/255.0 blue:favLoc->getColor().b/255.0 alpha:1.0];
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        
        targetPoint.title = favLoc->getTitle().toNSString();
        targetPoint.icon = [UIImage imageNamed:favCol.iconName];
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    else
    {
        return nil;
    }
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo->mapSymbol->groupPtr))
    {
//        for (const auto& fav : _onlineNotesCollection->getMarkers())
//        {
//            if (markerGroup->getMapMarker() == fav.get())
//            {
//                double lat = OsmAnd::Utilities::get31LatitudeY(fav->getPosition().y);
//                double lon = OsmAnd::Utilities::get31LongitudeX(fav->getPosition().x);
//                for (const auto& favLoc : self.app.favoritesCollection->getFavoriteLocations())
//                {
//                    double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
//                    double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
//                    if ([OAUtilities isCoordEqual:favLat srcLon:favLon destLat:lat destLon:lon])
//                    {
//                        OATargetPoint *targetPoint = [self getTargetPointCpp:favLoc.get()];
//                        if (![found containsObject:targetPoint])
//                            [found addObject:targetPoint];
//                    }
//                }
//            }
//        }
    }
}

@end
