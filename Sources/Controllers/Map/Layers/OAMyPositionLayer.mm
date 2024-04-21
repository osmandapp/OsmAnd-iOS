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
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/SingleSkImage.h>

#define kRotateAnimationTime 1.0f

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

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> straightLocationMarkerDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey straightLocationMainIconKeyDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> straightLocationMarkerNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey straightLocationMainIconKeyNight;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerLostDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyLostDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerLostNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyLostNight;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> courseMarkerDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey courseMainIconKeyDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> courseMarkerNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey courseMainIconKeyNight;

- (instancetype) initWithMapView:(OAMapRendererView *)mapView;

- (void) hideMarkers;
- (void) updateLocation:(OsmAnd::PointI)target31 animationDuration:(float)animationDuration horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy heading:(CLLocationDirection)heading visible:(BOOL)visible;
- (OsmAnd::PointI) getPosition;

@end

@implementation OAMarkerCollection
{
    OAMapRendererView *_mapView;
}

- (instancetype) initWithMapView:(OAMapRendererView *)mapView
{
    self = [super init];
    if (self)
    {
        _mapView = mapView;
    }
    return self;
}

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

- (void) updateLocation:(OsmAnd::PointI)target31 animationDuration:(float)animationDuration horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy heading:(CLLocationDirection)heading visible:(BOOL)visible
{
    std::shared_ptr<OsmAnd::MapMarker> marker = [self getActiveMarker];
    OsmAnd::MapMarker::OnSurfaceIconKey iconKey = [self getActiveIconKey];
    if (marker)
    {
        marker->setIsAccuracyCircleVisible(true);
        marker->setAccuracyCircleRadius(horizontalAccuracy);

        _mapView.mapMarkersAnimator->cancelAnimations(marker);
        if (animationDuration > 0)
        {
            _mapView.mapMarkersAnimator->animatePositionTo(marker, target31, animationDuration,  OsmAnd::Animator::TimingFunction::Linear);
            if (iconKey)
                _mapView.mapMarkersAnimator->animateDirectionTo(marker, iconKey, OsmAnd::Utilities::normalizedAngleDegrees(heading), kRotateAnimationTime,  OsmAnd::Animator::TimingFunction::Linear);
        }
        else
        {
            marker->setPosition(target31);
            if (iconKey)
                marker->setOnMapSurfaceIconDirection(iconKey, OsmAnd::Utilities::normalizedAngleDegrees(heading));
        }

        if (visible && marker->isHidden())
            marker->setIsHidden(false);
    }
}

- (void) updateOtherLocations:(OsmAnd::PointI)target31 horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy heading:(CLLocationDirection)heading
{
    std::shared_ptr<OsmAnd::MapMarker> marker = [self getActiveMarker];

    if (marker != _courseMarkerDay)
    {
        _courseMarkerDay->setPosition(target31);
        if (_courseMainIconKeyDay)
            _courseMarkerDay->setOnMapSurfaceIconDirection(_courseMainIconKeyDay, OsmAnd::Utilities::normalizedAngleDegrees(heading));
    }

    if (marker != _courseMarkerNight)
    {
        _courseMarkerNight->setPosition(target31);
        if (_courseMainIconKeyNight)
            _courseMarkerNight->setOnMapSurfaceIconDirection(_courseMainIconKeyNight, OsmAnd::Utilities::normalizedAngleDegrees(heading));
    }

    if (marker != _locationMarkerLostDay)
        _locationMarkerLostDay->setPosition(target31);

    if (marker != _locationMarkerLostNight)
        _locationMarkerLostNight->setPosition(target31);

    if (marker != _locationMarkerDay)
    {
        _locationMarkerDay->setPosition(target31);
        if (_locationHeadingIconKeyDay)
            _locationMarkerDay->setOnMapSurfaceIconDirection(_locationHeadingIconKeyDay, OsmAnd::Utilities::normalizedAngleDegrees(heading));
    }

    if (marker != _locationMarkerNight)
    {
        _locationMarkerNight->setPosition(target31);
        if (_locationHeadingIconKeyNight)
            _locationMarkerNight->setOnMapSurfaceIconDirection(_locationHeadingIconKeyNight, OsmAnd::Utilities::normalizedAngleDegrees(heading));
    }
}

