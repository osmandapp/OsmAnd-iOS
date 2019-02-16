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
#import "OAEntity.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAOsmNotePoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAPOIHelper.h"
#import "OAAutoObserverProxy.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@implementation OAOsmEditsLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _osmEditsCollection;
    OAOsmEditingPlugin *_plugin;
    
    OAAutoObserverProxy *_editsChangedObserver;
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
    
    _editsChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onEditsCollectionChanged)
                                                       andObserve:self.app.osmEditsChangeObservable];
    
    [self refreshOsmEditsCollection];
    
//
//    [self.app.data.mapLayersConfiguration setLayer:self.layerId
//                                    Visibility:[[OAAppSettings sharedManager] mapSettingShowFavorites]];
}

- (void) deinitLayer
{
    [super deinitLayer];
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getOsmEditsCollection
{
    return _osmEditsCollection;
}

- (void) refreshOsmEditsCollection
{
    _osmEditsCollection.reset(new OsmAnd::MapMarkersCollection());
    NSArray * data = [self getAllPoints];
    for (OAOsmPoint *point in data)
    {
        OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_osm_edit"])
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

- (void) onEditsCollectionChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hide];
        [self refreshOsmEditsCollection];
        [self show];
    });
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *)getTargetPointFromPoint:(OAOsmPoint *)point {
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.location = CLLocationCoordinate2DMake(point.getLatitude, point.getLongitude);
    targetPoint.title = point.getName;
    
    targetPoint.values = point.getTags;
    targetPoint.icon = [self getUIImangeForPoint:point];
    
    targetPoint.type = OATargetOsmEdit;
    
    targetPoint.targetObj = point;
    
    targetPoint.sortIndex = (NSInteger)targetPoint.type;
    return targetPoint;
}

-(UIImage *)getUIImangeForPoint:(OAOsmPoint *)point
{
    if ([point getSubType])
    {
        OAPOIType *type = [[OAPOIHelper sharedInstance] getPoiTypeByName:[point.getSubType lowerCase]];
        return type ? type.icon : nil;
    }
    return [UIImage imageNamed:@"map_osm_edit"];
}

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:OAOsmPoint.class])
        return [self getTargetPointFromPoint:(OAOsmPoint *)obj];
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (NSArray *)getAllPoints {
    NSArray *data = @[];
    data = [data arrayByAddingObjectsFromArray:[[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints]];
    data = [data arrayByAddingObjectsFromArray:[[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints]];
    return data;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    for (const auto& edit : _osmEditsCollection->getMarkers())
    {
        double lat = OsmAnd::Utilities::get31LatitudeY(edit->getPosition().y);
        double lon = OsmAnd::Utilities::get31LongitudeX(edit->getPosition().x);
        NSArray * data = [self getAllPoints];
        for (OAOsmPoint *osmPoint in data)
        {
            double pointLat = osmPoint.getLatitude;
            double pointLon = osmPoint.getLongitude;
            if ([OAUtilities isCoordEqual:pointLat srcLon:pointLon destLat:lat destLon:lon])
            {
                if (OsmAnd::Utilities::distance(pointLat, pointLon, point.latitude, point.longitude) < 15) {
                    OATargetPoint *targetPoint = [self getTargetPoint:osmPoint];
                    if (![found containsObject:targetPoint])
                        [found addObject:targetPoint];
                }
            }
        }
    }
}

@end
