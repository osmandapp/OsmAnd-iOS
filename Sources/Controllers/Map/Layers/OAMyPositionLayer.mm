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
#import "OAMapViewTrackingUtilities.h"
#import "OATargetPoint.h"
#import "Localization.h"
#import "OALocationIcon.h"
#import "OANavigationIcon.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

typedef enum {
    
    OAMarkerColletionStateStay = 0,
    OAMarkerColletionStateMove,
    OAMarkerColletionStateOutdatedLocation,
    
} EOAMarkerCollectionState;

typedef enum {

    OAMarkerColletionModeUndefined = 0,
    OAMarkerColletionModeDay,
    OAMarkerColletionModeNight,
    
} EOAMarkerCollectionMode;

@interface OAMarkerCollection : NSObject

@property (nonatomic) EOAMarkerCollectionMode mode;
@property (nonatomic) EOAMarkerCollectionState state;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarkersCollection> markerCollection;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationHeadingIconKeyDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationHeadingIconKeyNight;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerLostDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyLostDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerLostNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyLostNight;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> courseMarkerDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey courseMainIconKeyDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> courseMarkerNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey courseMainIconKeyNight;

- (void) hideMarkers;
- (void) updateLocation:(OsmAnd::PointI)target31 horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy heading:(CLLocationDirection)heading;

@end

@implementation OAMarkerCollection

- (void) hideMarkers
{
    _locationMarkerDay->setIsHidden(true);
    _locationMarkerDay->setIsAccuracyCircleVisible(false);
    _locationMarkerNight->setIsHidden(true);
    _locationMarkerNight->setIsAccuracyCircleVisible(false);
    _locationMarkerLostDay->setIsHidden(true);
    _locationMarkerLostDay->setIsAccuracyCircleVisible(false);
    _locationMarkerLostNight->setIsHidden(true);
    _locationMarkerLostNight->setIsAccuracyCircleVisible(false);
    _courseMarkerDay->setIsHidden(true);
    _courseMarkerDay->setIsAccuracyCircleVisible(false);
    _courseMarkerNight->setIsHidden(true);
    _courseMarkerNight->setIsAccuracyCircleVisible(false);
}

- (void) setState:(EOAMarkerCollectionState)state
{
    if (_state != state)
    {
        _state = state;
        [self updateState];
    }
}

- (void) setMode:(EOAMarkerCollectionMode)mode
{
    if (_mode != mode)
    {
        _mode = mode;
        [self updateState];
    }
}

- (void) updateState
{
    switch (_state)
    {
        case OAMarkerColletionStateStay:
        {
            _courseMarkerDay->setIsHidden(true);
            _courseMarkerNight->setIsHidden(true);
            _locationMarkerLostDay->setIsHidden(true);
            _locationMarkerLostNight->setIsHidden(true);
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    _locationMarkerDay->setIsHidden(false);
                    _locationMarkerNight->setIsHidden(true);
                    break;
                    
                case OAMarkerColletionModeNight:
                    _locationMarkerDay->setIsHidden(true);
                    _locationMarkerNight->setIsHidden(false);
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case OAMarkerColletionStateMove:
        {
            _locationMarkerDay->setIsHidden(true);
            _locationMarkerNight->setIsHidden(true);
            _locationMarkerLostDay->setIsHidden(true);
            _locationMarkerLostNight->setIsHidden(true);
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    _courseMarkerNight->setIsHidden(true);
                    _courseMarkerDay->setIsHidden(false);
                    break;

                case OAMarkerColletionModeNight:
                    _courseMarkerDay->setIsHidden(true);
                    _courseMarkerNight->setIsHidden(false);
                    break;
                    
                default:
                    break;
            }

            break;
        }
        case OAMarkerColletionStateOutdatedLocation:
        {
            _courseMarkerDay->setIsHidden(true);
            _courseMarkerNight->setIsHidden(true);
            _locationMarkerDay->setIsHidden(true);
            _locationMarkerNight->setIsHidden(true);
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    _locationMarkerLostDay->setIsHidden(false);
                    _locationMarkerLostNight->setIsHidden(true);
                    break;
                    
                case OAMarkerColletionModeNight:
                    _locationMarkerLostDay->setIsHidden(true);
                    _locationMarkerLostNight->setIsHidden(false);
                    break;
                    
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}



- (void) updateLocation:(OsmAnd::PointI)target31 horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy heading:(CLLocationDirection)heading
{
    std::shared_ptr<OsmAnd::MapMarker> marker;
    OsmAnd::MapMarker::OnSurfaceIconKey iconKey = NULL;

    switch (_state)
    {
        case OAMarkerColletionStateMove:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    marker = _courseMarkerDay;
                    iconKey = _courseMainIconKeyDay;
                    break;
                case OAMarkerColletionModeNight:
                    marker = _courseMarkerNight;
                    iconKey = _courseMainIconKeyNight;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case OAMarkerColletionStateOutdatedLocation:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    marker = _locationMarkerLostDay;
                    break;
                case OAMarkerColletionModeNight:
                    marker = _locationMarkerLostNight;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        default:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    marker = _locationMarkerDay;
                    iconKey = _locationHeadingIconKeyDay;
                    break;
                case OAMarkerColletionModeNight:
                    marker = _locationMarkerNight;
                    iconKey = _locationHeadingIconKeyNight;
                    break;
                    
                default:
                    break;
            }
            break;
        }
    }
    
    if (marker)
    {
        marker->setPosition(target31);
        marker->setIsAccuracyCircleVisible(true);
        marker->setAccuracyCircleRadius(horizontalAccuracy);
        if (iconKey != NULL)
            marker->setOnMapSurfaceIconDirection(iconKey, OsmAnd::Utilities::normalizedAngleDegrees(heading));
        if (marker->isHidden())
            marker->setIsHidden(false);
    }
}

