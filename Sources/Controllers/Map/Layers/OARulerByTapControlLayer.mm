//
//  OARulerByTapControlLayer.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARulerByTapControlLayer.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OAFingerRulerDelegate.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAMapUtils.h"

#include <OsmAndCore/Utilities.h>

@interface OARulerByTapControlLayer() <UIGestureRecognizerDelegate>

@end

@implementation OARulerByTapControlLayer
{
//    OsmAndAppInstance _app;
//    OAAppSettings *_settings;
//    OAMapViewController *_mapViewController;
//
//    BOOL _oneFingerDist;
//    BOOL _twoFingersDist;
//
//    CLLocationCoordinate2D _tapPointOne;
//    CLLocationCoordinate2D _tapPointTwo;
//
//    CALayer *_fingerDistanceSublayer;
//    OAFingerRulerDelegate *_fingerRulerDelegate;
//
//    UITapGestureRecognizer* _singleGestureRecognizer;
//    UITapGestureRecognizer* _doubleGestureRecognizer;
}

//- (void) initFingerLayer
//{
//    _fingerDistanceSublayer = [[CALayer alloc] init];
//    _fingerDistanceSublayer.frame = self.bounds;
//    _fingerDistanceSublayer.bounds = self.bounds;
//    _fingerDistanceSublayer.contentsCenter = self.layer.contentsCenter;
//    _fingerDistanceSublayer.contentsScale = [[UIScreen mainScreen] scale];
//    _fingerRulerDelegate = [[OAFingerRulerDelegate alloc] initWithRulerWidget:self];
//    _fingerDistanceSublayer.delegate = _fingerRulerDelegate;
//}

//- (void) layoutSubviews
//{
//    // resize your layers based on the view's new bounds
//    _fingerDistanceSublayer.frame = self.bounds;
//}

