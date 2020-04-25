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

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

#define LABEL_OFFSET 15

@implementation OADestinationsLineWidget
{
    OsmAndAppInstance _app;
    OALocationServices *_locationProvider;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    
    BOOL _oneFingerDist;
    
    OADestination *_destination;
    NSMutableArray<OADestination *> *_destinationsArray;
    
    CALayer *_destinationLineSublayer;
    NSString *_rulerDistance;
    
    NSDictionary<NSString *, NSNumber *> *_rulerLineFontAttrs;
    
    OADestinationLineDelegate *_destinationLineDelegate;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _destinationsMarkersCollection;
}

+ (OADestinationsLineWidget *)sharedInstance
{
    static OADestinationsLineWidget *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OADestinationsLineWidget alloc] init];
    });
    return _sharedInstance;
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
    _app = [OsmAndApp instance];
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _destinationsArray = [[NSMutableArray alloc] init];
    
    self.hidden = NO;
}

- (void) initDestinationLayer
{
    _destinationLineSublayer = [[CALayer alloc] init];
    _destinationLineSublayer.frame = self.bounds;
    _destinationLineSublayer.bounds = self.bounds;
    _destinationLineSublayer.contentsCenter = self.layer.contentsCenter;
    _destinationLineSublayer.contentsScale = [[UIScreen mainScreen] scale];
    _destinationLineDelegate = [[OADestinationLineDelegate alloc] initWithDestinationLine:self];
    _destinationLineSublayer.delegate = _destinationLineDelegate;
}

- (void) layoutSubviews
{
    // resize your layers based on the view's new bounds
    _destinationLineSublayer.frame = self.bounds;
}

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

//- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
//{
//    UIGraphicsPushContext(ctx);
//    
//    if (layer == self.layer)
//    {
//        
//    }
//    UIGraphicsPopContext();
//}

- (void) updateLayer
{
    [self clearLayers];
    [self initDestinationLayer];
    if (_destinationLineSublayer.superlayer != self.layer)
        [self.layer insertSublayer:_destinationLineSublayer above:self.layer];
    [_destinationLineSublayer setNeedsDisplay];
}

- (void) clearLayers
{
    for (CALayer *layer in self.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
}

- (void) drawLineToDestinationPin:(OADestination *)destination
{
    //_destination = destination;
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
    
    if (layer == _destinationLineSublayer)
    {
        CLLocation *currLoc = [_app.locationServices lastKnownLocation];
        if (currLoc) {
            
            for (OADestination* destination in _destinationsArray)
            {
                NSValue *pointOfCurrentLocation = [self getTouchPointFromLat:currLoc.coordinate.latitude lon:currLoc.coordinate.longitude];
                NSValue *touchPoint = [self getTouchPointFromLat:destination.latitude lon:destination.longitude];
                const auto dist = OsmAnd::Utilities::distance(destination.longitude, destination.latitude,
                                                              currLoc.coordinate.longitude, currLoc.coordinate.latitude);
                if (!pointOfCurrentLocation)
                {
                    CGPoint touch = touchPoint.CGPointValue;
                    CGFloat angle = 360 - [[OsmAndApp instance].locationServices radiusFromBearingToLocation:
                                           [[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude]];
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
                    CGPoint touchCGPoint = touchPoint.CGPointValue;
                    double angle = [self getLineAngle:touchCGPoint end:pointOfCurrentLocation.CGPointValue];
                    NSString *distance = [_app getFormattedDistance:dist];
                    
                    _rulerDistance = distance;
                    [self drawLineBetweenPoints:pointOfCurrentLocation.CGPointValue end:touchPoint.CGPointValue distance:distance color:destination.color inContext:ctx];
                    [self drawDistance:ctx distance:distance angle:angle start:touchCGPoint end:pointOfCurrentLocation.CGPointValue];
                }
            }
        }
    }
    UIGraphicsPopContext();
}

- (void) drawLineBetweenPoints:(CGPoint)start end:(CGPoint)end distance:(NSString *)distance color:(UIColor *)lineColor inContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    {
        UIColor *color = lineColor;
        [color set];
        CGContextSetLineWidth(ctx, 2.0);
        CGFloat dashLengths[] = {10, 10};
        CGContextSetLineDash(ctx, 30.0, dashLengths , 2);
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

- (double) getLineAngle:(CGPoint)start end:(CGPoint)end
{
    double dx = start.x - end.x;
    double dy = start.y - end.y;
    
    return dx ? atan(dy/dx) : (180 * M_PI) / 180;
}

@end
