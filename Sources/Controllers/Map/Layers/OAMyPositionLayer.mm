//
//  OAMyPositionLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMyPositionLayer.h"
#import "OAMyPositionLayerState.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapStyleSettings.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAMapLayers.h"
#import "OARouteLayer.h"
#import "OATargetPoint.h"
#import "Localization.h"
#import "OALocationIcon.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "OAObservable.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OAModel3dHelper+cpp.h"
#import "OAPointDescription.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/SingleSkImage.h>

static float kRotateAnimationTime = 1.0f;
static int MODEL_3D_MAX_SIZE_DP = 6;
static double BEARING_SPEED_THRESHOLD = 0.1;

typedef enum {

    OAMarkerColletionModeUndefined = 0,
    OAMarkerColletionModeDay,
    OAMarkerColletionModeNight,
    
} EOAMarkerCollectionMode;

@interface OAMarkerCollection : NSObject

@property (nonatomic) EOAMarkerCollectionMode mode;
@property (nonatomic) EOAMarkerState currentMarkerState;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarkersCollection> markerCollection;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationHeadingIconKeyDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> locationMarkerNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationMainIconKeyNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey locationHeadingIconKeyNight;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> courseMarkerDay;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey courseMainIconKeyDay;

@property (nonatomic, assign) std::shared_ptr<OsmAnd::MapMarker> courseMarkerNight;
@property (nonatomic) OsmAnd::MapMarker::OnSurfaceIconKey courseMainIconKeyNight;

@property (nonatomic) int baseOrder;

- (instancetype) initWithMapView:(OAMapRendererView *)mapView;

- (void) hideMarkers;
- (void) updateLocation:(OsmAnd::PointI)target31 animationDuration:(float)animationDuration horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy heading:(CLLocationDirection)heading visible:(BOOL)visible;
- (OsmAnd::PointI) getPosition;

@end

@implementation OAMarkerCollection
{
    OAMapRendererView *_mapView;
    BOOL _showHeadingCached;
    float _locationIconScaleFactor;
}

- (instancetype) initWithMapView:(OAMapRendererView *)mapView
{
    self = [super init];
    if (self)
    {
        _mapView = mapView;
        _currentMarkerState = EOAMarkerStateNone;
    }
    return self;
}

- (void) hideMarkers
{
    _locationMarkerDay->setIsHidden(true);
    _locationMarkerDay->setIsAccuracyCircleVisible(false);
    _locationMarkerNight->setIsHidden(true);
    _locationMarkerNight->setIsAccuracyCircleVisible(false);
    _courseMarkerDay->setIsHidden(true);
    _courseMarkerDay->setIsAccuracyCircleVisible(false);
    _courseMarkerNight->setIsHidden(true);
    _courseMarkerNight->setIsAccuracyCircleVisible(false);
    
    executeOnMainThread(^{
        [OARootViewController.instance.mapPanel.mapViewController.mapLayers.myPositionLayer setMyLocationCircleRadius:(0.0f)];
    });
}

- (void) setCurrentMarkerState:(EOAMarkerState)state showHeading:(BOOL)showHeading locationIconScaleFactor:(float)locationIconScaleFactor
{
    _locationIconScaleFactor = locationIconScaleFactor;
    if (_currentMarkerState != state || showHeading != _showHeadingCached)
    {
        _currentMarkerState = state;
        [self updateState:showHeading];
        _showHeadingCached = showHeading;
    }
}

- (void) setMode:(EOAMarkerCollectionMode)mode
{
    if (_mode != mode)
    {
        _mode = mode;
        [self updateState:_showHeadingCached];
    }
}