//- (void) commonInit
//{
//    _settings = [OAAppSettings sharedManager];
//    _app = [OsmAndApp instance];
//    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
//    _singleGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
//                                                                       action:@selector(touchDetected:)];
//    _singleGestureRecognizer.delegate = self;
//    _singleGestureRecognizer.numberOfTouchesRequired = 1;
//    //[self addGestureRecognizer:_singleGestureRecognizer]; ??
//    
//    _doubleGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
//                                                                       action:@selector(touchDetected:)];
//    _doubleGestureRecognizer.delegate = self;
//    _doubleGestureRecognizer.numberOfTouchesRequired = 2;
//    //[self addGestureRecognizer:_doubleGestureRecognizer]; ??
//    
//    //self.multipleTouchEnabled = YES; ??
//}
//
//- (void) drawFingerRulerLayer:(CALayer *)layer inContext:(CGContextRef)ctx
//{
//    UIGraphicsPushContext(ctx);
//    if (layer == _fingerDistanceSublayer)
//    {
//        if (_oneFingerDist && !_twoFingersDist)
//        {
//            CLLocation *currLoc = [_app.locationServices lastKnownLocation];
//            if (currLoc)
//            {
//                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, currLoc.coordinate.longitude, currLoc.coordinate.latitude);
//                NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:currLoc.coordinate.latitude fromLon:currLoc.coordinate.longitude toLat:_tapPointOne.latitude toLon:_tapPointOne.longitude];
//                if (linePoints.count == 2)
//                {
//                    CGPoint a = linePoints[0].CGPointValue;
//                    CGPoint b = linePoints[1].CGPointValue;
//                    double angle = [OAMapUtils getAngleBetween:a end:b];
//                    NSString *distance = [_app getFormattedDistance:dist];
//                    _rulerDistance = distance;
//                    [self drawLineBetweenPoints:a end:b context:ctx distance:distance];
//                    [self drawDistance:ctx distance:distance angle:angle start:a end:b];
//                    if ([_mapViewController isLocationVisible:_tapPointOne.latitude longitude:_tapPointOne.longitude])
//                    {
//                        UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
//                        CGRect pointRect = CGRectMake(b.x - iconToUse.size.width / 2, b.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
//                        [iconToUse drawInRect:pointRect];
//                    }
//                }
//            }
//        }
//        if (_twoFingersDist && !_oneFingerDist)
//        {
//            NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:_tapPointOne.latitude fromLon:_tapPointOne.longitude toLat:_tapPointTwo.latitude toLon:_tapPointTwo.longitude];
//            if (linePoints.count == 2)
//            {
//                CGPoint a = linePoints[0].CGPointValue;
//                CGPoint b = linePoints[1].CGPointValue;
//                double angle = [OAMapUtils getAngleBetween:a end:b];
//                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, _tapPointTwo.longitude, _tapPointTwo.latitude);
//                NSString *distance = [_app getFormattedDistance:dist];
//                _rulerDistance = distance;
//                [self drawLineBetweenPoints:a end:b context:ctx distance:distance];
//                [self drawDistance:ctx distance:distance angle:angle start:a end:b];
//                UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
//                if ([_mapViewController isLocationVisible:_tapPointOne.latitude longitude:_tapPointOne.longitude])
//                {
//                    CGRect pointOneRect = CGRectMake(a.x - iconToUse.size.width / 2, a.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
//                    [iconToUse drawInRect:pointOneRect];
//                }
//                if ([_mapViewController isLocationVisible:_tapPointTwo.latitude longitude:_tapPointTwo.longitude])
//                {
//                    CGRect pointTwoRect = CGRectMake(b.x - iconToUse.size.width / 2, b.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
//                    [iconToUse drawInRect:pointTwoRect];
//                }
//            }
//        }
//        OAMapWidgetRegInfo *rulerWidget = [[OARootViewController instance].mapPanel.mapWidgetRegistry widgetByKey:@"radius_ruler"];
//        if (rulerWidget)
//            [rulerWidget.widget updateInfo];
//    }
//    UIGraphicsPopContext();
//}
//
//- (BOOL) updateInfo
//{
//    BOOL visible = [self rulerWidgetOn];
//    if (visible)
//    {
//        if (!_fingerDistanceSublayer)
//            [self initFingerLayer];
//        
//        if (_cachedMapMode != _settings.nightMode)
//        {
//            _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
//            _cachedMapMode = _settings.nightMode;
//        }
//        
//        OAMapRendererView *mapRendererView = _mapViewController.mapView;
//        visible = [_mapViewController calculateMapRuler] != 0
//            && !_mapViewController.zoomingByGesture
//            && !_mapViewController.rotatingByGesture;
//        
//        CGSize viewSize = self.bounds.size;
//        float viewportScale = mapRendererView.viewportYScale;
//        BOOL centerChanged  = _cachedViewportScale != viewportScale || _cachedWidth != viewSize.width || _cachedHeight != viewSize.height;
//        if (centerChanged)
//            [self changeCenter];
//        
//        BOOL modeChanged = _cachedRulerMode != _settings.rulerMode;
//        if ((visible && _cachedRulerMode != RULER_MODE_NO_CIRCLES) || modeChanged)
//        {
//            _cachedMapDensity = mapRendererView.currentPixelsToMetersScaleFactor;
//            double fullMapScale = _cachedMapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
//            float mapAzimuth = mapRendererView.azimuth;
//            float mapZoom = mapRendererView.zoom;
//            const auto target31 = mapRendererView.target31;
//            const auto target31Delta = _cachedCenter31 - target31;
//            
//            BOOL wasTargetChanged = abs(target31Delta.y) > TARGET31_UPDATING_THRESHOLD;
//            if (wasTargetChanged)
//                _cachedCenter31 = target31;
//            
//            //BOOL wasZoomed = abs(_cachedMapZoom - mapZoom) > ZOOM_UPDATING_THRESHOLD;
//            BOOL wasRotated = abs(mapAzimuth - _cachedMapAzimuth) > RULER_ROTATION_UPDATING_THRESHOLD;
//            BOOL wasElevated = abs(_cachedMapElevation - _mapViewController.mapView.elevationAngle) > ELEVATION_UPDATING_THRESHOLD;
//
//            double oneFrameTime = 1.0 / FRAMES_PER_SECOND;
//            BOOL wasUpdatedRecently = ([[NSDate date] timeIntervalSince1970] - _cachedTimestamp) < oneFrameTime;
//
//            BOOL mapMoved = (wasTargetChanged || centerChanged
//                             || _cachedWidth != viewSize.width
//                             || wasElevated
//                             || wasRotated
//                             || _cachedMapZoom != mapZoom
//                             || modeChanged);
//            
//            BOOL compassVisible = [_settings.showCompassControlRuler get] && [_mapViewController getMapZoom] > SHOW_COMPASS_MIN_ZOOM;
//            double heading = _app.locationServices.lastKnownHeading;
//            BOOL headingChanged = abs(int(_cachedHeading) - int(heading)) >= ARROW_ROTATION_UPDATING_THRESHOLD;
//            BOOL shouldUpdateCompass = compassVisible && headingChanged;
//            
//            _cachedWidth = viewSize.width;
//            _cachedHeight = viewSize.height;
//            _cachedHeading = heading;
//            _cachedMapAzimuth = mapAzimuth;
//            _cachedViewportScale = viewportScale;
//            _cachedHeading = _app.locationServices.lastKnownHeading;
//            _mapScaleUnrounded = fullMapScale;
//            _mapScale = [_app calculateRoundedDist:_mapScaleUnrounded];
//            _radius = (_mapScale / _cachedMapDensity) / [[UIScreen mainScreen] scale];
//            _maxRadius = [self calculateMaxRadiusInPx];
//            
//            if ((mapMoved || shouldUpdateCompass) && !wasUpdatedRecently )
//                [self setNeedsDisplay];
//        }
//        if (_twoFingersDist || _oneFingerDist)
//            [_fingerDistanceSublayer setNeedsDisplay];
//
//        _cachedRulerMode = _settings.rulerMode;
//    }
//    [self updateVisibility:visible];
//    return YES;
//}
//
//- (void) touchDetected:(UITapGestureRecognizer *)recognizer
//{
//    // Handle gesture only when it is ended
//    if (recognizer.state != UIGestureRecognizerStateEnded)
//        return;
//    
//    if ([recognizer numberOfTouches] == 1 && !_twoFingersDist) {
//        _oneFingerDist = YES;
//        _twoFingersDist = NO;
//        _tapPointOne = [self getTouchPointCoord:[recognizer locationInView:self]];
//        if (_fingerDistanceSublayer.superlayer != self.layer)
//            [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
//        [_fingerDistanceSublayer setNeedsDisplay];
//    }
//    
//    if ([recognizer numberOfTouches] == 2 && !_oneFingerDist) {
//        _twoFingersDist = YES;
//        _oneFingerDist = NO;
//        CGPoint first = [recognizer locationOfTouch:0 inView:self];
//        CGPoint second = [recognizer locationOfTouch:1 inView:self];
//        _tapPointOne = [self getTouchPointCoord:first];
//        _tapPointTwo = [self getTouchPointCoord:second];
//        if (_fingerDistanceSublayer.superlayer != self.layer)
//            [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
//        [_fingerDistanceSublayer setNeedsDisplay];
//    }
//    
//    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(hideTouchRuler) object: self];
//    [self performSelector:@selector(hideTouchRuler) withObject: self afterDelay: DRAW_TIME];
//}
//
//- (void) hideTouchRuler
//{
//    _rulerDistance = nil;
//    _oneFingerDist = NO;
//    _twoFingersDist = NO;
//    if (_fingerDistanceSublayer.superlayer == self.layer)
//        [_fingerDistanceSublayer removeFromSuperlayer];
//}

@end
