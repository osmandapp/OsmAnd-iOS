//
//  OAOsmEditsLayer.m
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditsLayer.h"
#import "OADefaultFavorite.h"
#import "OAFavoriteItem.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@implementation OAOsmEditsLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _osmEditsCollection;
    OAOsmEditingPlugin *_plugin;
}

-(id) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder plugin:(OAOsmEditingPlugin *)plugin
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self) {
        _plugin = plugin;
    }
    return self;
}

- (NSString *) layerId
{
    return kOsmEditsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    [self refreshOsmEditsCollection];
    
//
//    [self.app.data.mapLayersConfiguration setLayer:self.layerId
//                                    Visibility:[[OAAppSettings sharedManager] mapSettingShowFavorites]];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    self.app.favoritesCollection->collectionChangeObservable.detach((__bridge const void*)self);
    self.app.favoritesCollection->favoriteLocationChangeObservable.detach((__bridge const void*)self);
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getOsmEditsCollection
{
    return _osmEditsCollection;
}

- (void) refreshOsmEditsCollection
{
    _osmEditsCollection.reset(new OsmAnd::MapMarkersCollection());
    NSArray *data = @[];
    data = [data arrayByAddingObjectsFromArray:[[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints]];
    data = [data arrayByAddingObjectsFromArray:[[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints]];
    for (id<OAOsmPointProtocol> point in data)
    {
        OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"my_location_marker_car"])
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon([point getLatitude], [point getLongitude])))
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .buildAndAddToCollection(_osmEditsCollection);
    }
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_osmEditsCollection];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_osmEditsCollection];
    }];
}

- (void) onFavoritesCollectionChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hide];
        [self refreshOsmEditsCollection];
        [self show];
    });
}

- (void) onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hide];
        [self refreshOsmEditsCollection];
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
//    if (const auto favLoc = reinterpret_cast<const OsmAnd::IFavoriteLocation *>(obj))
//    {
//        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
//        targetPoint.type = OATargetFavorite;
//        double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
//        double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
//        targetPoint.location = CLLocationCoordinate2DMake(favLat, favLon);
//
//        UIColor* color = [UIColor colorWithRed:favLoc->getColor().r/255.0 green:favLoc->getColor().g/255.0 blue:favLoc->getColor().b/255.0 alpha:1.0];
//        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
//
//        targetPoint.title = favLoc->getTitle().toNSString();
//        targetPoint.icon = [UIImage imageNamed:favCol.iconName];
//
//        targetPoint.sortIndex = (NSInteger)targetPoint.type;
//        return targetPoint;
//    }
//    else
//    {
        return nil;
//    }
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    
//    for (const auto& edit : _osmEditsCollection->getMarkers())
//    {
//        
//        double lat = OsmAnd::Utilities::get31LatitudeY(edit->getPosition().y);
//        double lon = OsmAnd::Utilities::get31LongitudeX(edit->getPosition().x);
//        for (const auto& favLoc : self.app.favoritesCollection->getFavoriteLocations())
//        {
//            double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
//            double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
//            if ([OAUtilities isCoordEqual:favLat srcLon:favLon destLat:lat destLon:lon])
//            {
//                OATargetPoint *targetPoint = [self getTargetPointCpp:favLoc.get()];
//                if (![found containsObject:targetPoint])
//                    [found addObject:targetPoint];
//            }
//        }
//        
//    }
}

@end
