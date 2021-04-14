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
#import "OAMapLayers.h"
#import "OAMyPositionLayer.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

#define DRAW_TIME 2
#define LABEL_OFFSET 15

@protocol OALineDrawingDelegate <NSObject>

- (void) onDrawNewLine:(OsmAnd::PointI)from to:(OsmAnd::PointI)to color:(OsmAnd::ColorARGB)color;
- (void) onHideLine;

@end

@interface OARulerByTapView()

@property (nonatomic, weak) id<OALineDrawingDelegate> lineDrawingDelegate;

@end

@interface OARulerByTapControlLayer() <UIGestureRecognizerDelegate, OALineDrawingDelegate>

@end

@implementation OARulerByTapControlLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _lineEndsMarkersCollection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _linesCollection;
    OARulerByTapView *_rulerByTapView;
    
    BOOL _showingLine;
    
    std::shared_ptr<SkBitmap> _centerIconDay;
    std::shared_ptr<SkBitmap> _centerIconNight;
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
    _rulerByTapView.lineDrawingDelegate = self;
    _rulerByTapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _linesCollection.reset(new OsmAnd::VectorLinesCollection());
    _lineEndsMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    
    _centerIconDay = [OANativeUtilities skBitmapFromPngResource:@"ic_ruler_center"];
    _centerIconNight = [OANativeUtilities skBitmapFromPngResource:@"ic_ruler_center_light"];
}

- (void) deinitLayer
{
    [super deinitLayer];
}

- (BOOL) updateLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [super updateLayer];
        
        [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                            Visibility:self.isVisible];
        if (self.isVisible)
            [self.mapView addSubview:_rulerByTapView];
        else if (_rulerByTapView.superview)
            [_rulerByTapView removeFromSuperview];
    });
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

// MARK: OALineDrawingDelegate

- (void)onDrawNewLine:(OsmAnd::PointI)from to:(OsmAnd::PointI)to color:(OsmAnd::ColorARGB)color
{
    if (!_showingLine)
    {
        [self.mapView removeKeyedSymbolsProvider:_linesCollection];
        [self.mapView removeKeyedSymbolsProvider:_lineEndsMarkersCollection];
        _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
        [self drawLine:from to:to lineId:10 color:color];
        
        _lineEndsMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        [self drawLineEnds:{from, to}];
        
        [self.mapView addKeyedSymbolsProvider:_linesCollection];
        [self.mapView addKeyedSymbolsProvider:_lineEndsMarkersCollection];
        _showingLine = YES;
    }
}

- (void)onHideLine
{
    if (_showingLine)
    {
        [self.mapView removeKeyedSymbolsProvider:_linesCollection];
        [self.mapView removeKeyedSymbolsProvider:_lineEndsMarkersCollection];
        _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
        _lineEndsMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        _showingLine = NO;
    }
}

- (void) drawLine:(OsmAnd::PointI)from to:(OsmAnd::PointI)to lineId:(int)lineId color:(OsmAnd::ColorARGB)color
{
    QVector<OsmAnd::PointI> points;
    points.push_back(from);
    points.push_back(to);
    
    double strokeWidth = 20.;
    std::vector<double> inlinePattern;
    inlinePattern.push_back(75);
    inlinePattern.push_back(45);
    
    OsmAnd::VectorLineBuilder inlineBuilder;
    inlineBuilder.setBaseOrder(self.mapViewController.mapLayers.myPositionLayer.baseOrder + lineId)
    .setIsHidden(false)
    .setLineId(lineId + 1)
    .setLineWidth(strokeWidth)
    .setLineDash(inlinePattern)
    .setPoints(points)
    .setFillColor(color);
    inlineBuilder.buildAndAddToCollection(_linesCollection);
}

- (void) drawLineEnds:(QVector<OsmAnd::PointI>)points
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    for (const auto p : points)
    {
        OsmAnd::MapMarkerBuilder builder;
        builder.setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setPinIcon(settings.nightMode ? _centerIconNight : _centerIconDay)
        .setPosition(p)
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
        
        builder.buildAndAddToCollection(_lineEndsMarkersCollection);
    }
}

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
    [self updateAttributes];
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