- (void) updateState:(BOOL)showHeading
{
    auto circleColor = OsmAnd::FColorRGB();
    auto circleLocation31 = OsmAnd::PointI();
    float circleRadius = 0.0f;
    bool withCircle = false;
    
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
    float sectorDirection = 0.0f;
    float sectorRadius = 0.0f;
    
    switch (_currentMarkerState)
    {
        case EOAMarkerStateMove:
        {
            _locationMarkerDay->setIsHidden(true);
            _locationMarkerNight->setIsHidden(true);
            
            _courseMarkerDay->setIsHidden(_mode != OAMarkerColletionModeDay);
            _courseMarkerNight->setIsHidden(_mode != OAMarkerColletionModeNight);
            
            if (_mode == OAMarkerColletionModeDay)
            {
                circleColor = [[[currentMode getProfileColor] light] toFColorRGB];
                circleLocation31 = _courseMarkerDay->getPosition();
                circleRadius = _courseMarkerDay->getAccuracyCircleRadius();
                withCircle = true;
            }
            else if (_mode == OAMarkerColletionModeNight)
            {
                circleColor = [[[currentMode getProfileColor] dark] toFColorRGB];
                circleLocation31 = _courseMarkerNight->getPosition();
                circleRadius = _courseMarkerNight->getAccuracyCircleRadius();
                withCircle = true;
            }
            if (showHeading)
                sectorRadius = [self getSizeOfMarker:_courseMarkerNight icon:_locationHeadingIconKeyNight];
            break;
        }
        case EOAMarkerStateStay:
        {
            _courseMarkerDay->setIsHidden(true);
            _courseMarkerNight->setIsHidden(true);
            
            _locationMarkerDay->setIsHidden(_mode != OAMarkerColletionModeDay);
            _locationMarkerNight->setIsHidden(_mode != OAMarkerColletionModeNight);
            
            if (_mode == OAMarkerColletionModeDay)
            {
                circleColor = [[[currentMode getProfileColor] light] toFColorRGB];
                circleLocation31 = _locationMarkerDay->getPosition();
                circleRadius = _locationMarkerDay->getAccuracyCircleRadius();
                withCircle = true;
                sectorDirection = showHeading ? _locationMarkerDay->getOnMapSurfaceIconDirection(_locationHeadingIconKeyDay) : 0;
                if (showHeading)
                    sectorRadius = [self getSizeOfMarker:_locationMarkerDay icon:_locationHeadingIconKeyDay];
            }
            else if (_mode == OAMarkerColletionModeNight)
            {
                circleColor = [[[currentMode getProfileColor] dark] toFColorRGB];
                circleLocation31 = _locationMarkerNight->getPosition();
                circleRadius = _locationMarkerNight->getAccuracyCircleRadius();
                withCircle = true;
                sectorDirection = showHeading ? _locationMarkerNight->getOnMapSurfaceIconDirection(_locationHeadingIconKeyNight) : 0;
                if (showHeading)
                    sectorRadius = [self getSizeOfMarker:_locationMarkerNight icon:_locationHeadingIconKeyNight];
            }
            break;
        }
        default:
        {
            _courseMarkerDay->setIsHidden(true);
            _courseMarkerNight->setIsHidden(true);
            _locationMarkerDay->setIsHidden(true);
            _locationMarkerNight->setIsHidden(true);
            break;
        }
    }
    if (withCircle)
    {
        [_mapView setMyLocationCircleColor:(circleColor.withAlpha(0.2f))];
        [_mapView setMyLocationCirclePosition:(circleLocation31)];
        executeOnMainThread(^{
            [OARootViewController.instance.mapPanel.mapViewController.mapLayers.myPositionLayer setMyLocationCircleRadius:(circleRadius)];
        });
        [_mapView setMyLocationSectorDirection:(sectorDirection)];
        [_mapView setMyLocationSectorRadius:(sectorRadius * _locationIconScaleFactor)];
    }
    else
    {
        executeOnMainThread(^{
            [OARootViewController.instance.mapPanel.mapViewController.mapLayers.myPositionLayer setMyLocationCircleRadius:(0.0f)];
        });
        [_mapView setMyLocationSectorRadius:(0.0f)];
    }
}

- (int) getSizeOfMarker:(std::shared_ptr<OsmAnd::MapMarker>)marker icon:(OsmAnd::MapMarker::OnSurfaceIconKey)icon
{
    sk_sp<const SkImage> surfaceIcon = marker->onMapSurfaceIcons[icon];
    if (surfaceIcon != nullptr)
        return int(MAX(surfaceIcon->width(), surfaceIcon->height()) / 2);
    return 76;
}

