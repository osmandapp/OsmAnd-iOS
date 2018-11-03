//
//  OARulerWidget.m
//  OsmAnd
//
//  Created by Paul on 10/5/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARulerWidget.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OALocationServices.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAMapWidgetRegistry.h"
#import "OATextInfoWidget.h"
#import "OAMapWidgetRegInfo.h"

#include <OsmAndCore/Utilities.h>

#define kMapRulerMaxWidth 120
#define DRAW_TIME 2
#define LABEL_OFFSET 15

@interface OARulerWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation OARulerWidget
{
    OALocationServices *_locationProvider;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    double _radius;
    double _maxRadius;
    float _cachedViewportScale;
    float _cachedWidth;
    float _cachedMapAngle;
    double _mapScale;
    double _mapScaleUnrounded;
    float _mapDensity;
    int _cachedRulerMode;
    BOOL _cachedMapMode;
    
    UIImage *_centerIconDay;
    UIImage *_centerIconNight;
    
    UITapGestureRecognizer* _singleGestureRecognizer;
    UITapGestureRecognizer* _doubleGestureRecognizer;
    UILongPressGestureRecognizer *_longSingleGestureRecognizer;
    UILongPressGestureRecognizer *_longDoubleGestureRecognizer;
    
    CLLocationCoordinate2D _tapPointOne;
    CLLocationCoordinate2D _tapPointTwo;
    
    NSDictionary<NSString *, NSNumber *> *_rulerLineAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerCircleAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerCircleAltAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerLineFontAttrs;
    
    CALayer *_fingerDistanceSublayer;
    
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:@"OARulerWidget" owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARulerWidget class]])
        {
            self = (OARulerWidget *)v;
            break;
        }
    }
    
    if (self)
        self.frame = CGRectMake(50, 50, 100, 100);
    
    [self commonInit];
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARulerWidget class]])
        {
            self = (OARulerWidget *)v;
            break;
        }
    }
    
    if (self)
        self.frame = frame;
    
    [self commonInit];
    
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
    _locationProvider = _app.locationServices;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _singleGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(touchDetected:)];
    _singleGestureRecognizer.delegate = self;
    _singleGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:_singleGestureRecognizer];
    
    _doubleGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(touchDetected:)];
    _doubleGestureRecognizer.delegate = self;
    _doubleGestureRecognizer.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:_doubleGestureRecognizer];
    
    _longSingleGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(touchDetected:)];
    _longSingleGestureRecognizer.numberOfTouchesRequired = 1;
    _longSingleGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longSingleGestureRecognizer];
    
    _longDoubleGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(touchDetected:)];
    _longDoubleGestureRecognizer.numberOfTouchesRequired = 2;
    _longDoubleGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longDoubleGestureRecognizer];
    self.multipleTouchEnabled = YES;
    _centerIconDay = [UIImage imageNamed:@"ic_ruler_center.png"];
    _centerIconNight = [UIImage imageNamed:@"ic_ruler_center_light.png"];
    _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
    _cachedMapMode = _settings.nightMode;
    self.hidden = YES;
}

