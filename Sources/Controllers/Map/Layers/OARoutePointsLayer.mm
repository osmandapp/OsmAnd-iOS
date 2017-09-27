//
//  OARoutePointsLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePointsLayer.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OARoutePointsLayer () <OAStateChangedListener>

@end

@implementation OARoutePointsLayer
{
    OATargetPointsHelper *_targetPoints;
    
    // Markers
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _startPointMarker;
    std::shared_ptr<OsmAnd::MapMarker> _targetPointMarker;
    QList<std::shared_ptr<OsmAnd::MapMarker>> _intermediatePointMarkers;
}

- (NSString *) layerId
{
    return kRoutePointsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _targetPoints = [OATargetPointsHelper sharedInstance];
    [_targetPoints addListener:self];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    [_targetPoints removeListener:self];
}

- (void) resetPoints
{
    if (_markersCollection)
        [self.mapView removeKeyedSymbolsProvider:_markersCollection];
    
    _markersCollection.reset(new OsmAnd::MapMarkersCollection());
}

- (void) setupPoints
{
    OARTargetPoint *pointToStart = [_targetPoints getPointToStart];
    if (pointToStart)
    {
        const OsmAnd::LatLon latLon([pointToStart getLatitude], [pointToStart getLongitude]);
        _startPointMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_start_point"])
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
        .buildAndAddToCollection(_markersCollection);
    }
    
    for (OARTargetPoint *point in [_targetPoints getIntermediatePoints])
    {
        const OsmAnd::LatLon latLon([point getLatitude], [point getLongitude]);
        _targetPointMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder + 1)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_intermediate_point"])
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
        .buildAndAddToCollection(_markersCollection);
    }
    
    OARTargetPoint *pointToNavigate = [_targetPoints getPointToNavigate];
    if (pointToNavigate)
    {
        const OsmAnd::LatLon latLon([pointToNavigate getLatitude], [pointToNavigate getLongitude]);
        _targetPointMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder + 2)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_target_point"])
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
        .buildAndAddToCollection(_markersCollection);
    }
    
    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_markersCollection];
    }];
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
