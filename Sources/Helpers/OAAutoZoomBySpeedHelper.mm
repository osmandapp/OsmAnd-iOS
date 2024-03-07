//
//  OAAutoZoomBySpeedHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 14/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAAutoZoomBySpeedHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARouteDirectionInfo.h"
#import "OAMapRendererView.h"
#import "OAZoom.h"
#import "OARouteCalculationResult.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewTrackingUtilities.h"

const static int kShowDrivingSecondsV2 = 45;
const static float kMinAutoZoomSpeed = 7.0 / 3.6;

const static float kFocusPixelRatioX = 0.5;
const static float kFocusPixelRatioY = 1.0 / 3.0;


@interface OASpeedFilter : NSObject

- (float) getFilteredSpeed:(float)speed;

@end


@implementation OASpeedFilter
{
    float _speedToFilter;
    float _currentSpeed;
}

- (float) getFilteredSpeed:(float)speed
{
    float oldSpeed = _speedToFilter;
    _speedToFilter = _currentSpeed;
    _currentSpeed = speed;
    
    if (isnan(oldSpeed))
    {
        return _speedToFilter;
    }
    else
    {
        BOOL monotonous = (_currentSpeed >= _speedToFilter && _speedToFilter >= oldSpeed)
                                || (_currentSpeed <= _speedToFilter && _speedToFilter <= oldSpeed);
        return monotonous ? _speedToFilter : NAN;
    }
}

@end


@implementation OAAutoZoomDTO

- (instancetype) initWithZoom:(OAComplexZoom *)zoomValue floatValue:(float)floatValue
{
    self = [super init];
    if (self)
    {
        _zoomValue = zoomValue;
        _floatValue = floatValue;
    }
    return self;
}

@end



@implementation OAAutoZoomBySpeedHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASpeedFilter *_speedFilter;
    
    OARouteDirectionInfo *_nextTurnInFocus;
    
    OAAutoObserverProxy *_mapZoomObserver;
    
    //old vars
    NSTimeInterval _lastTimeAutoZooming;
    BOOL _isUserZoomed;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _speedFilter = [[OASpeedFilter alloc] init];
        
        _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onManualZoomChange) andObserve:OARootViewController.instance.mapPanel.mapViewController.zoomObservable];
    }
    return self;
}


//TODO: delete?

// previous version of autozoom code from OAMapViewTrackingUtilities
// without any changes. differs with android
- (double) calculateAutoZoomBySpeedV1:(float)speed mapView:(OAMapRendererView *)mapView
{
    if (speed >= 0)
    {
        NSTimeInterval now = CACurrentMediaTime();
        float zdelta = [self defineZoomFromSpeed:speed mapView:mapView];
        if (ABS(zdelta) >= 0.5/*?Math.sqrt(0.5)*/)
        {
            // prevent ui hysteresis (check time interval for autozoom)
            if (zdelta >= 2)
            {
                // decrease a bit
                zdelta -= 1;
            }
            else if (zdelta <= -2)
            {
                // decrease a bit
                zdelta += 1;
            }
            double targetZoom = MIN(mapView.zoom + zdelta, [OAAutoZoomMap getMaxZoom:[_settings.autoZoomMapScale get]]);
            int threshold = [_settings.autoFollowRoute get];
            if (now - _lastTimeAutoZooming > 4.5 && (now - _lastTimeAutoZooming > threshold || !_isUserZoomed))
            {
                _isUserZoomed = false;
                _lastTimeAutoZooming = now;
                targetZoom = round(targetZoom * 3) / 3.f;
                return targetZoom;
            }
        }
    }
    return 0;
}

//TODO: delete?

// previous version of autozoom code from OAMapViewTrackingUtilities
// without any changes. differs with android
- (float) defineZoomFromSpeed:(float)speed mapView:(OAMapRendererView *)mapView
{
    if (speed < 7.0 / 3.6)
        return 0;

    OsmAnd::AreaI bbox = [mapView getVisibleBBox31];
    double visibleDist = OsmAnd::Utilities::distance31(OsmAnd::PointI(bbox.left() + bbox.width() / 2, bbox.top()), bbox.center());
    float time = 75.f; // > 83 km/h show 75 seconds
    if (speed < 83.f / 3.6)
        time = 60.f;
    
    time /= [OAAutoZoomMap getCoefficient:[_settings.autoZoomMapScale get]];
    double distToSee = speed * time;
    float zoomDelta = (float) (log(visibleDist / distToSee) / log(2.0f));
    // check if 17, 18 is correct?
    return zoomDelta;
}


