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



@implementation OAAutoZoomBySpeedHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASpeedFilter *_speedFilter;
    
    OARouteDirectionInfo *_nextTurnInFocus;
    
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
    }
    return self;
}

// previous version of autozoom code from OAMapViewTrackingUtilities
// without any changes. differs with android
- (double) calculateAutoZoomBySpeedV1:(float)speed mapView:(OAMapRendererView *)mapView
{
    EOAAutoZoomMap autoZoomScale = [_settings.autoZoomMapScale get];
    
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

- (OAComplexZoom *) calculateZoomBySpeedToAnimate:(OAMapRendererView *)mapView myLocation:(CLLocation *)myLocation rotationToAnimate:(float)rotationToAnimate nextTurn:(OANextDirectionInfo *)nextTurn
{
    //TODO: implement
    return nil;
}

- (void) getAnimatedZoomParamsForChart
{
    //TODO: implement
}

- (void) calculateRawZoomBySpeedForChart
{
    //TODO: implement
}

- (void) getAutoZoomParams
{
    //TODO: implement
}

- (void) getShowDistanceToDrive
{
    //TODO: implement
}

- (void) getFocusPixel
{
    //TODO: implement
}


@end