- (void) updateLocation:(OsmAnd::PointI)target31 animationDuration:(float)animationDuration horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy bearing:(CLLocationDirection)bearing heading:(CLLocationDirection)heading visible:(BOOL)visible
{
    std::shared_ptr<OsmAnd::MapMarker> marker = [self getActiveMarker];
    OsmAnd::MapMarker::OnSurfaceIconKey iconKey = [self getActiveIconKey];
    if (marker)
    {
        marker->setIsAccuracyCircleVisible(true);
        marker->setAccuracyCircleRadius(horizontalAccuracy);
        executeOnMainThread(^{
            [OARootViewController.instance.mapPanel.mapViewController.mapLayers.myPositionLayer setMyLocationCircleRadius:(horizontalAccuracy)];
        });

        _mapView.mapMarkersAnimator->cancelAnimations(marker);
        if (animationDuration > 0)
        {
            _mapView.mapMarkersAnimator->animatePositionTo(marker, target31, animationDuration,  OsmAnd::Animator::TimingFunction::Linear);
            if (marker->model3D != nullptr)
            {
                _mapView.mapMarkersAnimator->animateModel3DDirectionTo(marker, OsmAnd::Utilities::normalizedAngleDegrees(bearing), kRotateAnimationTime, OsmAnd::Animator::TimingFunction::Linear);
                [_mapView setMyLocationSectorDirection:(OsmAnd::Utilities::normalizedAngleDegrees(heading))];
            }
            else
            {
                if (iconKey)
                    _mapView.mapMarkersAnimator->animateDirectionTo(marker, iconKey, OsmAnd::Utilities::normalizedAngleDegrees(bearing), kRotateAnimationTime,  OsmAnd::Animator::TimingFunction::Linear);
            }
        }
        else
        {
            marker->setPosition(target31);
            [_mapView setMyLocationCirclePosition:(target31)];

            if (marker->model3D != nullptr)
            {
                marker->setModel3DDirection(OsmAnd::Utilities::normalizedAngleDegrees(bearing));
                [_mapView setMyLocationSectorDirection:(OsmAnd::Utilities::normalizedAngleDegrees(heading))];
            }
            else
            {
                if (iconKey)
                    marker->setOnMapSurfaceIconDirection(iconKey, OsmAnd::Utilities::normalizedAngleDegrees(bearing));
            }
        }

        if (visible && marker->isHidden())
            marker->setIsHidden(false);
    }
}

- (void) updateOtherLocations:(OsmAnd::PointI)target31 horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy bearing:(CLLocationDirection)bearing heading:(CLLocationDirection)heading
{
    std::shared_ptr<OsmAnd::MapMarker> marker = [self getActiveMarker];

    if (marker != _courseMarkerDay)
    {
        _courseMarkerDay->setPosition(target31);
        if (_courseMainIconKeyDay)
            _courseMarkerDay->setOnMapSurfaceIconDirection(_courseMainIconKeyDay, OsmAnd::Utilities::normalizedAngleDegrees(bearing));
        if (_courseMarkerDay->model3D != nullptr)
            _courseMarkerDay->setModel3DDirection(OsmAnd::Utilities::normalizedAngleDegrees(bearing));

    }
    if (marker != _courseMarkerNight)
    {
        _courseMarkerNight->setPosition(target31);
        if (_courseMainIconKeyNight)
            _courseMarkerNight->setOnMapSurfaceIconDirection(_courseMainIconKeyNight, OsmAnd::Utilities::normalizedAngleDegrees(bearing));
        if (_courseMarkerNight->model3D != nullptr)
            _courseMarkerNight->setModel3DDirection(OsmAnd::Utilities::normalizedAngleDegrees(bearing));
    }

    if (marker != _locationMarkerDay)
    {
        _locationMarkerDay->setPosition(target31);
        if (_locationHeadingIconKeyDay)
            _locationMarkerDay->setOnMapSurfaceIconDirection(_locationHeadingIconKeyDay, OsmAnd::Utilities::normalizedAngleDegrees(heading));
        if (_locationMarkerDay->model3D != nullptr)
            _locationMarkerDay->setModel3DDirection(OsmAnd::Utilities::normalizedAngleDegrees(bearing));
    }
    if (marker != _locationMarkerNight)
    {
        _locationMarkerNight->setPosition(target31);
        if (_locationHeadingIconKeyNight)
            _locationMarkerNight->setOnMapSurfaceIconDirection(_locationHeadingIconKeyNight, OsmAnd::Utilities::normalizedAngleDegrees(heading));
        if (_locationMarkerNight->model3D != nullptr)
            _locationMarkerNight->setModel3DDirection(OsmAnd::Utilities::normalizedAngleDegrees(bearing));
    }
}