- (std::shared_ptr<OsmAnd::MapMarker>) getActiveMarker
{
    switch (_state)
    {
        case OAMarkerColletionStateMove:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    return _courseMarkerDay;
                case OAMarkerColletionModeNight:
                    return _courseMarkerNight;
            }
            break;
        }
        case OAMarkerColletionStateOutdatedLocation:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    return _locationMarkerLostDay;
                case OAMarkerColletionModeNight:
                    return _locationMarkerLostNight;
            }
            break;
        }
        default:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    return _locationMarkerDay;
                case OAMarkerColletionModeNight:
                    return _locationMarkerNight;
            }
            break;
        }
    }
    return nil;
}

- (OsmAnd::MapMarker::OnSurfaceIconKey) getActiveIconKey
{
    switch (_state)
    {
        case OAMarkerColletionStateMove:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    return _courseMainIconKeyDay;
                case OAMarkerColletionModeNight:
                    return _courseMainIconKeyNight;
            }
            break;
        }
        case OAMarkerColletionStateOutdatedLocation:
        {
            return NULL;
        }
        default:
        {
            switch (_mode)
            {
                case OAMarkerColletionModeDay:
                    return _locationHeadingIconKeyDay;
                case OAMarkerColletionModeNight:
                    return _locationHeadingIconKeyNight;
            }
            break;
        }
    }
    return NULL;
}

- (OsmAnd::PointI) getPosition
{
    std::shared_ptr<OsmAnd::MapMarker> marker = [self getActiveMarker];
    OsmAnd::MapMarker::OnSurfaceIconKey iconKey = [self getActiveIconKey];
    return marker ? marker->getPosition() : OsmAnd::PointI();
}
@end

@implementation OAMyPositionLayer
{
    OAMapViewTrackingUtilities *_mapViewTrackingUtilities;
    
    NSMapTable<OAApplicationMode *, OAMarkerCollection *> *_modeMarkers;
    CLLocation *_lastLocation;
    CLLocationDirection _lastHeading;
    CLLocation *_prevLocation;
    float _textScaleFactor;

    OAAutoObserverProxy* _appModeChangeObserver;

    BOOL _initDone;
}

- (void) generateMarkersCollection
{
    // Create location and course markers
    int baseOrder = self.pointsOrder;
    
    _modeMarkers = [NSMapTable strongToStrongObjectsMapTable];
    NSArray<OAApplicationMode *> *modes = [OAApplicationMode allPossibleValues];
    for (OAApplicationMode *mode in modes)
    {
        OAMarkerCollection *c = [[OAMarkerCollection alloc] initWithMapView:self.mapView];

        c.markerCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        c.markerCollection->setPriority(std::numeric_limits<int64_t>::max());

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
        sk_sp<SkImage> locationMainIcon = [OANativeUtilities skImageFromCGImage:[locIcon iconWithColor:iconColor].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyDay,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationMainIcon scaleFactor:_textScaleFactor]));

        c.locationHeadingIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
        sk_sp<SkImage> locationHeadingIcon = [OANativeUtilities skImageFromCGImage:[locIcon headingIconWithColor:iconColor].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationHeadingIconKeyDay,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationHeadingIcon scaleFactor:_textScaleFactor]));
        c.locationMarkerDay = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
        
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.courseMainIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        sk_sp<SkImage> courseMainIcon = [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:iconColor].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.courseMainIconKeyDay,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:courseMainIcon scaleFactor:_textScaleFactor]));
        c.courseMarkerDay = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
        
        // Night
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.locationMainIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        sk_sp<SkImage> locationMainNightIcon = [OANativeUtilities skImageFromCGImage:[locIcon iconWithColor:iconColor].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyNight,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationMainNightIcon scaleFactor:_textScaleFactor]));
        c.locationHeadingIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
        sk_sp<SkImage> locationHeadingNightIcon = [OANativeUtilities skImageFromCGImage:[locIcon headingIconWithColor:iconColor].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationHeadingIconKeyNight,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationHeadingNightIcon scaleFactor:_textScaleFactor]));
        c.locationMarkerNight = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);

        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.courseMainIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        sk_sp<SkImage> courseMainNightIcon = [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:iconColor].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.courseMainIconKeyNight,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:courseMainNightIcon scaleFactor:_textScaleFactor]));
        c.courseMarkerNight = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);

        locationAndCourseMarkerBuilder.setIsAccuracyCircleSupported(false);

        // Lost (day)
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.locationMainIconKeyLostDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        sk_sp<SkImage> locationMainLostDayIcon = [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:UIColorFromRGB(location_icon_color_lost)].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyLostDay,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationMainLostDayIcon scaleFactor:_textScaleFactor]));
        c.locationMarkerLostDay = locationAndCourseMarkerBuilder.buildAndAddToCollection(c.markerCollection);
        
        // Lost (night)
        locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
        c.locationMainIconKeyLostNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
        sk_sp<SkImage> locationMainLostNightIcon = [OANativeUtilities skImageFromCGImage:[navIcon iconWithColor:UIColorFromRGB(location_icon_color_lost)].CGImage];
        locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(c.locationMainIconKeyLostNight,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationMainLostNightIcon scaleFactor:_textScaleFactor]));
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

    _textScaleFactor = [[OAAppSettings sharedManager].textSize get];

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