- (OAComplexZoom *) calculateZoomBySpeedToAnimate:(OAMapRendererView *)mapRenderer myLocation:(CLLocation *)myLocation rotationToAnimate:(float)rotationToAnimate nextTurn:(OANextDirectionInfo *)nextTurn
{
    float speed = myLocation.speed;
    if (speed < kMinAutoZoomSpeed)
        return nil;
    
    float filteredSpeed = [_speedFilter getFilteredSpeed:speed];
    if (isnan(filteredSpeed))
        return nil;
    
    EOAAutoZoomMap autoZoomScale = [_settings.autoZoomMapScale get];
    
    OsmAnd::LatLon myLocationLatLon = OsmAnd::LatLon(myLocation.coordinate.latitude, myLocation.coordinate.longitude);
    OsmAnd::PointI myLocation31 = [OANativeUtilities getPoint31FromLatLon:myLocationLatLon];
    float myLocationHeight = [OANativeUtilities getLocationHeightOrZero:myLocation31];
    OsmAnd::PointI myLocationPixel = mapRenderer.renderer->getState().fixedPixel;
    
    float showDistanceToDrive = [self getShowDistanceToDrive:autoZoomScale nextTurn:nextTurn speed:filteredSpeed];
    float rotation = !isnan(rotationToAnimate) ? rotationToAnimate : mapRenderer.azimuth;
    OsmAnd::LatLon anotherLatLon = OsmAnd::Utilities::rhumbDestinationPoint(myLocationLatLon, showDistanceToDrive, rotation);
    
    OsmAnd::PointI anotherLocation31 = [OANativeUtilities getPoint31FromLatLon:anotherLatLon];
    float anotherLocationHeight = [OANativeUtilities getLocationHeightOrZero:anotherLocation31];
    OsmAnd::PointI windowSize = mapRenderer.renderer->getState().windowSize;
    OsmAnd::PointI anotherPixel = [self getFocusPixel:windowSize.x pixHeight:windowSize.y];
    
    float expectedSurfaceZoom = mapRenderer.renderer->getSurfaceZoomAfterPinch(myLocation31, myLocationHeight, myLocationPixel, anotherLocation31, anotherLocationHeight, anotherPixel);
    if (expectedSurfaceZoom == -1)
        return nil;
    
    int minZoom = mapRenderer.minZoom;
    int maxZoom = mapRenderer.maxZoom;
    OAZoom *boundedZoom = [OAZoom checkZoomBoundsWithZoom:expectedSurfaceZoom minZoom:minZoom maxZoom:maxZoom];
    
    return [OAComplexZoom fromPreferredBase:[boundedZoom getBaseZoom] + [boundedZoom getZoomFloatPart]  preferredZoomBase:mapRenderer.zoom];
}

- (OAAutoZoomDTO *) getAnimatedZoomParamsForChart:(OAMapRendererView *)mapRenderer currentZoom:(float)currentZoom lat:(double)lat lon:(double)lon heading:(float)heading speed:(float)speed
{
    if (speed < kMinAutoZoomSpeed)
        return nil;
    
    float filteredSpeed = [_speedFilter getFilteredSpeed:speed];
    if (isnan(filteredSpeed))
        return nil;
    
    OAComplexZoom *autoZoom = [self calculateRawZoomBySpeedForChart:mapRenderer currentZoom:currentZoom lat:lat lon:lon rotation:heading speed:filteredSpeed];
    if (!autoZoom)
        return nil;
    
    return [self getAutoZoomParams:currentZoom autoZoom:autoZoom fixedDurationMillis:-1];
}

