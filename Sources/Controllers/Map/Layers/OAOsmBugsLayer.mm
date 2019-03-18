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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@implementation OAOsmBugsLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _favoritesMarkersCollection;
}

- (NSString *) layerId
{
    return kOsmBugsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    self.app.favoritesCollection->collectionChangeObservable.attach((__bridge const void*)self,
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                                {
                                                                    [self onFavoritesCollectionChanged];
                                                                });
    
    self.app.favoritesCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
                                                                      [self]
                                                                      (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                       const std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation)
                                                                      {
                                                                          [self onFavoriteLocationChanged:favoriteLocation];
                                                                      });

    [self refreshFavoritesMarkersCollection];
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                    Visibility:[[OAAppSettings sharedManager] mapSettingShowFavorites]];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    self.app.favoritesCollection->collectionChangeObservable.detach((__bridge const void*)self);
    self.app.favoritesCollection->favoriteLocationChangeObservable.detach((__bridge const void*)self);
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getFavoritesMarkersCollection
{
    return _favoritesMarkersCollection;
}

- (void) refreshFavoritesMarkersCollection
{
    _favoritesMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    
    for (const auto& favLoc : self.app.favoritesCollection->getFavoriteLocations())
    {
        UIColor* color = [UIColor colorWithRed:favLoc->getColor().r/255.0 green:favLoc->getColor().g/255.0 blue:favLoc->getColor().b/255.0 alpha:1.0];
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        
        OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:favCol.iconName])
        .setPosition(favLoc->getPosition31())
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .buildAndAddToCollection(_favoritesMarkersCollection);
    }
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_favoritesMarkersCollection];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_favoritesMarkersCollection];
    }];
}

- (void) onFavoritesCollectionChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hide];
        [self refreshFavoritesMarkersCollection];
        [self show];
    });
}

- (void) onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hide];
        [self refreshFavoritesMarkersCollection];
        [self show];
    });
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
        for (const auto& fav : _favoritesMarkersCollection->getMarkers())
        {
            if (markerGroup->getMapMarker() == fav.get())
            {
                double lat = OsmAnd::Utilities::get31LatitudeY(fav->getPosition().y);
                double lon = OsmAnd::Utilities::get31LongitudeX(fav->getPosition().x);
                for (const auto& favLoc : self.app.favoritesCollection->getFavoriteLocations())
                {
                    double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
                    double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
                    if ([OAUtilities isCoordEqual:favLat srcLon:favLon destLat:lat destLon:lon])
                    {
                        OATargetPoint *targetPoint = [self getTargetPointCpp:favLoc.get()];
                        if (![found containsObject:targetPoint])
                            [found addObject:targetPoint];
                    }
                }
            }
        }
    }
}

@end
