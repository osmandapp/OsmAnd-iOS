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

#define CLCOORDINATES_EQUAL( coord1, coord2 ) (coord1.latitude == coord2.latitude && coord1.longitude == coord2.longitude)

@interface OARulerWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation OARulerWidget
{
    OALocationServices *_locationProvider;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    int _zoom;
    double _radius;
    double _maxRadius;
    float _cachedViewportScale;
    float _cachedWidth;
    float _cachedMapAngle;
    double _mapScale;
    
    UIImage *_centerIcon;
    
    UITapGestureRecognizer* _singleGestureRecognizer;
    UITapGestureRecognizer* _doubleGestureRecognizer;
    UILongPressGestureRecognizer *_longSingleGestureRecognizer;
    UILongPressGestureRecognizer *_longDoubleGestureRecognizer;
    
    CLLocationCoordinate2D _tapPointOne;
    CLLocationCoordinate2D _tapPointTwo;
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
    _centerIcon = [UIImage imageNamed:@"ic_ruler_center.png"];
    _imageView.image = _centerIcon;
    [self changeCenter];
    self.hidden = YES;
}

- (BOOL) updateInfo
{
    BOOL visible = [self rulerWidgetOn];
    if (visible)
    {
        OAMapRendererView *mapRendererView = _mapViewController.mapView;
        visible = [_mapViewController calculateMapRuler] != 0;
        BOOL centerChanged  = _cachedViewportScale != _mapViewController.mapView.viewportYScale;
        BOOL mapMoved = (_zoom != (int) mapRendererView.zoom
                              || centerChanged
                              || _cachedWidth != self.frame.size.width
                              || _cachedMapAngle != mapRendererView.elevationAngle);
        if (centerChanged) {
            [self changeCenter];
        }
        if (visible && mapMoved) {
            _cachedWidth = self.frame.size.width;
            _cachedMapAngle = mapRendererView.elevationAngle;
            _cachedViewportScale = _mapViewController.mapView.viewportYScale;
            float mapDensity = mapRendererView.currentPixelsToMetersScaleFactor;
            _mapScale = [_app calculateRoundedDist:mapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale]];
            _radius = (_mapScale / mapDensity) / [[UIScreen mainScreen] scale];
            _maxRadius = [self calculateMaxRadiusInPx];
            _zoom = (int) mapRendererView.zoom;
            _oneFingerDist = NO;
            _twoFingersDist = NO;
            [self setNeedsDisplay];
        }
//        else if (_oneFingerDist && !_twoFingersDist)
//        {
//            _oneFingerDist = NO;
//            [self setNeedsDisplay];
//        }
        else if (_twoFingersDist || _oneFingerDist)
        {
            [self setNeedsDisplay];
        }
    }
    [self updateVisibility:visible];
    return YES;
}

- (float) calculateMaxRadiusInPx
{
    float centerY = self.center.y * _cachedViewportScale;
    float centerX = self.center.x;
    return MAX(centerY, centerX);
}

-(void) drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 1.0);
    
    double maxRadiusCopy = _maxRadius;
    
    UIFont *font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0];
    NSDictionary<NSAttributedStringKey, id> *attrs = @{NSFontAttributeName: font, NSStrokeColorAttributeName : [[UIColor whiteColor] colorWithAlphaComponent:0.7f],
                                                       NSForegroundColorAttributeName : [UIColor blackColor],
                                                       NSStrokeWidthAttributeName : @(-4.0)};
    
    for (int i = 1; maxRadiusCopy > _radius && _radius != 0; i++) {
        [[UIColor blackColor] set];
        CGContextSetShadowWithColor(ctx, CGSizeZero, 3.0, [UIColor whiteColor].CGColor);
        maxRadiusCopy -= _radius;
        double currRadius = _radius * i;
        double cosine = cos(qDegreesToRadians(_cachedMapAngle - 90));
        CGRect circleRect = CGRectMake(self.frame.size.width/2 - currRadius,
                                       (self.frame.size.height/2 * _cachedViewportScale) - (currRadius * cosine),
                                       currRadius * 2, currRadius * 2 * cosine);
        CGContextStrokeEllipseInRect(ctx, circleRect);
            
        NSString *dist = [_app getFormattedDistance:_mapScale * i];
        CGSize titleSize = [dist sizeWithAttributes:attrs];
        [dist drawAtPoint:CGPointMake(circleRect.origin.x + circleRect.size.width/2 - titleSize.width/2,
                                      circleRect.origin.y - titleSize.height/2) withAttributes:attrs];
        [dist drawAtPoint:CGPointMake(circleRect.origin.x + circleRect.size.width/2 - titleSize.width/2,
                                      circleRect.origin.y + circleRect.size.height - titleSize.height/2)
                                      withAttributes:attrs];
    }
    
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
                pointOfCurrentLocation = [NSValue valueWithCGPoint:CGPointMake(endX, endY)];
            }
            if (pointOfCurrentLocation && touchPoint)
            {
                double angle = [self getLineAngle:touchPoint.CGPointValue end:pointOfCurrentLocation.CGPointValue];
                NSString *distance = [_app getFormattedDistance:dist];
                _rulerDistance = distance;
                [self drawLineBetweenPoints:touchPoint.CGPointValue end:pointOfCurrentLocation.CGPointValue context:ctx distance:distance];
                [self drawDistance:ctx distance:distance angle:angle start:touchPoint.CGPointValue end:pointOfCurrentLocation.CGPointValue];
                
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
        }
    }
    OAMapWidgetRegInfo *rulerWidget = [[OARootViewController instance].mapPanel.mapWidgetRegistry widgetByKey:@"radius_ruler"];
    if (rulerWidget)
        [rulerWidget.widget updateInfo];
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
        NSDictionary<NSAttributedStringKey, id> *attrs = @{NSFontAttributeName: font, NSStrokeColorAttributeName : [[UIColor whiteColor] colorWithAlphaComponent:0.7f],
                                                           NSForegroundColorAttributeName : [UIColor blackColor],
                                                           NSStrokeWidthAttributeName : @(-4.0)};
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
        [[UIColor blackColor] set];
        CGContextSetLineWidth(ctx, 5.0);
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
    if ([_mapViewController.mapView convert:&currentPositionI toScreen:&point])
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
        [self setNeedsDisplay];
    }

    if ([recognizer numberOfTouches] == 2 && !_oneFingerDist) {
        _twoFingersDist = YES;
        _oneFingerDist = NO;
        CGPoint first = [recognizer locationOfTouch:0 inView:self];
        CGPoint second = [recognizer locationOfTouch:1 inView:self];
        _tapPointOne = [self getTouchPointCoord:first];
        _tapPointTwo = [self getTouchPointCoord:second];
        [self setNeedsDisplay];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(hideTouchRuler) object: self];
    [self performSelector:@selector(hideTouchRuler) withObject: self afterDelay: DRAW_TIME];
}

- (void) changeCenter
{
    BOOL moveUp = _mapViewController.mapView.viewportYScale == 1.0 && _cachedViewportScale == 1.5;
    CGRect frame = _imageView.frame;
    CGFloat y = moveUp ? frame.origin.y / 1.5 : frame.origin.y * _mapViewController.mapView.viewportYScale;
    CGRect imageFrame = CGRectMake(frame.origin.x, y, frame.size.width, frame.size.height);
    _imageView.frame = imageFrame;
}

- (void) hideTouchRuler
{
    _rulerDistance = nil;
    _oneFingerDist = NO;
    _twoFingersDist = NO;
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