- (OAComplexZoom *) calculateRawZoomBySpeedForChart:(OAMapRendererView *)mapRenderer currentZoom:(float)currentZoom lat:(double)lat lon:(double)lon rotation:(float)rotation speed:(float)speed
{
    OsmAnd::MapRendererState state = mapRenderer.renderer->getState();
    EOAAutoZoomMap autoZoomScale = [_settings.autoZoomMapScale get];
    
    OsmAnd::PointI fixedLocation31 = [OANativeUtilities getPoint31FromLatLon:lat lon:lon];
    
    OsmAnd::PointI firstLocation31 = fixedLocation31;
    float firstHeightInMeters = [OANativeUtilities getLocationHeightOrZero:firstLocation31];
    OsmAnd::PointI firstPixel = state.fixedPixel;
    
    float showDistanceToDrive = [self getShowDistanceToDrive:autoZoomScale nextTurn:nil speed:speed];
    OsmAnd::LatLon secondLatLon = OsmAnd::Utilities::rhumbDestinationPoint(lat, lon, showDistanceToDrive, rotation);
    OsmAnd::PointI secondLocation31 = [OANativeUtilities getPoint31FromLatLon:secondLatLon];
    float secondHeightInMeters = [OANativeUtilities getLocationHeightOrZero:secondLocation31];
    OsmAnd::PointI windowSize = state.windowSize;
    OsmAnd::PointI secondPixel = [self getFocusPixel:windowSize.x pixHeight:windowSize.y];
    
    float expectedSurfaceZoom = mapRenderer.renderer->getSurfaceZoomAfterPinchWithParams(fixedLocation31, currentZoom, -rotation, firstLocation31, firstHeightInMeters, firstPixel, secondLocation31, secondHeightInMeters, secondPixel);
    
    if (expectedSurfaceZoom == -1)
        return nil;
    
    int minZoom = mapRenderer.minZoom;
    int maxZoom = mapRenderer.maxZoom;
    OAZoom *boundedZoom = [OAZoom checkZoomBoundsWithZoom:expectedSurfaceZoom minZoom:minZoom maxZoom:maxZoom];
    return [[OAComplexZoom alloc] initWithBase:[boundedZoom getBaseZoom] floatPart:[boundedZoom getZoomFloatPart]];
}

- (OAAutoZoomDTO *) getAutoZoomParams:(float)currentZoom autoZoom:(OAComplexZoom *)autoZoom fixedDurationMillis:(float)fixedDurationMillis
{
    if (fixedDurationMillis > 0)
        return [[OAAutoZoomDTO alloc] initWithZoom:autoZoom floatValue:fixedDurationMillis];
    
    float zoomDelta = [autoZoom fullZoom] - currentZoom;
    float zoomDuration = abs(zoomDelta) / kZoomPerMillis;
    
    if (zoomDuration < kZoomDurationMillis)
        return nil;
    
    return [[OAAutoZoomDTO alloc] initWithZoom:autoZoom floatValue:zoomDuration];
}

- (float) getShowDistanceToDrive:(EOAAutoZoomMap)autoZoomScale nextTurn:(OANextDirectionInfo *)nextTurn speed:(float)speed
{
    float showDistanceToDrive = speed * kShowDrivingSecondsV2 / [OAAutoZoomMap getCoefficient:autoZoomScale];
    if (nextTurn)
    {
        //TODO: check this comparation
        if (_nextTurnInFocus && _nextTurnInFocus == nextTurn.directionInfo)
        {
            showDistanceToDrive = nextTurn.distanceTo;
        }
        else if (nextTurn.distanceTo < showDistanceToDrive)
        {
            showDistanceToDrive = nextTurn.distanceTo;
            _nextTurnInFocus = nextTurn.directionInfo;
        }
        else
        {
            _nextTurnInFocus = nil;
        }
    }
    
    return max(showDistanceToDrive, [OAAutoZoomMap getMinDistanceToDrive:autoZoomScale]);
}

- (OsmAnd::PointI) getFocusPixel:(int)pixWidth pixHeight:(int)pixHeight
{
        CGPoint originalRatio = CGPointMake(kFocusPixelRatioX, kFocusPixelRatioY);
        CGPoint ratio = [OAMapViewTrackingUtilities.instance projectRatioToVisibleMapRect:originalRatio];
        if (CGPointEqualToPoint(ratio, CGPointZero))
            ratio = originalRatio;
        
        int32_t pixelX = (int32_t) (ratio.x * pixWidth);
        int32_t pixelY = (int32_t) (ratio.y * pixHeight);
        return OsmAnd::PointI(pixelX, pixelY);
}


- (void) onManualZoomChange
{
   //TODO: check it
   _nextTurnInFocus = nil;
}

// getTrackPointsAnalyser()

// addAvailableGPXDataSetTypes()

// getOrderedLineDataSet()

// getZoomDataSet()

// postProcessAttributes()

@end
