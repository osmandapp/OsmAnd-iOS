//
//  OAImpassableRoadsLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImpassableRoadsLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAvoidSpecificRoads.h"
#import "OAStateChangedListener.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@interface OAImpassableRoadsLayer () <OAStateChangedListener>

@end

@implementation OAImpassableRoadsLayer
{
    OAAvoidSpecificRoads *_avoidRoads;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
}

- (NSString *) layerId
{
    return kImpassableRoadsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _avoidRoads = [OAAvoidSpecificRoads instance];
    [self updatePoints];
    [_avoidRoads addListener:self];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    [_avoidRoads removeListener:self];
}

- (void) resetPoints
{
    if (_markersCollection)
        [self.mapView removeKeyedSymbolsProvider:_markersCollection];
    
    _markersCollection.reset(new OsmAnd::MapMarkersCollection());
}

- (void) setupPoints
{
    const auto& roads = [_avoidRoads getImpassableRoads];
    for (const auto& road : roads)
    {
        CLLocation *location = [_avoidRoads getLocation:road];
        if (location)
        {
            const OsmAnd::LatLon latLon(location.coordinate.latitude, location.coordinate.longitude);
            std::shared_ptr<OsmAnd::MapMarker> mapMarker = OsmAnd::MapMarkerBuilder()
            .setIsAccuracyCircleSupported(false)
            .setBaseOrder(self.baseOrder + 1)
            .setIsHidden(false)
            .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_pin_avoid_road"])
            .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
            .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
            .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
            .buildAndAddToCollection(_markersCollection);
        }
    }
    
    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_markersCollection];
    }];
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getImpassableMarkersCollection
{
    return _markersCollection;
}

- (void) updatePoints
{
    [self.mapViewController runWithRenderSync:^{
        
        [self resetPoints];
        [self setupPoints];
    }];
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    [self updatePoints];
}

#pragma mark - OAContextMenuProvider

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAMapRendererView *mapView = self.mapView;
    if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo->mapSymbol->groupPtr))
    {
        for (const auto& r : _markersCollection->getMarkers())
        {
            if (markerGroup->getMapMarker() == r.get())
            {
                double lat = OsmAnd::Utilities::get31LatitudeY(r->getPosition().y);
                double lon = OsmAnd::Utilities::get31LongitudeX(r->getPosition().x);
                OAAvoidSpecificRoads *avoidRoads = [OAAvoidSpecificRoads instance];
                const auto& roads = [avoidRoads getImpassableRoads];
                for (const auto& road : roads)
                {
                    CLLocation *location = [avoidRoads getLocation:road];
                    if (location && [OAUtilities doublesEqualUpToDigits:5 source:location.coordinate.latitude destination:lat] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:location.coordinate.longitude destination:lon])
                    {
                        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
                        targetPoint.location = location.coordinate;
                        targetPoint.zoom = mapView.zoom;
                        targetPoint.touchPoint = touchPoint;

                        QString lang = QString::fromNSString([settings settingPrefMapLanguage] ? [settings settingPrefMapLanguage] : @"");
                        bool transliterate = [settings settingMapLanguageTranslit];
                        targetPoint.title = road->getName(lang, transliterate).toNSString();
                        targetPoint.icon = [UIImage imageNamed:@"map_pin_avoid_road"];
                        
                        targetPoint.type = OATargetImpassableRoad;
                        targetPoint.targetObj = @((unsigned long long)road->id);
                        
                        [found addObject:targetPoint];
                    }
                }
            }
        }
    }
}

@end