- (std::shared_ptr<OsmAnd::MapMarker>) getActiveMarker
{
    switch (_currentMarkerState)
    {
        case EOAMarkerStateMove:
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
    switch (_currentMarkerState)
    {
        case EOAMarkerStateMove:
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
    return marker ? marker->getPosition() : OsmAnd::PointI();
}
@end

@implementation OAMyPositionLayer
{
    OAMapViewTrackingUtilities *_mapViewTrackingUtilities;
    OALocationServices *_locationProvider;
    
    NSMapTable<OAApplicationMode *, OAMarkerCollection *> *_modeMarkers;
    OAMarkerCollection *_previewMarker;
    CLLocation *_lastLocation;
    CLLocationDirection _lastHeading;
    CLLocationDirection _lastCourse;
    CLLocation *_prevLocation;
    float _locationIconScaleFactor;
    float _courseIconScaleFactor;
    
    EOAMarkerState _currentMarkerState;

    OAAutoObserverProxy* _appModeChangedObserver;
    OAAutoObserverProxy* _availableAppModesChangedObserver;
    OAAutoObserverProxy* _mapSettingsChangeObserver;

    BOOL _initDone;
}

- (void)generateMarkersCollection
{
    [self generateMarkersCollectionWithLocationFactor:_locationIconScaleFactor courseFactor:_courseIconScaleFactor];
}

- (void)generateMarkersCollectionWithLocationFactor:(float)locationFactor courseFactor:(float)courseFactor
{
    // Create location and course markers
    int baseOrder = self.pointsOrder;
    
    _modeMarkers = [NSMapTable strongToStrongObjectsMapTable];
    NSArray<OAApplicationMode *> *modes = [OAApplicationMode allPossibleValues];
    for (OAApplicationMode *mode in modes)
    {
        int order = baseOrder--;
        [self generateMarkerCollectionFor:mode baseOrder:order locationIconScaleFactor:locationFactor courseIconScaleFactor:courseFactor];
    }
}

- (void)generateMarkerCollectionFor:(OAApplicationMode *)mode baseOrder:(int)baseOrder
{
    [self generateMarkerCollectionFor:mode baseOrder:baseOrder locationIconScaleFactor:_locationIconScaleFactor courseIconScaleFactor:_courseIconScaleFactor];
}

- (void)generateMarkerCollectionFor:(OAApplicationMode *)mode baseOrder:(int)baseOrder locationIconScaleFactor:(float)locationIconScaleFactor courseIconScaleFactor:(float)courseIconScaleFactor
{
    OAMarkerCollection *collection = [self getMarkerCollectionFor:mode baseOrder:baseOrder locationIconScaleFactor:locationIconScaleFactor courseIconScaleFactor:courseIconScaleFactor];
    [_modeMarkers setObject:collection forKey:mode];
}

- (void)generatePreviewMarkerCollectionFor:(float)locationIconScaleFactor courseIconScaleFactor:(float)courseIconScaleFactor
{
    int baseOrder = self.pointsOrder;
    OAApplicationMode *mode = [[OAAppSettings sharedManager].applicationMode get];
    _previewMarker = [self getMarkerCollectionFor:mode baseOrder:baseOrder locationIconScaleFactor:locationIconScaleFactor courseIconScaleFactor:courseIconScaleFactor];
}

- (OAMarkerCollection *)getMarkerCollectionFor:(OAApplicationMode *)mode baseOrder:(int)baseOrder locationIconScaleFactor:(float)locationIconScaleFactor courseIconScaleFactor:(float)courseIconScaleFactor
{
    OAMarkerCollection *collection = [[OAMarkerCollection alloc] initWithMapView:self.mapView];
    collection.baseOrder = baseOrder;

    collection.markerCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    collection.markerCollection->setPriority(std::numeric_limits<int64_t>::max());
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;

    OsmAnd::MapMarkerBuilder locationMarkerBuilder;

    locationMarkerBuilder.setIsAccuracyCircleSupported(true);
    locationMarkerBuilder.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationMarkerBuilder.setBaseOrder(baseOrder);
    locationMarkerBuilder.setIsHidden(true);
    locationMarkerBuilder.setModel3DMaxSizeInPixels(int(MODEL_3D_MAX_SIZE_DP * locationIconScaleFactor * [[UIScreen mainScreen] scale]));
    
    OsmAnd::MapMarkerBuilder courseMarkerBuilder;

    courseMarkerBuilder.setIsAccuracyCircleSupported(true);
    courseMarkerBuilder.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    courseMarkerBuilder.setBaseOrder(baseOrder);
    courseMarkerBuilder.setIsHidden(true);
    courseMarkerBuilder.setModel3DMaxSizeInPixels(int(MODEL_3D_MAX_SIZE_DP * courseIconScaleFactor * [[UIScreen mainScreen] scale]));
    
    UIColor *iconColor = [mode getProfileColor];
    
    NSString *locationIconName = [mode.getLocationIcon name];
    NSString *navigationIconName = [mode.getNavigationIcon name];
    
    OAModel3dWrapper *navigationModel;
    OAModel3dWrapper *locationModel;
    std::shared_ptr<const OsmAnd::Model3D> navigationModelCpp;
    std::shared_ptr<const OsmAnd::Model3D> locationModelCpp;

    OALocationIcon *navIcon = [OALocationIcon locationIconWithName:navigationIconName];
    navigationIconName = [navIcon iconName];
    if ([navIcon shouldDisplayModel])
    {
        navigationModel = [Model3dHelper.shared getModelWithModelName:[navIcon modelName] callback:nil];
        if (!navigationModel)
        {
            navIcon = [OALocationIcon MOVEMENT_DEFAULT];
            navigationIconName = [navIcon iconName];
        }
    }
    
    OALocationIcon *locIcon = [OALocationIcon locationIconWithName:locationIconName];
    locationIconName = [locIcon iconName];
    if ([locIcon shouldDisplayModel])
    {
        locationModel = [Model3dHelper.shared getModelWithModelName:[locIcon modelName] callback:nil];
        if (!locationModel)
        {
            locIcon = [OALocationIcon DEFAULT];
            locationIconName = [locIcon iconName];
        }
    }
            
    if (navigationModel)
    {
        if (mode == currentMode)
            [navigationModel setMainColor:iconColor];
        navigationModelCpp = [navigationModel model];
    }
    if (locationModel)
    {
        if (mode == currentMode)
            [locationModel setMainColor:iconColor];
        locationModelCpp = [locationModel model];
    }
    
    // Day
    collection.locationMainIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    collection.locationHeadingIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
    if (locationModel)
    {
        locationMarkerBuilder.setModel3D(locationModelCpp);
    }
    else
    {
        sk_sp<SkImage> locationMainIcon = [OANativeUtilities skImageFromCGImage:[locIcon getMapIcon:iconColor].CGImage];
        locationMarkerBuilder.addOnMapSurfaceIcon(collection.locationMainIconKeyDay,
                                                  OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationMainIcon scaleFactor:locationIconScaleFactor]));

        sk_sp<SkImage> locationHeadingIcon = [OANativeUtilities skImageFromCGImage:[locIcon getHeadingIconWithColor:iconColor].CGImage];
        locationMarkerBuilder.addOnMapSurfaceIcon(collection.locationHeadingIconKeyDay,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationHeadingIcon scaleFactor:locationIconScaleFactor]));
    }
    collection.locationMarkerDay = locationMarkerBuilder.buildAndAddToCollection(collection.markerCollection);

    collection.courseMainIconKeyDay = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    if (navigationModel)
    {
        courseMarkerBuilder.setModel3D(navigationModelCpp);
    }
    else
    {
        sk_sp<SkImage> courseMainIcon = [OANativeUtilities skImageFromCGImage:[navIcon getMapIcon:iconColor].CGImage];
        courseMarkerBuilder.addOnMapSurfaceIcon(collection.courseMainIconKeyDay,
                                                OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:courseMainIcon scaleFactor:courseIconScaleFactor]));
    }
    collection.courseMarkerDay = courseMarkerBuilder.buildAndAddToCollection(collection.markerCollection);
    
    // Night
    locationMarkerBuilder.clearOnMapSurfaceIcons();
    collection.locationMainIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    collection.locationHeadingIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(2);
    if (locationModel)
    {
        locationMarkerBuilder.setModel3D(locationModelCpp);
    }
    else
    {
        sk_sp<SkImage> locationMainNightIcon = [OANativeUtilities skImageFromCGImage:[locIcon getMapIcon:iconColor].CGImage];
        locationMarkerBuilder.addOnMapSurfaceIcon(collection.locationMainIconKeyNight,
                                                  OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationMainNightIcon scaleFactor:locationIconScaleFactor]));
        
        sk_sp<SkImage> locationHeadingNightIcon = [OANativeUtilities skImageFromCGImage:[locIcon getHeadingIconWithColor :iconColor].CGImage];
        locationMarkerBuilder.addOnMapSurfaceIcon(collection.locationHeadingIconKeyNight,
                                                           OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:locationHeadingNightIcon scaleFactor:locationIconScaleFactor]));
    }
    collection.locationMarkerNight = locationMarkerBuilder.buildAndAddToCollection(collection.markerCollection);

    courseMarkerBuilder.clearOnMapSurfaceIcons();
    collection.courseMainIconKeyNight = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    if (navigationModel)
    {
        courseMarkerBuilder.setModel3D(navigationModelCpp);
    }
    else
    {
        sk_sp<SkImage> courseMainNightIcon = [OANativeUtilities skImageFromCGImage:[navIcon getMapIcon:iconColor].CGImage];
        courseMarkerBuilder.addOnMapSurfaceIcon(collection.courseMainIconKeyNight,
                                                OsmAnd::SingleSkImage([OANativeUtilities getScaledSkImage:courseMainNightIcon scaleFactor:courseIconScaleFactor]));
    }
    collection.courseMarkerNight = courseMarkerBuilder.buildAndAddToCollection(collection.markerCollection);

    locationMarkerBuilder.setIsAccuracyCircleSupported(false);
    courseMarkerBuilder.setIsAccuracyCircleSupported(false);
    
    [self updateMode:collection];
    return collection;
}

