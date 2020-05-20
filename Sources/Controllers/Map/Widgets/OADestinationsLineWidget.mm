//
//  OADestinationsLineWidget.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 21.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADestinationsLineWidget.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAUtilities.h"
#import "OADestinationLineDelegate.h"
#import "OADestinationsLayer.h"
#import "OADestinationsHelper.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

#define LABEL_OFFSET 15
#define kArrowFrame @"map_marker_direction_arrow_p1_light"
#define kArrowShadow @"map_marker_direction_arrow_p3_shadow"


@interface OADestinationsLineWidget()

@property (nonatomic) NSArray *colors;
@property (nonatomic) NSArray *markerNames;

@end

@implementation OADestinationsLineWidget
{
    OsmAndAppInstance _app;
    OALocationServices *_locationProvider;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    OAMapPanelViewController *_mapPanel;
    
    UILongPressGestureRecognizer *_longSingleGestureRecognizer;

    NSMutableArray<OADestination *> *_destinationsArray;
    CALayer *_destinationLineSublayer;
    NSString *_arrowColor;
    
    OADestinationLineDelegate *_destinationLineDelegate;
    CLLocation *_tapLocation;
}

- (instancetype) init
{
    self = [super init];
    
    if (self)
        self.frame = CGRectMake(0., 0., DeviceScreenWidth, DeviceScreenHeight);
    
    [self commonInit];
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
        self.frame = frame;

    [self commonInit];

    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _destinationsArray = [[NSMutableArray alloc] init];
    _mapPanel = [OARootViewController instance].mapPanel;
    
    _longSingleGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(touchDetected:)];
    _longSingleGestureRecognizer.numberOfTouchesRequired = 1;
    _longSingleGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longSingleGestureRecognizer];
    
    self.colors = @[UIColorFromRGB(marker_pin_color_orange),
                    UIColorFromRGB(marker_pin_color_blue),
                    UIColorFromRGB(marker_pin_color_green),
                    UIColorFromRGB(marker_pin_color_red),
                    UIColorFromRGB(marker_pin_color_light_green)];
    
    self.markerNames = @[@"map_marker_direction_arrow_p2_color_pin_1", @"map_marker_direction_arrow_p2_color_pin_2", @"map_marker_direction_arrow_p2_color_pin_3", @"map_marker_direction_arrow_p2_color_pin_4", @"map_marker_direction_arrow_p2_color_pin_5"];
    
    self.hidden = NO;
    [self initDestinationLayer];
}

#pragma mark - Layer

- (void) initDestinationLayer
{
    _destinationLineSublayer = [[CALayer alloc] init];
    _destinationLineSublayer.drawsAsynchronously = YES;
    _destinationLineSublayer.frame = self.bounds;
    _destinationLineSublayer.bounds = self.bounds;
    _destinationLineSublayer.contentsCenter = self.layer.contentsCenter;
    _destinationLineSublayer.contentsScale = [[UIScreen mainScreen] scale];
    _destinationLineDelegate = [[OADestinationLineDelegate alloc] initWithDestinationLine:self];
    _destinationLineSublayer.delegate = _destinationLineDelegate;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
   
    self.frame = CGRectMake(0., 0., DeviceScreenWidth, DeviceScreenHeight);
    _destinationLineSublayer.frame = CGRectMake(0., 0., DeviceScreenWidth, DeviceScreenHeight);
}

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (BOOL) updateLayer
{
    if (_destinationLineSublayer.superlayer != self.layer)
        [self.layer insertSublayer:_destinationLineSublayer above:self.layer];
    [_destinationLineSublayer setNeedsDisplay];
    return YES;
}