- (BOOL) updateInfo
{
    BOOL visible = [self rulerWidgetOn];
    if (visible)
    {
        if (!_fingerDistanceSublayer)
            [self initFingerLayer];
        
        if (_cachedMapMode != _settings.nightMode)
        {
            _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
            _cachedMapMode = _settings.nightMode;
        }
        
        OAMapRendererView *mapRendererView = _mapViewController.mapView;
        visible = [_mapViewController calculateMapRuler] != 0;
        BOOL centerChanged  = _cachedViewportScale != _mapViewController.mapView.viewportYScale;
        if (centerChanged)
            [self changeCenter];
        
        BOOL modeChanged = _cachedRulerMode != _settings.rulerMode;
        if ((visible && _cachedRulerMode != RULER_MODE_NO_CIRCLES) || modeChanged) {
            _mapDensity = mapRendererView.currentPixelsToMetersScaleFactor;
            double fullMapScale = _mapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
            BOOL mapMoved = (centerChanged
                             || _cachedWidth != self.frame.size.width
                             || _cachedMapAngle != mapRendererView.elevationAngle
                             || _mapScaleUnrounded != fullMapScale
                             || modeChanged);
            _cachedWidth = self.frame.size.width;
            _cachedMapAngle = mapRendererView.elevationAngle;
            _cachedViewportScale = _mapViewController.mapView.viewportYScale;
            _mapScaleUnrounded = fullMapScale;
            _mapScale = [_app calculateRoundedDist:_mapScaleUnrounded];
            _radius = (_mapScale / _mapDensity) / [[UIScreen mainScreen] scale];
            _maxRadius = [self calculateMaxRadiusInPx];
            //if (mapMoved) {
                [self setNeedsDisplay];
            //}
        }
        if (_twoFingersDist || _oneFingerDist)
        {
            [_fingerDistanceSublayer setNeedsDisplay];
        }
        _cachedRulerMode = _settings.rulerMode;
    }
    [self updateVisibility:visible];
    return YES;
}

- (void) updateAttributes
{
    _rulerLineAttrs = [_mapViewController getLineRenderingAttributes:@"rulerLine"];
    _rulerCircleAttrs = [_mapViewController getLineRenderingAttributes:@"rulerCircle"];
    _rulerCircleAltAttrs = [_mapViewController getLineRenderingAttributes:@"rulerCircleAlt"];
    _rulerLineFontAttrs = [_mapViewController getLineRenderingAttributes:@"rulerLineFont"];
}

- (float) calculateMaxRadiusInPx
{
    float centerY = self.center.y * _cachedViewportScale;
    float centerX = self.center.x;
    return MAX(centerY, centerX);
}

-(void) drawRect:(CGRect)rect {
    [super drawRect:rect];
}

- (void) initFingerLayer
{
    _fingerDistanceSublayer = [[CALayer alloc] init];
    _fingerDistanceSublayer.frame = self.bounds;
    _fingerDistanceSublayer.bounds = self.bounds;
    _fingerDistanceSublayer.contentsCenter = self.layer.contentsCenter;
    _fingerDistanceSublayer.contentsScale = [[UIScreen mainScreen] scale];
    _fingerDistanceSublayer.delegate = self;
}

- (void)layoutSubviews {
    // resize your layers based on the view's new bounds
    _fingerDistanceSublayer.frame = self.bounds;
}

/**
 * Returns the destination point having travelled along a rhumb line from ‘this’ point the given
 * distance on the  given bearing.
 *
 * @param   {number} distance - Distance travelled, in same units as earth radius (default: metres).
 * @param   {number} bearing - Bearing in degrees from north.
 * @param   {number} [radius=6371e3] - (Mean) radius of earth (defaults to radius in metres).
 * @returns {LatLon} Destination point.
 *
 * @example
 *     var p1 = new LatLon(51.127, 1.338);
 *     var p2 = p1.rhumbDestinationPoint(40300, 116.7); // 50.9642°N, 001.8530°E
 */