- (BOOL) updateLayer
{
    [super updateLayer];

    CGFloat textScaleFactor = [[OAAppSettings sharedManager].textSize get];
    if (_textScaleFactor != textScaleFactor)
    {
        _textScaleFactor = textScaleFactor;
        [self refreshMarkersCollection];
    }

    return YES;
}

- (void)refreshMarkersCollection
{
    [self.mapViewController runWithRenderSync:^{
        [self invalidateMarkersCollection];
        [self generateMarkersCollection];
        [self updateMyLocationCourseProvider];
    }];
}

- (void) onAvailableAppModesChanged
{
    [self refreshMarkersCollection];
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
                [self updateLocation:mode];
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

- (void) updateLocation:(OAApplicationMode *)mode
{
    if (!_initDone)
        return;

    OAMarkerCollection *c = [_modeMarkers objectForKey:mode];

    CLLocation *newLocation = _lastLocation;
    CLLocationDirection newHeading = _lastHeading;
    CLLocation *prevLocation = _prevLocation;

    // In case there's no known location, do nothing and hide all markers
    if (!newLocation)
    {
        [c hideMarkers];
        return;
    }

    const OsmAnd::PointI newTarget31 =
            OsmAnd::PointI(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                           OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

    float animationDuration = 0;
    if (OAAppSettings.sharedManager.animateMyLocation.get && prevLocation && ![OAMapViewTrackingUtilities isSmallSpeedForAnimation:_lastLocation])
    {
        animationDuration = [newLocation.timestamp timeIntervalSinceDate:prevLocation.timestamp];
        if (animationDuration > 5)
            animationDuration = 0;
    }

    [self updateCollectionLocation:c newLocation:newLocation newTarget31:newTarget31 newHeading:newHeading animationDuration:animationDuration visible:YES];

    for (OAMarkerCollection *mc in _modeMarkers.objectEnumerator)
        if (mc != c)
            [self updateCollectionLocation:mc newLocation:newLocation newTarget31:newTarget31 newHeading:newHeading animationDuration:0 visible:NO];
}

- (void) updateCollectionLocation:(OAMarkerCollection *)c newLocation:(CLLocation *)newLocation newTarget31:(OsmAnd::PointI)newTarget31 newHeading:(CLLocationDirection)newHeading animationDuration:(float)animationDuration visible:(BOOL)visible
{
    if (newLocation.course >= 0)
    {
        c.state = OAMarkerColletionStateMove;
        [c updateLocation:newTarget31 animationDuration:animationDuration horizontalAccuracy:newLocation.horizontalAccuracy heading:newLocation.course - 90 visible:visible];
        [c updateOtherLocations:newTarget31 horizontalAccuracy:newLocation.horizontalAccuracy heading:newLocation.course - 90];
    }
    else //if (_mapViewTrackingUtilities.showViewAngle)
    {
        c.state = OAMarkerColletionStateStay;
        [c updateLocation:newTarget31 animationDuration:animationDuration horizontalAccuracy:newLocation.horizontalAccuracy heading:newHeading visible:visible];
        [c updateOtherLocations:newTarget31 horizontalAccuracy:newLocation.horizontalAccuracy heading:newHeading];
    }
}

- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading
{
    _prevLocation = _lastLocation;
    _lastLocation = newLocation;
    _lastHeading = newHeading;
    
    if (!_initDone)
        return;
    
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
    [self updateLocation:mode];
}

- (CLLocationCoordinate2D) getActiveMarkerLocation
{
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
    OAMarkerCollection *c = [_modeMarkers objectForKey:currentMode];
    auto position31 = [c getPosition];
    if (position31.x == 0 && position31.y == 0)
        return kCLLocationCoordinate2DInvalid;

    auto latLon = OsmAnd::Utilities::convert31ToLatLon(position31);
    return CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
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