@end

@implementation OAMyPositionLayer
{
    OAMapViewTrackingUtilities *_mapViewTrackingUtilities;
    
    NSMapTable<OAApplicationMode *, OAMarkerCollection *> *_modeMarkers;
    CLLocation *_lastLocation;
    CLLocationDirection _lastHeading;
    
    OAAutoObserverProxy* _appModeChangeObserver;

    BOOL _initDone;
}

- (void) generateMarkersCollection
{
    // Create location and course markers
    int baseOrder = self.baseOrder;
    
    _modeMarkers = [NSMapTable strongToStrongObjectsMapTable];
    NSArray<OAApplicationMode *> *modes = [OAApplicationMode allPossibleValues];
    for (OAApplicationMode *mode in modes)
    {
        OAMarkerCollection *c = [[OAMarkerCollection alloc] init];
        
        c.markerCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilder;
        
        locationAndCourseMarkerBuilder.setIsAccuracyCircleSupported(true);
        locationAndCourseMarkerBuilder.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
        locationAndCourseMarkerBuilder.setBaseOrder(baseOrder--);
        locationAndCourseMarkerBuilder.setIsHidden(true);
        
        OALocationIcon *locIcon = [OALocationIcon withLocationIcon:mode.getLocationIcon];
        OANavigationIcon *navIcon = [OANavigationIcon withNavigationIcon:mode.getNavigationIcon];
        UIColor *iconColor = UIColorFromRGB(mode.getIconColor);
        
        // Day
        c.locationMainIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyDay,
                                                           [OANativeUtilities skImageFromCGImage:[locIcon iconWithColor:iconColor].CGImage]);
        c.locationHeadingIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationHeadingIconKeyDay,
                                                           [OANativeUtilities skImageFromCGImage:[locIcon headingIconWithColor:iconColor].CGImage]);
        c.locationMarkerDay = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
        
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.courseMainIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.courseMainIconKeyDay,
                                                           [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:iconColor].CGImage]);
        c.courseMarkerDay = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
        
        // Night
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.locationMainIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyNight,
                                                           [OANativeUtilities skImageFromCGImage:[locIcon iconWithColor:iconColor].CGImage]);
        c.locationHeadingIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationHeadingIconKeyNight,
                                                           [OANativeUtilities skImageFromCGImage:[locIcon headingIconWithColor:iconColor].CGImage]);
        c.locationMarkerNight = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);

        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.courseMainIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.courseMainIconKeyNight,
                                                           [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:iconColor].CGImage]);
        c.courseMarkerNight = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);

        locationAndCourseMarkerBuilder.setIsAccuracyCircleSupported(false);

        // Lost (day)
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.locationMainIconKeyLostDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyLostDay,
                                                           [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:UIColorFromRGB(location_icon_color_lost)].CGImage]);
        c.locationMarkerLostDay = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
        
        // Lost (night)
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.locationMainIconKeyLostNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyLostNight,
                                                           [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:UIColorFromRGB(location_icon_color_lost)].CGImage]);
        c.locationMarkerLostNight = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
    
        [self updateMode:c];
        
        [_modeMarkers setObject:c forKey:mode];
    }
}