- (NSString *) layerId
{
    return kMyPositionLayerId;
}

- (void) initLayer
{
    _lastCourse = -1.0;
    
    _mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
    _locationProvider = OsmAndApp.instance.locationServices;
    
    _appModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onAppModeChanged)
                                                          andObserve:[OsmAndApp instance].applicationModeChangedObservable];
    
    _availableAppModesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onAvailableAppModesChanged)
                                                        andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
    
    _mapSettingsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onSettingsChanged)
                                                        andObserve:[OsmAndApp instance].mapSettingsChangeObservable];

    _locationIconScaleFactor = [[OAAppSettings sharedManager].locationIconSize get];
    _courseIconScaleFactor = [[OAAppSettings sharedManager].courseIconSize get];
    
    __weak OAMyPositionLayer *weakSelf = self;
    [Model3dHelper.shared loadAllModelsWithCallback:
         [[OAModel3dCallback alloc] initWithCallback:^(OAModel3dWrapper * _Nullable model) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf refreshMarkersCollection];
            });
        }]
    ];
    
    _currentMarkerState = EOAMarkerStateStay;

    [self generateMarkersCollection];
    
    _initDone = YES;
    
    // Add "My location" and "My course" markers
    [self updateMyLocationCourseProvider];
}

- (void) deinitLayer
{
    [_availableAppModesChangedObserver detach];
    _availableAppModesChangedObserver = nil;
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    CGFloat locationIconScaleFactor = [[OAAppSettings sharedManager].locationIconSize get];
    CGFloat courseIconScaleFactor = [[OAAppSettings sharedManager].courseIconSize get];
    if (_locationIconScaleFactor != locationIconScaleFactor || _courseIconScaleFactor != courseIconScaleFactor)
    {
        _locationIconScaleFactor = locationIconScaleFactor;
        _courseIconScaleFactor = courseIconScaleFactor;
        [self refreshMarkersCollection];
    }

    return YES;
}

