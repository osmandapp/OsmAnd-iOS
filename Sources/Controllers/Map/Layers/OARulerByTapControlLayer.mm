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

#define DRAW_TIME 2
#define LABEL_OFFSET 15

@interface OARulerByTapControlLayer() <UIGestureRecognizerDelegate>

@end

@implementation OARulerByTapControlLayer
{
    OARulerByTapView *_rulerByTapView;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    return self;
}

- (NSString *) layerId
{
    return kRulerByTapControlLayerId;
}

- (void) initLayer
{
    [super initLayer];

    _rulerByTapView = [[OARulerByTapView alloc] initWithFrame:CGRectMake(0, 0, DeviceScreenWidth, DeviceScreenHeight)];
}

- (void) deinitLayer
{
    [super deinitLayer];
}

- (BOOL) updateLayer
{
    [super updateLayer];
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];
    if (self.isVisible)
        [self.mapView addSubview:_rulerByTapView];
    else
        [_rulerByTapView removeFromSuperview];
    
    return YES;
}

- (BOOL) isVisible
{
    return [[OAAppSettings sharedManager].showDistanceRuler get];
}

- (void) onMapFrameRendered
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_rulerByTapView updateLayer];
    });
}

@end

@interface OARulerByTapView()

@end

@implementation OARulerByTapView
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
  
    BOOL _oneFingerDist;
    BOOL _twoFingersDist;
    
    CLLocationCoordinate2D _tapPointOne;
    CLLocationCoordinate2D _tapPointTwo;
    
    NSDictionary<NSString *, NSNumber *> *_rulerLineAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerLineFontAttrs;
    
    CALayer *_fingerDistanceSublayer;
    OAFingerRulerDelegate *_fingerRulerDelegate;
    
    UITapGestureRecognizer* _singleGestureRecognizer;
    UITapGestureRecognizer* _doubleGestureRecognizer;
    UILongPressGestureRecognizer *_longSingleGestureRecognizer;
    UILongPressGestureRecognizer *_longDoubleGestureRecognizer;
    
    UIImage *_centerIconDay;
    UIImage *_centerIconNight;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.frame = frame;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
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
    
    [self initFingerLayer];
 
    _centerIconDay = [UIImage imageNamed:@"ic_ruler_center.png"];
    _centerIconNight = [UIImage imageNamed:@"ic_ruler_center_light.png"];
}

- (void) initFingerLayer
{
    _fingerDistanceSublayer = [[CALayer alloc] init];
    _fingerDistanceSublayer.frame = self.bounds;
    _fingerDistanceSublayer.bounds = self.bounds;
    _fingerDistanceSublayer.contentsCenter = self.layer.contentsCenter;
    _fingerDistanceSublayer.contentsScale = [[UIScreen mainScreen] scale];
    _fingerRulerDelegate = [[OAFingerRulerDelegate alloc] initWithRulerLayer:self];
    _fingerDistanceSublayer.delegate = _fingerRulerDelegate;
}

- (void) layoutSubviews
{
    // resize your layers based on the view's new bounds
    [super layoutSubviews];
    _fingerDistanceSublayer.frame = self.bounds;
}

- (BOOL) updateLayer
{
    if (_fingerDistanceSublayer.superlayer != self.layer)
        [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
    [_fingerDistanceSublayer setNeedsDisplay];
    return YES;
}

- (BOOL) rulerModeOn
{
    return [_settings.showDistanceRuler get];
}

- (void) drawLineFrom:(CGPoint)startPoint stopPoint:(CGPoint)stopPoint color:(UIColor *)color strokeWidth:(CGFloat)strokeWidth inContext:(CGContextRef)ctx
{
    [color set];
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(ctx, stopPoint.x, stopPoint.y);
    CGContextStrokePath(ctx);
}

- (void) drawLineByPoints:(NSMutableArray<NSValue *> *)points color:(UIColor *)color strokeWidth:(CGFloat)strokeWidth inContext:(CGContextRef)ctx
{
    BOOL isEmpty = YES;
    for (NSValue *pointValue in points)
    {
        CGPoint point = pointValue.CGPointValue;
        if (isEmpty)
        {
            isEmpty = NO;
            CGContextMoveToPoint(ctx, point.x, point.y);
        }
        else
        {
            CGContextAddLineToPoint(ctx, point.x, point.y);
        }
    }
    [color set];
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextStrokePath(ctx);
}

- (void) drawFingerRulerLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    if (layer == _fingerDistanceSublayer)
    {
        if (_oneFingerDist && !_twoFingersDist)
        {
            CLLocation *currLoc = [_app.locationServices lastKnownLocation];
            if (currLoc)
            {
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, currLoc.coordinate.longitude, currLoc.coordinate.latitude);
                NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:currLoc.coordinate.latitude fromLon:currLoc.coordinate.longitude toLat:_tapPointOne.latitude toLon:_tapPointOne.longitude];
                if (linePoints.count == 2)
                {
                    CGPoint a = linePoints[0].CGPointValue;
                    CGPoint b = linePoints[1].CGPointValue;
                    double angle = [OAMapUtils getAngleBetween:a end:b];
                    NSString *distance = [_app getFormattedDistance:dist];
                    _rulerDistance = distance;
                    [self drawLineBetweenPoints:a end:b context:ctx distance:distance];
                    [self drawDistance:ctx distance:distance angle:angle start:a end:b];
                    if ([_mapViewController isLocationVisible:_tapPointOne.latitude longitude:_tapPointOne.longitude])
                    {
                        UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
                        CGRect pointRect = CGRectMake(b.x - iconToUse.size.width / 2, b.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                        [iconToUse drawInRect:pointRect];
                    }
                }
            }
        }
        if (_twoFingersDist && !_oneFingerDist)
        {
            NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:_tapPointOne.latitude fromLon:_tapPointOne.longitude toLat:_tapPointTwo.latitude toLon:_tapPointTwo.longitude];
            if (linePoints.count == 2)
            {
                CGPoint a = linePoints[0].CGPointValue;
                CGPoint b = linePoints[1].CGPointValue;
                double angle = [OAMapUtils getAngleBetween:a end:b];
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, _tapPointTwo.longitude, _tapPointTwo.latitude);
                NSString *distance = [_app getFormattedDistance:dist];
                _rulerDistance = distance;
                [self drawLineBetweenPoints:a end:b context:ctx distance:distance];
                [self drawDistance:ctx distance:distance angle:angle start:a end:b];
                UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
                if ([_mapViewController isLocationVisible:_tapPointOne.latitude longitude:_tapPointOne.longitude])
                {
                    CGRect pointOneRect = CGRectMake(a.x - iconToUse.size.width / 2, a.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                    [iconToUse drawInRect:pointOneRect];
                }
                if ([_mapViewController isLocationVisible:_tapPointTwo.latitude longitude:_tapPointTwo.longitude])
                {
                    CGRect pointTwoRect = CGRectMake(b.x - iconToUse.size.width / 2, b.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                    [iconToUse drawInRect:pointTwoRect];
                }
            }
        }
    }
    UIGraphicsPopContext();
}

