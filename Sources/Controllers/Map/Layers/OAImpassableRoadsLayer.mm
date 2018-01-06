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

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getRouteMarkersCollection
{
    return _markersCollection;
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    [self.mapViewController runWithRenderSync:^{
        
        [self resetPoints];
        [self setupPoints];
    }];
}

@end