- (void) refreshMarkersCollection
{
    [self.mapViewController runWithRenderSync:^{
        [self invalidateMarkersCollection];
        [self generateMarkersCollection];
        [self updateMyLocationCourseProvider];
    }];
}

- (void) refreshMarkersCollectionForMode:(OAApplicationMode *)mode
{
    [self.mapViewController runWithRenderSync:^{
        [self invalidateMarkersCollectionForMode:mode];
        OAMarkerCollection *c = [_modeMarkers objectForKey:mode];
        [self generateMarkerCollectionFor:mode baseOrder:c.baseOrder];
        [self updateMarkersCollectionProviderForMode:mode];
    }];
}

- (void)updatePreviewMarker:(CLLocation *)newLocation locationFactor:(float)locationFactor courseFactor:(float)courseFactor showBearing:(BOOL)showBearing
{
    [self.mapViewController runWithRenderSync:^{
        [self hidePreviewMarker];
        [self generatePreviewMarkerCollectionFor:locationFactor courseIconScaleFactor:courseFactor];
        [self updateMyPreviewLocationCourseProviderFor:showBearing newLocation:newLocation];
        [self.mapView invalidateFrame];
    }];
}

- (void) onSettingsChanged
{
    __weak OAMyPositionLayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf refreshMarkersCollection];
    });
}

- (void) onAppModeChanged
{
    __weak OAMyPositionLayer *weakSelf = self;
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf refreshMarkersCollectionForMode:currentMode];
    });
}

- (void) onAvailableAppModesChanged
{
    __weak OAMyPositionLayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf refreshMarkersCollection];
    });
}

- (void) invalidateMarkersCollection
{
    NSArray *modesCopy = [_modeMarkers.keyEnumerator allObjects];
    for (OAApplicationMode *mode in modesCopy)
    {
        [self invalidateMarkersCollectionForMode:mode];
    }
}

- (void)hidePreviewMarker
{
    OAMarkerCollection *collection = _previewMarker;
    [collection hideMarkers];
    [self.mapView removeKeyedSymbolsProvider:collection.markerCollection];
}