- (void) drawDistance:(CGContextRef)ctx distance:(NSString *)distance angle:(double)angle start:(CGPoint)start end:(CGPoint)end
{
    CGPoint middlePoint = CGPointMake((start.x + end.x) / 2, (start.y + end.y) / 2);
    UIFont *font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    
    BOOL useDefaults = !_rulerLineFontAttrs || [_rulerLineFontAttrs count] == 0;
    NSNumber *strokeColorAttr = useDefaults ? nil : [_rulerLineFontAttrs objectForKey:@"color_2"];
    UIColor *strokeColor = strokeColorAttr ? UIColorFromARGB(strokeColorAttr.intValue) : [UIColor whiteColor];
    NSNumber *colorAttr = useDefaults ? nil : [_rulerLineFontAttrs objectForKey:@"color"];
    UIColor *color = colorAttr ? UIColorFromARGB(colorAttr.intValue) : [UIColor blackColor];
    NSNumber *strokeWidthAttr = useDefaults ? nil : [_rulerLineFontAttrs valueForKey:@"strokeWidth_2"];
    float strokeWidth = (strokeWidthAttr ? strokeWidthAttr.floatValue / [[UIScreen mainScreen] scale] : 4.0) * 4.0;
    
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;

    NSAttributedString *string = [OAUtilities createAttributedString:distance font:font color:color strokeColor:nil strokeWidth:0];
    NSAttributedString *shadowString = [OAUtilities createAttributedString:distance font:font color:color strokeColor:strokeColor strokeWidth:strokeWidth];

    CGSize titleSize = [string size];
    CGRect rect = CGRectMake(middlePoint.x - (titleSize.width / 2), middlePoint.y - (titleSize.height / 2), titleSize.width, titleSize.height);
    
    CGFloat xMid = CGRectGetMidX(rect);
    CGFloat yMid = CGRectGetMidY(rect);
    CGContextSaveGState(ctx);
    {
        CGContextTranslateCTM(ctx, xMid, yMid);
        CGContextRotateCTM(ctx, angle);
        
        CGRect newRect = rect;
        newRect.origin.x = -newRect.size.width / 2;
        newRect.origin.y = -newRect.size.height / 2 + LABEL_OFFSET;
        
        [shadowString drawWithRect:newRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        [string drawWithRect:newRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
}

- (void) drawLineBetweenPoints:(CGPoint) start end:(CGPoint) end context:(CGContextRef) ctx distance:(NSString *) distance
{
    CGContextSaveGState(ctx);
    {
        NSNumber *colorAttr = _rulerLineAttrs ? [_rulerLineAttrs objectForKey:@"color"] : nil;
        UIColor *color = colorAttr ? UIColorFromARGB(colorAttr.intValue) : [UIColor blackColor];
        [color set];
        CGContextSetLineWidth(ctx, 4.0);
        CGFloat dashLengths[] = {10, 5};
        CGContextSetLineDash(ctx, 0.0, dashLengths , 2);
        CGContextMoveToPoint(ctx, start.x, start.y);
        CGContextAddLineToPoint(ctx, end.x, end.y);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return [self rulerModeOn];
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
        if (_fingerDistanceSublayer.superlayer != self.layer)
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
        if (_fingerDistanceSublayer.superlayer != self.layer)
            [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
        [_fingerDistanceSublayer setNeedsDisplay];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(hideTouchRuler) object: self];
    [self performSelector:@selector(hideTouchRuler) withObject: self afterDelay: DRAW_TIME];
}

- (void) hideTouchRuler
{
    _rulerDistance = nil;
    _oneFingerDist = NO;
    _twoFingersDist = NO;
    if (_fingerDistanceSublayer.superlayer == self.layer)
        [_fingerDistanceSublayer removeFromSuperlayer];
}

- (void) onMapSourceUpdated
{
    if ([self rulerModeOn])
        [self setNeedsDisplay];
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