OsmAnd::LatLon rhumbDestinationPoint(double lat, double lon, double distance, double bearing)
{
    double radius = 6371e3;

    double δ = distance / radius; // angular distance in radians
    double φ1 = qDegreesToRadians(lat);
    double λ1 = qDegreesToRadians(lon);
    double θ = qDegreesToRadians(bearing);
    
    double Δφ = δ * cos(θ);
    double φ2 = φ1 + Δφ;
    
    // check for some daft bugger going past the pole, normalise latitude if so
    if (ABS(φ2) > M_PI_2)
        φ2 = φ2>0 ? M_PI-φ2 : -M_PI-φ2;
    
    double Δψ = log(tan(φ2/2+M_PI_4) / tan(φ1/2 + M_PI_4));
    double q = ABS(Δψ) > 10e-12 ? Δφ / Δψ : cos(φ1); // E-W course becomes ill-conditioned with 0/0
    
    double Δλ = δ * sin(θ) / q;
    double λ2 = λ1 + Δλ;
    
    //return OsmAnd::LatLon(OsmAnd::Utilities::normalizeLatitude(qRadiansToDegrees(phi2)), OsmAnd::Utilities::normalizeLongitude(qRadiansToDegrees(lambda2)));
    //return new LatLon(φ2.toDegrees(), (λ2.toDegrees()+540) % 360 - 180); // normalise to −180..+180°
    return OsmAnd::LatLon(qRadiansToDegrees(φ2), qRadiansToDegrees(λ2));
};

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    [self updateAttributes];
    if (layer == self.layer) {
        if (_settings.rulerMode != RULER_MODE_NO_CIRCLES) {
            double maxRadiusCopy = _maxRadius;
            BOOL hasAttributes = _rulerCircleAttrs && _rulerCircleAltAttrs && [_rulerCircleAttrs count] != 0 && [_rulerCircleAltAttrs count] != 0;
            NSNumber *circleColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color"] : [_rulerCircleAltAttrs valueForKey:@"color"]) :
            nil;
            UIColor *circleColor = circleColorAttr ? UIColorFromARGB(circleColorAttr.intValue) : [UIColor blackColor];
            NSNumber *textShadowColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color_3"] : [_rulerCircleAltAttrs valueForKey:@"color_3"]) :
            nil;
            UIColor *textShadowColor =  textShadowColorAttr ? UIColorFromARGB(textShadowColorAttr.intValue) : [[UIColor whiteColor] colorWithAlphaComponent:0.5];
            NSNumber *shadowColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"shadowColor"] : [_rulerCircleAltAttrs valueForKey:@"shadowColor"]) :
            nil;
            CGColor *shadowColor = shadowColorAttr ? UIColorFromARGB(shadowColorAttr.intValue).CGColor : nil;
            float strokeWidth = (hasAttributes && [_rulerCircleAttrs valueForKey:@"strokeWidth"]) ?
            [_rulerCircleAttrs valueForKey:@"strokeWidth"].floatValue / [[UIScreen mainScreen] scale] : 1.0;
            float shadowRadius = hasAttributes && [_rulerCircleAttrs valueForKey:@"shadowRadius"] ? [_rulerCircleAttrs valueForKey:@"shadowRadius"].floatValue : 3.0;
            
            float strokeWidthText = (hasAttributes && [_rulerCircleAttrs valueForKey:@"strokeWidth_3"]) ?
            -[_rulerCircleAttrs valueForKey:@"strokeWidth_3"].floatValue : -6.0;
            NSNumber *textColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color_2"] : [_rulerCircleAltAttrs valueForKey:@"color_2"]) :
            nil;
            UIColor *textColor =  textColorAttr ? UIColorFromARGB(textColorAttr.intValue) : [UIColor blackColor];
            
            UIFont *font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0];
            NSDictionary<NSAttributedStringKey, id> *attrs = @{NSFontAttributeName: font, NSStrokeColorAttributeName : textShadowColor,
                                                               NSForegroundColorAttributeName : textColor,
                                                               NSStrokeWidthAttributeName : @(strokeWidthText)};
            for (int i = 1; maxRadiusCopy > _radius && _radius != 0; i++) {
                [circleColor set];
                CGContextSetLineWidth(ctx, strokeWidth);
                CGContextSetShadowWithColor(ctx, CGSizeZero, shadowRadius, shadowColor);
                maxRadiusCopy -= _radius;
                double currRadius = _radius * i;
                
                auto center = OsmAnd::Utilities::convert31ToLatLon(_mapViewController.mapView.target31);
                double r = currRadius * _mapDensity * [[UIScreen mainScreen] scale];
                auto latLonTop = rhumbDestinationPoint(center.latitude, center.longitude, r, 0);
                auto latLonBottom = rhumbDestinationPoint(center.latitude, center.longitude, r, 180);
                auto latLonLeft = rhumbDestinationPoint(center.latitude, center.longitude, r, -90);
                auto latLonRight = rhumbDestinationPoint(center.latitude, center.longitude, r, 90);
                auto cTop = OsmAnd::Utilities::convertLatLonTo31(latLonTop);
                auto cBottom = OsmAnd::Utilities::convertLatLonTo31(latLonBottom);
                auto cLeft = OsmAnd::Utilities::convertLatLonTo31(latLonLeft);
                auto cRight = OsmAnd::Utilities::convertLatLonTo31(latLonRight);

                CGPoint sTop;
                [_mapViewController.mapView convert:&cTop toScreen:&sTop checkOffScreen:YES];
                CGPoint sBottom;
                [_mapViewController.mapView convert:&cBottom toScreen:&sBottom checkOffScreen:YES];
                CGPoint sLeft;
                [_mapViewController.mapView convert:&cLeft toScreen:&sLeft checkOffScreen:YES];
                CGPoint sRight;
                [_mapViewController.mapView convert:&cRight toScreen:&sRight checkOffScreen:YES];

                CGRect circleRect = CGRectMake(sLeft.x,
                                               sTop.y,
                                               sRight.x - sLeft.x,
                                               sBottom.y - sTop.y);
                CGContextStrokeEllipseInRect(ctx, circleRect);
                
                NSString *dist = [_app getFormattedDistance:_mapScale * i];
                CGSize titleSize = [dist sizeWithAttributes:attrs];
                CGContextSaveGState(ctx); {
                    if (self.frame.size.height > self.frame.size.width)
                    {
                        [dist drawAtPoint:CGPointMake(circleRect.origin.x + circleRect.size.width/2 - titleSize.width/2,
                                                      circleRect.origin.y - titleSize.height/2) withAttributes:attrs];
                        [dist drawAtPoint:CGPointMake(circleRect.origin.x + circleRect.size.width/2 - titleSize.width/2,
                                                      circleRect.origin.y + circleRect.size.height - titleSize.height/2)
                           withAttributes:attrs];
                    }
                    else
                    {
                        [dist drawAtPoint:CGPointMake(circleRect.origin.x - titleSize.width/2,
                                                      circleRect.origin.y + circleRect.size.height/2 - titleSize.height/2) withAttributes:attrs];
                        [dist drawAtPoint:CGPointMake(circleRect.origin.x + circleRect.size.width - titleSize.width/2,
                                                      circleRect.origin.y + circleRect.size.height/2 - titleSize.height/2)
                           withAttributes:attrs];
                    }
                    
                } CGContextRestoreGState(ctx);
            }
            
        }
    }
    if (layer == _fingerDistanceSublayer) {
        if (_oneFingerDist && !_twoFingersDist)
        {
            CLLocation *currLoc = [_app.locationServices lastKnownLocation];
            if (currLoc) {
                NSValue *pointOfCurrentLocation = [self getTouchPointFromLat:currLoc.coordinate.latitude lon:currLoc.coordinate.longitude];
                NSValue *touchPoint = [self getTouchPointFromLat:_tapPointOne.latitude lon:_tapPointOne.longitude];
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude,
                                                              currLoc.coordinate.longitude, currLoc.coordinate.latitude);
                if (!pointOfCurrentLocation)
                {
                    CGPoint touch = touchPoint.CGPointValue;
                    CGFloat angle = 360 - [[OsmAndApp instance].locationServices radiusFromBearingToLocation:
                                           [[CLLocation alloc] initWithLatitude:_tapPointOne.latitude longitude:_tapPointOne.longitude]];
                    CGFloat angleToLocation = qDegreesToRadians(angle);
                    double endX = (sinf(angleToLocation) * dist) + touch.x;
                    double endY = (cosf(angleToLocation) * dist) + touch.y;
                    CGFloat maxX = CGRectGetMaxX(self.frame);
                    CGFloat minX = CGRectGetMinX(self.frame);
                    CGFloat maxY = CGRectGetMaxY(self.frame);
                    CGFloat minY = CGRectGetMinY(self.frame);
                    
                    pointOfCurrentLocation = [self pointOnRect:endX y:endY minX:minX minY:minY maxX:maxX maxY:maxY startPoint:touch];
                }
                if (pointOfCurrentLocation && touchPoint)
                {
                    CGPoint touchCGPoint = touchPoint.CGPointValue;
                    double angle = [self getLineAngle:touchCGPoint end:pointOfCurrentLocation.CGPointValue];
                    NSString *distance = [_app getFormattedDistance:dist];
                    _rulerDistance = distance;
                    [self drawLineBetweenPoints:touchCGPoint end:pointOfCurrentLocation.CGPointValue context:ctx distance:distance];
                    [self drawDistance:ctx distance:distance angle:angle start:touchCGPoint end:pointOfCurrentLocation.CGPointValue];
                    UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
                    CGRect pointRect = CGRectMake(touchCGPoint.x - iconToUse.size.width / 2, touchCGPoint.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                    [iconToUse drawInRect:pointRect];
                }
            }
        }
        if (_twoFingersDist && !_oneFingerDist) {
            NSValue *first = [self getTouchPointFromLat:_tapPointOne.latitude lon:_tapPointOne.longitude];
            NSValue *second = [self getTouchPointFromLat:_tapPointTwo.latitude lon:_tapPointTwo.longitude];
            if (first && second) {
                double angle = [self getLineAngle:first.CGPointValue end:second.CGPointValue];
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude,
                                                              _tapPointTwo.longitude, _tapPointTwo.latitude);
                NSString *distance = [_app getFormattedDistance:dist];
                _rulerDistance = distance;
                [self drawLineBetweenPoints:first.CGPointValue end:second.CGPointValue context:ctx distance:distance];
                [self drawDistance:ctx distance:distance angle:angle start:first.CGPointValue end:second.CGPointValue];
                UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
                CGRect pointOneRect = CGRectMake(first.CGPointValue.x - iconToUse.size.width / 2,
                                                 first.CGPointValue.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                CGRect pointTwoRect = CGRectMake(second.CGPointValue.x - iconToUse.size.width / 2,
                                                 second.CGPointValue.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                [iconToUse drawInRect:pointOneRect];
                [iconToUse drawInRect:pointTwoRect];
            }
        }
        OAMapWidgetRegInfo *rulerWidget = [[OARootViewController instance].mapPanel.mapWidgetRegistry widgetByKey:@"radius_ruler"];
        if (rulerWidget)
            [rulerWidget.widget updateInfo];
    }
    UIGraphicsPopContext();
}

