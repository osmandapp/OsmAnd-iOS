//
//  OAMyPositionLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMyPositionLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapStyleSettings.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@implementation OAMyPositionLayer
{
    // "My location" marker, "My course" marker and collection
    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKey;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKey;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKey;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollectionPedestrian;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarkerPedestrian;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKeyPedestrian;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKeyPedestrian;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarkerPedestrian;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKeyPedestrian;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollectionBicycle;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarkerBicycle;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKeyBicycle;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKeyBicycle;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarkerBicycle;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKeyBicycle;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollectionCar;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarkerCar;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKeyCar;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKeyCar;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarkerCar;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKeyCar;
    
    BOOL _initDone;
}

+ (NSString *) getLayerId
{
    return kMyPositionLayerId;
}

- (void) initLayer
{
    // Create location and course markers
    _myMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilder;
    
    locationAndCourseMarkerBuilder.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilder.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilder.setBaseOrder(-206000);
    locationAndCourseMarkerBuilder.setIsHidden(true);
    _myLocationMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(_myLocationMainIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_icon"]);
    _myLocationHeadingIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(_myLocationHeadingIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon"]);
    _myLocationMarker = locationAndCourseMarkerBuilder.buildAndAddToCollection(_myMarkersCollection);
    
    locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
    _myCourseMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(_myCourseMainIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_course_marker_icon"]);
    _myCourseMarker = locationAndCourseMarkerBuilder.buildAndAddToCollection(_myMarkersCollection);
    
    // Pedestrian
    _myMarkersCollectionPedestrian.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilderPedestrian;
    
    locationAndCourseMarkerBuilderPedestrian.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilderPedestrian.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilderPedestrian.setBaseOrder(-206001);
    locationAndCourseMarkerBuilderPedestrian.setIsHidden(true);
    _myLocationMainIconKeyPedestrian = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderPedestrian.addOnMapSurfaceIcon(_myLocationMainIconKeyPedestrian,
                                                                 [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_icon"]);
    _myLocationHeadingIconKeyPedestrian = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilderPedestrian.addOnMapSurfaceIcon(_myLocationHeadingIconKeyPedestrian,
                                                                 [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon"]);
    _myLocationMarkerPedestrian = locationAndCourseMarkerBuilderPedestrian.buildAndAddToCollection(_myMarkersCollectionPedestrian);
    
    locationAndCourseMarkerBuilderPedestrian.clearOnMapSurfaceIcons();
    _myCourseMainIconKeyPedestrian = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderPedestrian.addOnMapSurfaceIcon(_myCourseMainIconKeyPedestrian,
                                                                 [OANativeUtilities skBitmapFromPngResource:@"map_pedestrian_bearing"]);
    _myCourseMarkerPedestrian = locationAndCourseMarkerBuilderPedestrian.buildAndAddToCollection(_myMarkersCollectionPedestrian);
    
    // Bicycle
    _myMarkersCollectionBicycle.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilderBicycle;
    
    locationAndCourseMarkerBuilderBicycle.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilderBicycle.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilderBicycle.setBaseOrder(-206002);
    locationAndCourseMarkerBuilderBicycle.setIsHidden(true);
    _myLocationMainIconKeyBicycle = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderBicycle.addOnMapSurfaceIcon(_myLocationMainIconKeyBicycle,
                                                              [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_bicycle"]);
    _myLocationHeadingIconKeyBicycle = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilderBicycle.addOnMapSurfaceIcon(_myLocationHeadingIconKeyBicycle,
                                                              [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon2"]);
    _myLocationMarkerBicycle = locationAndCourseMarkerBuilderBicycle.buildAndAddToCollection(_myMarkersCollectionBicycle);
    
    locationAndCourseMarkerBuilderBicycle.clearOnMapSurfaceIcons();
    _myCourseMainIconKeyBicycle = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderBicycle.addOnMapSurfaceIcon(_myCourseMainIconKeyBicycle,
                                                              [OANativeUtilities skBitmapFromPngResource:@"map_bicycle_bearing"]);
    _myCourseMarkerBicycle = locationAndCourseMarkerBuilderBicycle.buildAndAddToCollection(_myMarkersCollectionBicycle);
    
    // Car
    _myMarkersCollectionCar.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilderCar;
    
    locationAndCourseMarkerBuilderCar.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilderCar.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilderCar.setBaseOrder(-206003);
    locationAndCourseMarkerBuilderCar.setIsHidden(true);
    _myLocationMainIconKeyCar = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderCar.addOnMapSurfaceIcon(_myLocationMainIconKeyCar,
                                                          [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_car"]);
    _myLocationHeadingIconKeyCar = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilderCar.addOnMapSurfaceIcon(_myLocationHeadingIconKeyCar,
                                                          [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon2"]);
    _myLocationMarkerCar = locationAndCourseMarkerBuilderCar.buildAndAddToCollection(_myMarkersCollectionCar);
    
    locationAndCourseMarkerBuilderCar.clearOnMapSurfaceIcons();
    _myCourseMainIconKeyCar = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderCar.addOnMapSurfaceIcon(_myCourseMainIconKeyCar,
                                                          [OANativeUtilities skBitmapFromPngResource:@"map_car_bearing"]);
    _myCourseMarkerCar = locationAndCourseMarkerBuilderCar.buildAndAddToCollection(_myMarkersCollectionCar);
    
    _initDone = YES;
    
    // Add "My location" and "My course" markers
    [self updateMyLocationCourseProvider];
}

- (void) updateMyLocationCourseProvider
{
    if (!_initDone)
        return;
    
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_myMarkersCollectionCar];
        [self.mapView removeKeyedSymbolsProvider:_myMarkersCollectionPedestrian];
        [self.mapView removeKeyedSymbolsProvider:_myMarkersCollectionBicycle];
        [self.mapView removeKeyedSymbolsProvider:_myMarkersCollection];

        OAMapVariantType variantType = [OAMapStyleSettings getVariantType:self.app.data.lastMapSource.variant];
        switch (variantType)
        {
            case OAMapVariantCar:
                [self.mapView addKeyedSymbolsProvider:_myMarkersCollectionCar];
                break;
            case OAMapVariantPedestrian:
                [self.mapView addKeyedSymbolsProvider:_myMarkersCollectionPedestrian];
                break;
            case OAMapVariantBicycle:
                [self.mapView addKeyedSymbolsProvider:_myMarkersCollectionBicycle];
                break;
                
            default:
                [self.mapView addKeyedSymbolsProvider:_myMarkersCollection];
                break;
        }
    }];
}

- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading
{
    if (!_initDone)
        return;

    OAMapVariantType variantType = [OAMapStyleSettings getVariantType:self.app.data.lastMapSource.variant];
    
    // In case there's no known location, do nothing and hide all markers
    if (newLocation == nil)
    {
        switch (variantType)
        {
            case OAMapVariantCar:
                _myLocationMarkerCar->setIsHidden(true);
                _myCourseMarkerCar->setIsHidden(true);
                break;
            case OAMapVariantPedestrian:
                _myLocationMarkerPedestrian->setIsHidden(true);
                _myCourseMarkerPedestrian->setIsHidden(true);
                break;
            case OAMapVariantBicycle:
                _myLocationMarkerBicycle->setIsHidden(true);
                _myCourseMarkerBicycle->setIsHidden(true);
                break;
                
            default:
                _myLocationMarker->setIsHidden(true);
                _myCourseMarker->setIsHidden(true);
                break;
        }
        
        return;
    }
    
    const OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                     OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
    
    // Update "My" markers
    if (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0)
    {
        switch (variantType)
        {
            case OAMapVariantCar:
                _myLocationMarkerCar->setIsHidden(true);
                
                _myCourseMarkerCar->setIsHidden(false);
                _myCourseMarkerCar->setPosition(newTarget31);
                _myCourseMarkerCar->setIsAccuracyCircleVisible(true);
                _myCourseMarkerCar->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarkerCar->setOnMapSurfaceIconDirection(_myCourseMainIconKeyCar,
                                                                 OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
                
            case OAMapVariantPedestrian:
                _myLocationMarkerPedestrian->setIsHidden(true);
                
                _myCourseMarkerPedestrian->setIsHidden(false);
                _myCourseMarkerPedestrian->setPosition(newTarget31);
                _myCourseMarkerPedestrian->setIsAccuracyCircleVisible(true);
                _myCourseMarkerPedestrian->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarkerPedestrian->setOnMapSurfaceIconDirection(_myCourseMainIconKeyPedestrian,
                                                                        OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
                
            case OAMapVariantBicycle:
                _myLocationMarkerBicycle->setIsHidden(true);
                
                _myCourseMarkerBicycle->setIsHidden(false);
                _myCourseMarkerBicycle->setPosition(newTarget31);
                _myCourseMarkerBicycle->setIsAccuracyCircleVisible(true);
                _myCourseMarkerBicycle->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarkerBicycle->setOnMapSurfaceIconDirection(_myCourseMainIconKeyBicycle,
                                                                     OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
                
            default:
                _myLocationMarker->setIsHidden(true);
                
                _myCourseMarker->setIsHidden(false);
                _myCourseMarker->setPosition(newTarget31);
                _myCourseMarker->setIsAccuracyCircleVisible(true);
                _myCourseMarker->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarker->setOnMapSurfaceIconDirection(_myCourseMainIconKey,
                                                              OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
        }
    }
    else
    {
        switch (variantType)
        {
            case OAMapVariantCar:
                _myCourseMarkerCar->setIsHidden(true);
                
                _myLocationMarkerCar->setIsHidden(false);
                _myLocationMarkerCar->setPosition(newTarget31);
                _myLocationMarkerCar->setIsAccuracyCircleVisible(true);
                _myLocationMarkerCar->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarkerCar->setOnMapSurfaceIconDirection(_myLocationHeadingIconKeyCar,
                                                                   OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;
                
            case OAMapVariantPedestrian:
                _myCourseMarkerPedestrian->setIsHidden(true);
                
                _myLocationMarkerPedestrian->setIsHidden(false);
                _myLocationMarkerPedestrian->setPosition(newTarget31);
                _myLocationMarkerPedestrian->setIsAccuracyCircleVisible(true);
                _myLocationMarkerPedestrian->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarkerPedestrian->setOnMapSurfaceIconDirection(_myLocationHeadingIconKeyPedestrian,
                                                                          OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;
                
            case OAMapVariantBicycle:
                _myCourseMarkerBicycle->setIsHidden(true);
                
                _myLocationMarkerBicycle->setIsHidden(false);
                _myLocationMarkerBicycle->setPosition(newTarget31);
                _myLocationMarkerBicycle->setIsAccuracyCircleVisible(true);
                _myLocationMarkerBicycle->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarkerBicycle->setOnMapSurfaceIconDirection(_myLocationHeadingIconKeyBicycle,
                                                                       OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;
                
            default:
                _myCourseMarker->setIsHidden(true);
                
                _myLocationMarker->setIsHidden(false);
                _myLocationMarker->setPosition(newTarget31);
                _myLocationMarker->setIsAccuracyCircleVisible(true);
                _myLocationMarker->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarker->setOnMapSurfaceIconDirection(_myLocationHeadingIconKey,
                                                                OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;
        }
    }
}

@end