- (NSString *) layerId
{
    return kMyPositionLayerId;
}

- (void) initLayer
{
    _mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
    
    _appModeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onAvailableAppModesChanged)
                                                        andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
    
    [self generateMarkersCollection];
    
    _initDone = YES;
    
    // Add "My location" and "My course" markers
    [self updateMyLocationCourseProvider];
}

- (void) deinitLayer
{
    [_appModeChangeObserver detach];
    _appModeChangeObserver = nil;
}

- (void) onAvailableAppModesChanged
{
    [self.mapViewController runWithRenderSync:^{
        [self invalidateMarkersCollection];
        [self generateMarkersCollection];
        [self updateMyLocationCourseProvider];
    }];
}

- (void) invalidateMarkersCollection
{
    for (OAApplicationMode *mode in _modeMarkers.keyEnumerator)
    {
        OAMarkerCollection *c = [_modeMarkers objectForKey:mode];
        [c hideMarkers];
        [self.mapView removeKeyedSymbolsProvider:c.markerCollection];
    }
}

- (void) updateMyLocationCourseProvider
{
    if (!_initDone)
        return;
    
    [self.mapViewController runWithRenderSync:^{
    
        OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
        for (OAApplicationMode *mode in _modeMarkers.keyEnumerator)
        {
            OAMarkerCollection *c = [_modeMarkers objectForKey:mode];
            if (mode == currentMode)
            {
                [self updateLocation:c];
                [self.mapView addKeyedSymbolsProvider:c.markerCollection];
            }
            else
            {
                [c hideMarkers];
                [self.mapView removeKeyedSymbolsProvider:c.markerCollection];
            }
        }
    }];
}

- (void) updateMode
{
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
    OAMarkerCollection *c = [_modeMarkers objectForKey:currentMode];
    [self updateMode:c];
}

- (void) updateMode:(OAMarkerCollection *)c
{
    c.mode = [OAAppSettings sharedManager].nightMode ? OAMarkerColletionModeNight : OAMarkerColletionModeDay;
}

- (void) updateLocation:(OAMarkerCollection *)c
{
    if (!_initDone)
        return;

    CLLocation *newLocation = _lastLocation;
    CLLocationDirection newHeading = _lastHeading;
    
    // In case there's no known location, do nothing and hide all markers
    if (!newLocation)
    {
        [c hideMarkers];
        return;
    }
    
    const OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                     OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
    
    if (newLocation.course >= 0)
    {
        c.state = OAMarkerColletionStateMove;
        [c updateLocation:newTarget31 horizontalAccuracy:newLocation.horizontalAccuracy heading:newLocation.course - 90];
    }
    else if (_mapViewTrackingUtilities.showViewAngle)
    {
        c.state = OAMarkerColletionStateStay;
        [c updateLocation:newTarget31 horizontalAccuracy:newLocation.horizontalAccuracy heading:newHeading];
    }
}

- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading
{
    _lastLocation = newLocation;
    _lastHeading = newHeading;
    
    if (!_initDone)
        return;
    
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
    OAMarkerCollection *c = [_modeMarkers objectForKey:currentMode];
    [self updateLocation:c];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[CLLocation class]])
    {
        CLLocation *myLocation = (CLLocation *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetMyLocation;
        targetPoint.location = myLocation.coordinate;
        targetPoint.title = OALocalizedString(@"my_location");
        targetPoint.icon = [UIImage imageNamed:@"ic_action_location_color.png"];

        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    OAMapRendererView *mapView = self.mapView;
    CLLocation* myLocation = _lastLocation;
    if (myLocation)
    {
        CGPoint myLocationScreen;
        OsmAnd::PointI myLocationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(myLocation.coordinate.latitude, myLocation.coordinate.longitude));
        [mapView convert:&myLocationI toScreen:&myLocationScreen];
        myLocationScreen.x *= mapView.contentScaleFactor;
        myLocationScreen.y *= mapView.contentScaleFactor;
        
        if (fabs(myLocationScreen.x - touchPoint.x) < kDefaultSearchRadiusOnMap && fabs(myLocationScreen.y - touchPoint.y) < kDefaultSearchRadiusOnMap)
        {
            OATargetPoint *targetPoint = [self getTargetPoint:myLocation];
            if (![found containsObject:targetPoint])
                [found addObject:targetPoint];
        }
    }
}

@end