- (BOOL) updateLayer
{
    if (self.rulerModeOn)
    {
        if (_fingerDistanceSublayer.superlayer != self.layer)
            [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
        [_fingerDistanceSublayer setNeedsDisplay];
        [self updateAttributes];
    }
    return YES;
}

- (BOOL) updateAttributes
{
    NSDictionary<NSString *, NSNumber *> *lineAttrs = [_mapViewController getLineRenderingAttributes:@"rulerLine"];
    _rulerLineFontAttrs = [_mapViewController getLineRenderingAttributes:@"rulerLineFont"];
    BOOL changed = [_rulerLineAttrs isEqualToDictionary:lineAttrs];
    _rulerLineAttrs = lineAttrs;
    return changed;
}

- (BOOL) rulerModeOn
{
    return [_settings.showDistanceRuler get];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    _fingerDistanceSublayer.frame = self.bounds;
}

- (void) drawFingerRulerLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    if (layer == _fingerDistanceSublayer)
    {
        NSNumber *colorAttr = _rulerLineAttrs ? [_rulerLineAttrs objectForKey:@"color"] : @(0xff000000);
        if (_oneFingerDist && !_twoFingersDist)
        {
            CLLocation *currLoc = [_app.locationServices lastKnownLocation];
            if (currLoc)
            {
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, currLoc.coordinate.longitude, currLoc.coordinate.latitude);
                const OsmAnd::LatLon fromLatLon(currLoc.coordinate.latitude, currLoc.coordinate.longitude);
                const auto fromI = OsmAnd::Utilities::convertLatLonTo31(fromLatLon);
                const OsmAnd::LatLon toLatLon(_tapPointOne.latitude, _tapPointOne.longitude);
                const auto toI = OsmAnd::Utilities::convertLatLonTo31(toLatLon);
                NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:currLoc.coordinate.latitude fromLon:currLoc.coordinate.longitude toLat:_tapPointOne.latitude toLon:_tapPointOne.longitude];
                if (linePoints.count == 2)
                {
                    CGPoint a = linePoints[0].CGPointValue;
                    CGPoint b = linePoints[1].CGPointValue;
                    double angle = [OAMapUtils getAngleBetween:a end:b];
                    NSString *distance = [_app getFormattedDistance:dist];
                    _rulerDistance = distance;
                    if (self.lineDrawingDelegate)
                        [self.lineDrawingDelegate onDrawNewLine:fromI to:toI color:OsmAnd::ColorARGB(colorAttr.intValue)];
                    [self drawDistance:ctx distance:distance angle:angle start:a end:b];
                }
            }
        }
        if (_twoFingersDist && !_oneFingerDist)
        {
            const OsmAnd::LatLon fromLatLon(_tapPointOne.latitude, _tapPointOne.longitude);
            const auto fromI = OsmAnd::Utilities::convertLatLonTo31(fromLatLon);
            const OsmAnd::LatLon toLatLon(_tapPointTwo.latitude, _tapPointTwo.longitude);
            const auto toI = OsmAnd::Utilities::convertLatLonTo31(toLatLon);
            NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:_tapPointOne.latitude fromLon:_tapPointOne.longitude toLat:_tapPointTwo.latitude toLon:_tapPointTwo.longitude];
            if (linePoints.count == 2)
            {
                CGPoint a = linePoints[0].CGPointValue;
                CGPoint b = linePoints[1].CGPointValue;
                double angle = [OAMapUtils getAngleBetween:a end:b];
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, _tapPointTwo.longitude, _tapPointTwo.latitude);
                NSString *distance = [_app getFormattedDistance:dist];
                _rulerDistance = distance;
                if (self.lineDrawingDelegate)
                    [self.lineDrawingDelegate onDrawNewLine:fromI to:toI color:OsmAnd::ColorARGB(colorAttr.intValue)];
                [self drawDistance:ctx distance:distance angle:angle start:a end:b];
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

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return [self rulerModeOn];
}

- (void) touchDetected:(UITapGestureRecognizer *)recognizer
{
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    if (self.lineDrawingDelegate)
        [self.lineDrawingDelegate onHideLine];

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
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideTouchRuler) object:self];
    [self performSelector:@selector(hideTouchRuler) withObject:self afterDelay:DRAW_TIME];
}

- (void) hideTouchRuler
{
    _rulerDistance = nil;
    _oneFingerDist = NO;
    _twoFingersDist = NO;
    if (_fingerDistanceSublayer.superlayer == self.layer)
        [_fingerDistanceSublayer removeFromSuperlayer];
    
    if (self.lineDrawingDelegate)
        [self.lineDrawingDelegate onHideLine];
}

- (void) onMapSourceUpdated
{
    if ([self rulerModeOn])
    {
        [self setNeedsDisplay];
        [self updateAttributes];
    }
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