- (void) clearLayers
{
    for (CALayer *layer in self.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
}

#pragma mark - Drawing

- (void) drawLineArrowWidget:(OADestination *)destination
{
    [self clearLayers];
    [_destinationsArray addObject:destination];
    [self initDestinationLayer];
    if (_destinationLineSublayer.superlayer != self.layer)
        [self.layer insertSublayer:_destinationLineSublayer above:self.layer];
    [_destinationLineSublayer setNeedsDisplay];
}

- (void) drawDestinationLineLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    
    if ([OADestinationsHelper instance].sortedDestinations.count == 0)
        return;
    
    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    OADestination *firstMarkerDestination = (destinations.count >= 1 ? destinations[0] : nil);
    OADestination *secondMarkerDestination = (destinations.count >= 2 ? destinations[1] : nil);
    if (layer == _destinationLineSublayer)
    {
        if (_tapLocation)
        {
            if (firstMarkerDestination)
                [self drawLine:firstMarkerDestination fromLocation:_tapLocation inContext:ctx];
            if (secondMarkerDestination && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
                [self drawLine:secondMarkerDestination fromLocation:_tapLocation inContext:ctx];
            return;
        }
        
        if ([_settings.directionLines get])
        {
            CLLocation *currLoc = [_app.locationServices lastKnownLocation];
            if (currLoc)
            {
                if (firstMarkerDestination)
                    [self drawLine:firstMarkerDestination fromLocation:currLoc inContext:ctx];
                if (secondMarkerDestination && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
                    [self drawLine:secondMarkerDestination fromLocation:currLoc inContext:ctx];
            }
        }
        
        if ([_settings.arrowsOnMap get])
        {
            if (firstMarkerDestination)
                [self drawArrow:firstMarkerDestination inContext:ctx];
            if (secondMarkerDestination && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
                [self drawArrow:secondMarkerDestination inContext:ctx];
        }
    }
    UIGraphicsPopContext();
}

#pragma mark - Lines

- (void) drawLine:(OADestination *)marker fromLocation:(CLLocation *)currLoc inContext:(CGContextRef)ctx
{
    NSValue *pointOfCurrentLocation = [self getPointFromLat:currLoc.coordinate.latitude lon:currLoc.coordinate.longitude];
    NSValue *markerPoint = [self getPointFromLat:marker.latitude lon:marker.longitude];
    const auto dist = OsmAnd::Utilities::distance(marker.longitude, marker.latitude,
                                                  currLoc.coordinate.longitude, currLoc.coordinate.latitude);
    if (!markerPoint)
        return;
    if (!pointOfCurrentLocation)
    {
        CGPoint touch = markerPoint.CGPointValue;
        CGFloat angle = 360 - [[OsmAndApp instance].locationServices radiusFromBearingToLocation:
                               [[CLLocation alloc] initWithLatitude:marker.latitude longitude:marker.longitude]];
        CGFloat angleToLocation = qDegreesToRadians(angle);
        double endX = (sinf(angleToLocation) * dist) + touch.x;
        double endY = (cosf(angleToLocation) * dist) + touch.y;
        CGFloat maxX = CGRectGetMaxX(self.frame);
        CGFloat minX = CGRectGetMinX(self.frame);
        CGFloat maxY = CGRectGetMaxY(self.frame);
        CGFloat minY = CGRectGetMinY(self.frame);
        
        pointOfCurrentLocation = [self pointOnRect:endX y:endY minX:minX minY:minY maxX:maxX maxY:maxY startPoint:touch];
    }
    if (pointOfCurrentLocation)
    {
        CGPoint touchCGPoint = markerPoint.CGPointValue;
        double angle = [self getLineAngle:touchCGPoint end:pointOfCurrentLocation.CGPointValue];
        NSString *distance = [_app getFormattedDistance:dist];
        
        [self drawLineBetweenPoints:pointOfCurrentLocation.CGPointValue end:markerPoint.CGPointValue distance:distance color:marker.color inContext:ctx];
        [self drawDistance:ctx distance:distance angle:angle start:touchCGPoint end:pointOfCurrentLocation.CGPointValue];
    }
}

- (void) drawLineBetweenPoints:(CGPoint)start end:(CGPoint)end distance:(NSString *)distance color:(UIColor *)lineColor inContext:(CGContextRef)ctx
{
    UIColor *color = lineColor;
    CGFloat dashPattern[] = {10, 15};
    CGContextSaveGState(ctx);
    {
        CGContextSetLineWidth(ctx, 4.0);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextBeginPath(ctx);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextSetLineDash(ctx, 10.0, dashPattern , 2);
        CGContextMoveToPoint(ctx, start.x, start.y);
        CGContextAddLineToPoint(ctx, end.x, end.y);
        CGContextStrokePath(ctx);

        [color set];
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextSetLineDash(ctx, 10.0, dashPattern , 2);
        CGContextMoveToPoint(ctx, start.x, start.y);
        CGContextAddLineToPoint(ctx, end.x, end.y);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
}

- (void) drawDistance:(CGContextRef)ctx distance:(NSString *)distance angle:(double)angle start:(CGPoint)start end:(CGPoint)end
{
    NSValue *middle = nil;
    if (CGRectContainsPoint(self.frame, end))
    {
        middle = [NSValue valueWithCGPoint:CGPointMake((start.x + end.x) / 2, (start.y + end.y) / 2)];
    }
    else
    {
        CGFloat maxX = CGRectGetMaxX(self.frame);
        CGFloat minX = CGRectGetMinX(self.frame);
        CGFloat maxY = CGRectGetMaxY(self.frame);
        CGFloat minY = CGRectGetMinY(self.frame);
        
        NSValue *screeenIntersectionPoint = [self pointOnRect:end.x y:end.y minX:minX minY:minY maxX:maxX maxY:maxY startPoint:start];
        if (screeenIntersectionPoint)
        {
            CGPoint intersection = screeenIntersectionPoint.CGPointValue;
            middle = [NSValue valueWithCGPoint:CGPointMake((start.x + intersection.x) / 2, (start.y + intersection.y) / 2)];
        }
    }
    if (middle)
    {
        UIFont *font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold];
        UIColor *strokeColor = [UIColor whiteColor];
        UIColor *color = [UIColor blackColor];
        float strokeWidth = -2.0;
        
        NSDictionary<NSAttributedStringKey, id> *attrs = @{NSFontAttributeName: font, NSStrokeColorAttributeName : strokeColor,
        NSForegroundColorAttributeName : color,
        NSStrokeWidthAttributeName : @(strokeWidth)};
    
        CGSize titleSize = [distance sizeWithAttributes:attrs];
        CGPoint middlePoint = middle.CGPointValue;
        CGRect rect = CGRectMake(middlePoint.x - (titleSize.width / 2), middlePoint.y - (titleSize.height / 2), titleSize.width, titleSize.height);
        
        CGFloat xMid = CGRectGetMidX(rect);
        CGFloat yMid = CGRectGetMidY(rect);
        CGContextSaveGState(ctx);
        {
            CGContextTranslateCTM(ctx, xMid, yMid);
            CGContextRotateCTM(ctx, angle);
            
            CGRect newRect = rect;
            newRect.origin.x = -newRect.size.width / 2;
            newRect.origin.y = -newRect.size.height / 2 - LABEL_OFFSET;
            
            [distance drawWithRect:newRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil];
            CGContextStrokePath(ctx);
        }
        CGContextRestoreGState(ctx);
    }
}

#pragma mark - Arrows

- (void) drawArrow:(OADestination *)marker inContext:(CGContextRef)ctx
{
    NSValue *markerPoint = [self getPointFromLat:marker.latitude lon:marker.longitude];
    
    if (!markerPoint)
        return;
    for (NSInteger i = 0; i < self.colors.count; i++)
        if ([marker.color isEqual:self.colors[i]])
            _arrowColor = _markerNames[i];
    
    CLLocationCoordinate2D screenCenterCoord = [self getPointCoord:[self changeCenter]];
    
    double angle = [self changeArrowAngle:screenCenterCoord marker:marker];
    
    if(!CGRectContainsPoint(self.bounds, markerPoint.CGPointValue))
       [self drawArrowToMarker:[self changeCenter] angle:angle inContext:ctx];
}

- (void) drawArrowToMarker:(CGPoint)screenCenter angle:(double)angle inContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    {
        UIImage *arrowIcon = [self getArrowImage:[UIImage imageNamed:kArrowFrame]
                                         inImage:[UIImage imageNamed:_arrowColor]
                                      withShadow:[UIImage imageNamed:kArrowShadow]];
        CGRect imageRect = CGRectMake(0, 0, arrowIcon.size.width, arrowIcon.size.height);
        CGContextTranslateCTM(ctx, screenCenter.x, screenCenter.y);
        CGContextRotateCTM(ctx, angle);
        CGContextTranslateCTM(ctx, (imageRect.size.width * -0.5) + 80, imageRect.size.height * -0.5);
        CGContextDrawImage(ctx, imageRect, arrowIcon.CGImage);
    }
    CGContextRestoreGState(ctx);
}
    
- (UIImage *) getArrowImage:(UIImage*) fgImage inImage:(UIImage*) bgImage withShadow:(UIImage*)shadow
{
    UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
    [shadow drawInRect:CGRectMake(0.0, 0.0, shadow.size.width, shadow.size.height)];
    [bgImage drawInRect:CGRectMake(0.0, 0.0, bgImage.size.width, bgImage.size.height)];
    [fgImage drawInRect:CGRectMake(0.0, 0.0, fgImage.size.width, fgImage.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Supporting methods

- (CLLocation *) getMapLocation
{
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_mapViewController.mapView.target31);
    return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
}

- (CGPoint) changeCenter
{
    return CGPointMake(self.frame.size.width * 0.5,
                                    self.frame.size.height * 0.5 * _mapViewController.mapView.viewportYScale);
}

- (double) changeArrowAngle:(CLLocationCoordinate2D)current marker:(OADestination *)marker
{
    CGFloat itemDirection = [[OsmAndApp instance].locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:marker.latitude longitude:marker.longitude] sourceLocation:[[CLLocation alloc] initWithLatitude:current.latitude longitude:current.longitude]];
    CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - _mapViewController.mapView.azimuth - 90) * (M_PI / 180);
    return direction;
}

- (void) removeLineToDestinationPin:(OADestination *)destinationToRemove
{
    for (int index = 0; index < [_destinationsArray count]; index++)
    {
        if (_destinationsArray[index].latitude == destinationToRemove.latitude &&
            _destinationsArray[index].longitude == destinationToRemove.longitude)
            [_destinationsArray removeObject:_destinationsArray[index]];
    }
    [_destinationLineSublayer setNeedsDisplay];
}

- (void) touchDetected:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded)
    {
        CLLocationCoordinate2D tapPoint = [self getPointCoord:[recognizer locationInView:self]];
        _tapLocation = [[CLLocation alloc] initWithLatitude:tapPoint.latitude longitude:tapPoint.longitude];
    }
    else
    {
        _tapLocation = nil;
        [self updateLayer];
    }
}
- (CLLocationCoordinate2D) getPointCoord:(CGPoint)point
{
    point.x *= _mapViewController.mapView.contentScaleFactor;
    point.y *= _mapViewController.mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [_mapViewController.mapView convert:point toLocation:&touchLocation];
    
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

- (NSValue *) getPointFromLat:(CGFloat) lat lon:(CGFloat) lon
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
    if ((minX < x && x < maxX) && (minY < y && y < maxY))
        return nil;
    CGFloat startX = start.x;
    CGFloat startY = start.y;
    CGFloat m = (startY - y) / (startX - x);
    
    if (x <= startX) // check left side
    {
        CGFloat minXy = m * (minX - x) + y;
        if (minY <= minXy && minXy <= maxY)
            return [NSValue valueWithCGPoint:CGPointMake(minX, minXy)];
    }
    
    if (x >= startX) // check right side
    {
        CGFloat maxXy = m * (maxX - x) + y;
        if (minY <= maxXy && maxXy <= maxY)
            return [NSValue valueWithCGPoint:CGPointMake(maxX, maxXy)];
    }
    
    if (y <= startY) // check top side
    {
        CGFloat minYx = (minY - y) / m + x;
        if (minX <= minYx && minYx <= maxX)
            return [NSValue valueWithCGPoint:CGPointMake(minYx, minY)];
    }
    
    if (y >= startY) // check bottom side
    {
        CGFloat maxYx = (maxY - y) / m + x;
        if (minX <= maxYx && maxYx <= maxX)
            return [NSValue valueWithCGPoint:CGPointMake(maxYx, maxY)];
    }
    
    // edge case when finding midpoint intersection: m = 0/0 = NaN
    if (x == startX && y == startY)
        return [NSValue valueWithCGPoint:CGPointMake(x, y)];
    return nil;
}

- (double) getLineAngle:(CGPoint)start end:(CGPoint)end
{
    double dx = start.x - end.x;
    double dy = start.y - end.y;
    return dx ? atan(dy/dx) : (180 * M_PI) / 180;
}

@end