- (void) drawDistance:(CGContextRef)ctx distance:(NSString *)distance angle:(double)angle start:(CGPoint)start end:(CGPoint)end {
    NSValue *middle = nil;
    if (CGRectContainsPoint(self.frame, end)) {
        middle = [NSValue valueWithCGPoint:CGPointMake((start.x + end.x) / 2, (start.y + end.y) / 2)];
    } else {
        CGFloat maxX = CGRectGetMaxX(self.frame);
        CGFloat minX = CGRectGetMinX(self.frame);
        CGFloat maxY = CGRectGetMaxY(self.frame);
        CGFloat minY = CGRectGetMinY(self.frame);
        
        NSValue *screeenIntersectionPoint = [self pointOnRect:end.x y:end.y minX:minX minY:minY maxX:maxX maxY:maxY startPoint:start];
        if (screeenIntersectionPoint) {
            CGPoint intersection = screeenIntersectionPoint.CGPointValue;
            middle = [NSValue valueWithCGPoint:CGPointMake((start.x + intersection.x) / 2, (start.y + intersection.y) / 2)];
        }
    }
    
    if (middle) {
        UIFont *font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
        
        BOOL useDefaults = !_rulerLineFontAttrs || [_rulerLineFontAttrs count] == 0;
        NSNumber *strokeColorAttr = useDefaults ? nil : [_rulerLineFontAttrs objectForKey:@"color_2"];
        UIColor *strokeColor = strokeColorAttr ? UIColorFromARGB(strokeColorAttr.intValue) : [UIColor whiteColor];
        
        NSNumber *colorAttr = useDefaults ? nil : [_rulerLineFontAttrs objectForKey:@"color"];
        UIColor *color = colorAttr ? UIColorFromARGB(colorAttr.intValue) : [UIColor blackColor];
        
        NSNumber *strokeWidthAttr = useDefaults ? nil : [_rulerLineFontAttrs valueForKey:@"strokeWidth_2"];
        float strokeWidth = strokeWidthAttr ? -strokeWidthAttr.floatValue / [[UIScreen mainScreen] scale] : -2.0;
        
        NSDictionary<NSAttributedStringKey, id> *attrs = @{NSFontAttributeName: font, NSStrokeColorAttributeName : strokeColor,
                                                           NSForegroundColorAttributeName : color,
                                                           NSStrokeWidthAttributeName : @(strokeWidth)};
        CGSize titleSize = [distance sizeWithAttributes:attrs];
        CGPoint middlePoint = middle.CGPointValue;
        CGRect rect = CGRectMake(middlePoint.x - (titleSize.width / 2), middlePoint.y - (titleSize.height / 2), titleSize.width, titleSize.height);
        
        CGFloat xMid = CGRectGetMidX(rect);
        CGFloat yMid = CGRectGetMidY(rect);
        CGContextSaveGState(ctx); {
            
            CGContextTranslateCTM(ctx, xMid, yMid);
            CGContextRotateCTM(ctx, angle);
            
            CGRect newRect = rect;
            newRect.origin.x = -newRect.size.width / 2;
            newRect.origin.y = -newRect.size.height / 2 + LABEL_OFFSET;
            
            [distance drawWithRect:newRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
            CGContextStrokePath(ctx);
        } CGContextRestoreGState(ctx);
    }
}

- (void) drawLineBetweenPoints:(CGPoint) start end:(CGPoint) end context:(CGContextRef) ctx distance:(NSString *) distance
{
    CGContextSaveGState(ctx); {
        
        NSNumber *colorAttr = _rulerLineAttrs ? [_rulerLineAttrs objectForKey:@"color"] : nil;
        UIColor *color = colorAttr ? UIColorFromARGB(colorAttr.intValue) : [UIColor blackColor];
        [color set];
        CGContextSetLineWidth(ctx, 4.0);
        CGFloat dashLengths[] = {10, 5};
        CGContextSetLineDash(ctx, 0.0, dashLengths , 2);
        CGContextMoveToPoint(ctx, start.x, start.y);
        CGContextAddLineToPoint(ctx, end.x, end.y);
        CGContextStrokePath(ctx);
    } CGContextRestoreGState(ctx);
}

- (double) getLineAngle:(CGPoint)start end:(CGPoint)end
{
    double dx = start.x - end.x;
    double dy = start.y - end.y;
    
    return dx ? atan(dy/dx) : (180 * M_PI) / 180;
}

- (NSValue *) getTouchPointFromLat:(CGFloat) lat lon:(CGFloat) lon
{
    const OsmAnd::LatLon latLon(lat, lon);
    OsmAnd::PointI currentPositionI = OsmAnd::Utilities::convertLatLonTo31(latLon);
    
    CGPoint point;
    if ([_mapViewController.mapView convert:&currentPositionI toScreen:&point checkOffScreen:YES])
    {
        return [NSValue valueWithCGPoint:point];
    }
    return nil;
}

- (NSValue *) pointOnRect:(CGFloat)x y:(CGFloat)y minX:(CGFloat)minX minY:(CGFloat)minY maxX:(CGFloat)maxX maxY:(CGFloat)maxY startPoint:(CGPoint)start
{
    //assert minX <= maxX;
    //assert minY <= maxY;
    if ((minX < x && x < maxX) && (minY < y && y < maxY))
        return nil;
    CGFloat startX = start.x;
    CGFloat startY = start.y;
    CGFloat m = (startY - y) / (startX - x);
    
    if (x <= startX) { // check left side
        CGFloat minXy = m * (minX - x) + y;
        if (minY <= minXy && minXy <= maxY)
            return [NSValue valueWithCGPoint:CGPointMake(minX, minXy)];
    }
    
    if (x >= startX) { // check right side
        CGFloat maxXy = m * (maxX - x) + y;
        if (minY <= maxXy && maxXy <= maxY)
            return [NSValue valueWithCGPoint:CGPointMake(maxX, maxXy)];
    }
    
    if (y <= startY) { // check top side
        CGFloat minYx = (minY - y) / m + x;
        if (minX <= minYx && minYx <= maxX)
            return [NSValue valueWithCGPoint:CGPointMake(minYx, minY)];
    }
    
    if (y >= startY) { // check bottom side
        CGFloat maxYx = (maxY - y) / m + x;
        if (minX <= maxYx && maxYx <= maxX)
            return [NSValue valueWithCGPoint:CGPointMake(maxYx, maxY)];
    }
    
    // edge case when finding midpoint intersection: m = 0/0 = NaN
    if (x == startX && y == startY) return [NSValue valueWithCGPoint:CGPointMake(x, y)];
    
    return nil;
}

- (void) touchDetected:(UITapGestureRecognizer *)recognizer
{
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    if ([recognizer numberOfTouches] == 1 && !_twoFingersDist) {
        _oneFingerDist = YES;
        _twoFingersDist = NO;
        _tapPointOne = [self getTouchPointCoord:[recognizer locationInView:self]];
        [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
        [_fingerDistanceSublayer setNeedsDisplay];
    }
    
    if ([recognizer numberOfTouches] == 2 && !_oneFingerDist) {
        _twoFingersDist = YES;
        _oneFingerDist = NO;
        CGPoint first = [recognizer locationOfTouch:0 inView:self];
        CGPoint second = [recognizer locationOfTouch:1 inView:self];
        _tapPointOne = [self getTouchPointCoord:first];
        _tapPointTwo = [self getTouchPointCoord:second];
        [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
        [_fingerDistanceSublayer setNeedsDisplay];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(hideTouchRuler) object: self];
    [self performSelector:@selector(hideTouchRuler) withObject: self afterDelay: DRAW_TIME];
}

- (void) changeCenter
{
    CGSize imageSize = _imageView.frame.size;
    CGRect imageFrame = CGRectMake(self.frame.size.width / 2 - imageSize.width / 2,
                                   (self.frame.size.height / 2 - imageSize.height / 2) * _mapViewController.mapView.viewportYScale,
                                   imageSize.width, imageSize.height);
    _imageView.frame = imageFrame;
}

- (void) hideTouchRuler
{
    _rulerDistance = nil;
    _oneFingerDist = NO;
    _twoFingersDist = NO;
    [_fingerDistanceSublayer removeFromSuperlayer];
}

- (void) onMapSourceUpdated
{
    if ([self rulerWidgetOn])
        [self setNeedsDisplay];
}

- (BOOL) rulerWidgetOn
{
    return [[OARootViewController instance].mapPanel.mapWidgetRegistry isVisible:@"radius_ruler"];
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (_delegate)
            [_delegate widgetVisibilityChanged:nil visible:visible];
        
        return YES;
    }
    return NO;
}

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint
{
    touchPoint.x *= _mapViewController.mapView.contentScaleFactor;
    touchPoint.y *= _mapViewController.mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [_mapViewController.mapView convert:touchPoint toLocation:&touchLocation];
    
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

@end