- (void) invalidateMarkersCollectionForMode:(OAApplicationMode *)mode
{
    OAMarkerCollection *c = [_modeMarkers objectForKey:mode];
    [c hideMarkers];
    [self.mapView removeKeyedSymbolsProvider:c.markerCollection];
}

- (void) updateMyLocationCourseProvider
{
    if (!_initDone)
        return;
    
    NSArray *modesCopy = [_modeMarkers.keyEnumerator allObjects];
    
    for (OAApplicationMode *mode in modesCopy)
    {
        [self updateMarkersCollectionProviderForMode:mode];
    }
}

- (void) updateMarkersCollectionProviderForMode:(OAApplicationMode *)mode
{
    [self.mapViewController runWithRenderSync:^{
    
        OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
        
        OAMarkerCollection *c = [_modeMarkers objectForKey:mode];
        if (mode == currentMode)
        {
            [self updateLocation:currentMode];
            [self.mapView addKeyedSymbolsProvider:c.markerCollection];
        }
        else
        {
            [c hideMarkers];
            [self.mapView removeKeyedSymbolsProvider:c.markerCollection];
        }
    }];
}

- (void)updateMyPreviewLocationCourseProviderFor:(BOOL)showBearing newLocation:(CLLocation *)newLocation
{
    [self.mapViewController runWithRenderSync:^{
        OAMarkerCollection *collection = _previewMarker;
        [self updatePreviewLocation:showBearing newLocation:newLocation];
        [self.mapView addKeyedSymbolsProvider:collection.markerCollection];
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

- (void)updatePreviewLocation:(BOOL)showBearing newLocation:(CLLocation *)newLocation
{
    OAMarkerCollection *collection = _previewMarker;
    
    CLLocationDirection newHeading = newLocation.course;
    
    const OsmAnd::PointI newTarget31 =
            OsmAnd::PointI(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                           OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
    
    [self updateCollectionLocation:collection newLocation:newLocation newTarget31:newTarget31 newHeading:newHeading animationDuration:0 visible:YES showBearing:showBearing showHeading:NO pointCourse:newHeading];
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
    if (OAAppSettings.sharedManager.animateMyLocation.get && prevLocation
        && ![OAMapUtils areLatLonEqual:newLocation.coordinate coordinate2:prevLocation.coordinate precision:0.000001])
    {
        animationDuration = [newLocation.timestamp timeIntervalSinceDate:prevLocation.timestamp];
        if (animationDuration > 5)
            animationDuration = 0;
    }

    [self updateCollectionLocation:c newLocation:newLocation newTarget31:newTarget31 newHeading:newHeading animationDuration:animationDuration visible:YES];
    _currentMarkerState = c.currentMarkerState;
    for (OAMarkerCollection *mc in _modeMarkers.objectEnumerator)
        if (mc != c)
            [self updateCollectionLocation:mc newLocation:newLocation newTarget31:newTarget31 newHeading:newHeading animationDuration:animationDuration visible:NO];
}

- (void) updateCollectionLocation:(OAMarkerCollection *)c newLocation:(CLLocation *)newLocation newTarget31:(OsmAnd::PointI)newTarget31 newHeading:(CLLocationDirection)newHeading animationDuration:(float)animationDuration visible:(BOOL)visible
{
    BOOL showHeading = [self shouldShowHeading];
    BOOL showBearing = [self shouldShowBearing:newLocation];
    
    double pointCourse = [self getPointCourse];
    
    [self updateCollectionLocation:c newLocation:newLocation newTarget31:newTarget31 newHeading:newHeading animationDuration:animationDuration visible:visible showBearing:showBearing showHeading:showHeading pointCourse:pointCourse];
}

- (void)updateCollectionLocation:(OAMarkerCollection *)collection newLocation:(CLLocation *)newLocation newTarget31:(OsmAnd::PointI)newTarget31 newHeading:(CLLocationDirection)newHeading animationDuration:(float)animationDuration visible:(BOOL)visible showBearing:(BOOL)showBearing showHeading:(BOOL)showHeading pointCourse:(double)pointCourse
{
    double bearing = (pointCourse < 0 ? newHeading : pointCourse) - 90;
    
    [collection setCurrentMarkerState:showBearing ? EOAMarkerStateMove : EOAMarkerStateStay showHeading:showHeading locationIconScaleFactor:_locationIconScaleFactor];
    [collection updateLocation:newTarget31 animationDuration:animationDuration horizontalAccuracy:newLocation.horizontalAccuracy bearing:bearing heading:newHeading visible:visible];
    [collection updateOtherLocations:newTarget31 horizontalAccuracy:newLocation.horizontalAccuracy bearing:bearing heading:newHeading];
}

- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading
{
    _prevLocation = _lastLocation;
    _lastLocation = newLocation;
    _lastHeading = newHeading;
    if (newLocation.course >= 0)
        _lastCourse = newLocation.course;

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

- (BOOL) isLocationSnappedToRoad
{
    CLLocation *projection = self.mapViewController.mapLayers.routeMapLayer.lastProj;
    return OAAppSettings.sharedManager.snapToRoad.get && [projection isEqual:[self getPointLocation]];
}

- (void) setMyLocationCircleRadius:(float)radiusInMeters
{
    OAMapRendererView *mapView = OARootViewController.instance.mapPanel.mapViewController.mapView;
    [mapView setMyLocationCircleRadius:[self shouldShowLocationRadius] ? radiusInMeters : 0];
}

- (BOOL) shouldShowHeading
{
    int rawVisibilitySetting = OAAppSettings.sharedManager.viewAngleVisibility.get;
    MarkerDisplayOption displayOption = [MarkerDisplayOptionWrapper valueBy:rawVisibilitySetting];
    BOOL isVisible = [MarkerDisplayOptionWrapper isVisibleWithType:displayOption state:_currentMarkerState];
    return _mapViewTrackingUtilities.showViewAngle && !self.isLocationSnappedToRoad && isVisible;
}

- (BOOL) shouldShowLocationRadius
{
    int rawVisibilitySetting = OAAppSettings.sharedManager.locationRadiusVisibility.get;
    MarkerDisplayOption displayOption = [MarkerDisplayOptionWrapper valueBy:rawVisibilitySetting];
    BOOL isVisible = [MarkerDisplayOptionWrapper isVisibleWithType:displayOption state:_currentMarkerState];
    return !self.isLocationSnappedToRoad && isVisible;
}

- (BOOL) shouldShowBearing:(CLLocation *)location
{
    return [self getBearingToShow:location] >= 0;
}

- (CLLocation *) getPointLocation
{
    CLLocation *location = nil;
    if (OARoutingHelper.sharedInstance.isFollowingMode && OAAppSettings.sharedManager.snapToRoad.get)
        location = self.mapViewController.mapLayers.routeMapLayer.lastProj;

    return location ? location : self.app.locationServices.lastKnownLocation;
}

- (double) getBearingToShow:(CLLocation *)location
{
    if (location)
    {
        BOOL hasCourse = location.course > 0.0;
        BOOL courseValid = hasCourse || (self.isUseRouting && _lastCourse >= 0.0);
        BOOL speedValid = location.speed < 0 || location.speed > BEARING_SPEED_THRESHOLD;
        if (courseValid && (speedValid || self.isLocationSnappedToRoad))
            return hasCourse ? location.course : _lastCourse;
    }
    return -1.0;
}

- (BOOL) isUseRouting
{
    OARoutingHelper *routingHelper = OARoutingHelper.sharedInstance;
    return routingHelper.isFollowingMode || routingHelper.isRoutePlanningMode
    	|| routingHelper.isRouteBeingCalculated || routingHelper.isRouteCalculated;
}

- (double) getPointCourse
{
    CLLocation *location = [self getPointLocation];
    return location && location.course >= 0 ? location.course : _lastCourse;
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

- (void) collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    CLLocation* myLocation = _lastLocation;
    if (!myLocation)
        return;
    
    if ([self.mapViewController getMapZoom] >= 3 && !excludeUntouchableObjects)
    {
        CGPoint point = result.point;
        int radius = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
        OsmAnd::AreaI touchPolygon31 = [OANativeUtilities getPolygon31FromPixelAndRadius:point radius:radius];
        if (touchPolygon31 == OsmAnd::AreaI())
            return;
        
        BOOL shouldAdd = [OANativeUtilities isPointInsidePolygon:myLocation.coordinate.latitude lon:myLocation.coordinate.longitude polygon31:touchPolygon31];
        if (shouldAdd)
            [result collect:myLocation provider:self];
    }
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OATargetPoint.class])
    {
        OATargetPoint *targetPoint = (OATargetPoint *)obj;
        return  [[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude];
    }
    else
    {
        return _lastLocation;
    }
    return nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_MY_LOCATION name:OALocalizedString(@"my_location")];
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t) getSelectionPointOrder:(id)selectedObject
{
    return 0;
}

@end
