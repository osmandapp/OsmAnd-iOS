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
#import "OAMapUtils.h"
#import "OATextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OAFingerRulerDelegate.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAAutoObserverProxy.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/Utilities.h>

#define kMapRulerMaxWidth 120
#define DRAW_TIME 2
#define LABEL_OFFSET 15
#define CIRCLE_ANGLE_STEP 5
#define TITLE_PADDING 2
#define COMPASS_INDEX 2

#define SHOW_RULER_MIN_ZOOM 3
#define SHOW_COMPASS_MIN_ZOOM 8
#define ZOOM_UPDATING_THRESHOLD 0.05
#define RULER_ROTATION_UPDATING_THRESHOLD 1
#define ARROW_ROTATION_UPDATING_THRESHOLD 2
#define ELEVATION_UPDATING_THRESHOLD 2
#define TARGET31_UPDATING_THRESHOLD 1000000
#define FRAMES_PER_SECOND 10

typedef NS_ENUM(NSInteger, EOATextSide) {
    EOATextSideVertical = 0,
    EOATextSideHorizontal
};

@interface OARulerWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation OARulerWidget
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    EOATextSide _textSide;
    double _radius;
    double _maxRadius;
    double _roundedDist;
    
    float _cachedViewportScale;
    CGFloat _cachedWidth;
    CGFloat _cachedHeight;
    float _cachedMapElevation;
    float _cachedMapAzimuth;
    CLLocationDirection _cachedHeading;
    float _cachedMapZoom;
    int _cacheIntZoom;
    double _mapScale;
    double _mapScaleUnrounded;
    NSTimeInterval _cachedTimestamp;
    
    OACommonDouble *_mapDensity;
    double _cachedMapDensity;
    EOAMetricsConstant _cacheMetricSystem;
    EOARulerWidgetMode _cachedRulerMode;
    BOOL _cachedMapMode;
    
    OsmAnd::PointI _cachedCenter31;
    OsmAnd::LatLon _cachedCenterLatLon;
    CGPoint _cachedCenter;
    NSMutableArray<NSString *> *_cacheDistances;

    NSMutableArray<NSNumber *> *_degrees;
    NSArray<NSString *> *_cardinalDirections;

    NSDictionary<NSString *, NSNumber *> *_rulerCircleAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerCircleAltAttrs;

    UIColor *_circleColor;
    UIColor *_cardinalLinesColor;
    float _strokeWidth;
    UIColor *_textColor;
    UIColor *_textShadowColor;
    UIFont *_font;
    UIFont *_boldFont;
    float _strokeWidthText;
    CGColor *_shadowColor;
    float _shadowRadius;
    UIColor *_northArrowColor;
    UIColor *_headingArrowColor;
    
    UIImage *_centerIconDay;
    UIImage *_centerIconNight;
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
    {
        self.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight);
        [self commonInit];
    }
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

    _mapDensity = _settings.mapDensity;
    _cachedMapDensity = [_mapDensity get];
    _cacheMetricSystem = [_settings.metricSystem get];
    _cacheDistances = [NSMutableArray new];
    _cachedCenter = CGPointMake(0, 0);
    
    _cardinalDirections = @[ @"N", @"NE", @"E", @"SE", @"S", @"SW", @"W", @"NW"];
    _centerIconDay = [UIImage imageNamed:@"ic_ruler_center.png"];
    _centerIconNight = [UIImage imageNamed:@"ic_ruler_center_light.png"];
    _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
    self.hidden = YES;

    _degrees = [NSMutableArray arrayWithCapacity:72];
    for (int i = 0; i < 72; i++)
    {
        _degrees[i] = [NSNumber numberWithDouble:[self toRadians:(i * 5)]];
    }
    
    _cachedTimestamp = [[NSDate date] timeIntervalSince1970];
}

- (void) updateStyles
{
    _cachedMapMode = _settings.nightMode;

    _rulerCircleAttrs = [_mapViewController getLineRenderingAttributes:@"rulerCircle"];
    _rulerCircleAltAttrs = [_mapViewController getLineRenderingAttributes:@"rulerCircleAlt"];
 
    BOOL hasAttributes = _rulerCircleAttrs && _rulerCircleAltAttrs && [_rulerCircleAttrs count] != 0 && [_rulerCircleAltAttrs count] != 0;
    double scaleFactor = [_settings.mapDensity get:_settings.applicationMode.get];
    
    NSNumber *circleColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color"] : [_rulerCircleAltAttrs valueForKey:@"color"]) :
                nil;
    _circleColor = circleColorAttr ? UIColorFromARGB(circleColorAttr.intValue) : [UIColor blackColor];
    
    NSNumber *textShadowColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color_3"] : [_rulerCircleAltAttrs valueForKey:@"color_3"]) :
                nil;
    _textShadowColor =  textShadowColorAttr ? UIColorFromARGB(textShadowColorAttr.intValue) : [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    
    NSNumber *shadowColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"shadowColor"] : [_rulerCircleAltAttrs valueForKey:@"shadowColor"]) :
                nil;
    _shadowColor = shadowColorAttr ? UIColorFromARGB(shadowColorAttr.intValue).CGColor : nil;
    
    _strokeWidth = (hasAttributes && [_rulerCircleAttrs valueForKey:@"strokeWidth"]) ? [_rulerCircleAttrs valueForKey:@"strokeWidth"].floatValue : 1.0;
    _strokeWidth = scaleFactor < 1.0 ? 1.0 : _strokeWidth / [[UIScreen mainScreen] scale] / scaleFactor;
    _strokeWidthText = ((hasAttributes && [_rulerCircleAttrs valueForKey:@"strokeWidth_3"]) ? [_rulerCircleAttrs valueForKey:@"strokeWidth_3"].floatValue / scaleFactor : 6.0) * 3.0;
                
    _shadowRadius = hasAttributes && [_rulerCircleAttrs valueForKey:@"shadowRadius"] ? [_rulerCircleAttrs valueForKey:@"shadowRadius"].floatValue / scaleFactor : 3.0;
                
    NSNumber *textColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color_2"] : [_rulerCircleAltAttrs valueForKey:@"color_2"]) :
                nil;
    _textColor =  textColorAttr ? UIColorFromARGB(textColorAttr.intValue) : [UIColor blackColor];
                
    _font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    _boldFont = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    
    _cardinalLinesColor = UIColor.redColor;
    _northArrowColor = UIColor.redColor;
    _headingArrowColor = UIColor.blueColor;
    
    BOOL showLightCenterIcon;
    if (_cachedRulerMode == RULER_MODE_NO_CIRCLES)
        showLightCenterIcon = _settings.nightMode;
    else if (!_settings.nightMode)
        showLightCenterIcon = _cachedRulerMode == RULER_MODE_LIGHT;
    else
        showLightCenterIcon = YES;
    _imageView.image = showLightCenterIcon ? _centerIconNight : _centerIconDay;
}

- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    CGContextSaveGState(ctx);

    if ([self rulerModeOn] && [_mapViewController getMapZoom] > SHOW_RULER_MIN_ZOOM)
    {
        [self updateStyles];

        auto circleCenterPos31 = _mapViewController.mapView.target31;
        CGPoint circleCenterPoint;
        [_mapViewController.mapView convert:&circleCenterPos31 toScreen:&circleCenterPoint checkOffScreen:YES];
        
        EOARulerWidgetMode mode = _settings.rulerMode.get;
        BOOL showCompass = _settings.showCompassControlRuler.get && [_mapViewController getMapZoom] > SHOW_COMPASS_MIN_ZOOM;
        
        _imageView.center = CGPointMake(self.frame.size.width * 0.5,
                                        self.frame.size.height * 0.5 * _mapViewController.mapView.viewportYScale);
        
        if (mode == RULER_MODE_DARK || mode == RULER_MODE_LIGHT )
        {
            [self updateData:circleCenterPoint];
            if (showCompass)
                [self updateHeading];
            
            int compassCircleId = [self getCompassCircleId:circleCenterPoint];
            for (NSUInteger i = _cacheDistances.count; i >= 1; i--)
            {
                if (showCompass && i == compassCircleId)
                    [self drawCompassCircle:compassCircleId center:circleCenterPoint inContext:ctx];
                else
                    [self drawCircle:i center:circleCenterPoint inContext:ctx];
            }
        }
    }
    CGContextRestoreGState(ctx);
    UIGraphicsPopContext();
}

- (BOOL) rulerModeOn
{
    return [[OARootViewController instance].mapPanel.mapWidgetRegistry isVisible:@"radius_ruler"] && [self rulerWidgetOn];;
}

- (int) getCompassCircleId:(CGPoint)center
{
    int compassCircleId = 2;
    CGFloat radiusLength = _radius * compassCircleId;
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    NSNumber *leftMargin = [NSNumber numberWithFloat: center.x];
    NSNumber *rightMargin = [NSNumber numberWithFloat: width - center.x];
    NSNumber *topMargin = [NSNumber numberWithFloat: center.y];
    NSNumber *bottomMargin = [NSNumber numberWithFloat: height - center.y];
    NSArray<NSNumber *> *allMargins = @[leftMargin, rightMargin, topMargin, bottomMargin];
    
    NSNumber *nearestScreenMargin = [[allMargins sortedArrayUsingSelector: @selector(compare:)] firstObject];
    if (radiusLength > nearestScreenMargin.floatValue)
        compassCircleId = 1;
    
    return compassCircleId;
}

- (void) updateHeading
{
    CLLocationDirection heading = _app.locationServices.lastKnownHeading;
    if (heading && (int(_cachedHeading) != int(heading)))
        _cachedHeading = heading;
}

- (void) updateData:(CGPoint)center
{
    if (self.bounds.size.height > 0 && self.bounds.size.width > 0 && _maxRadius > 0)
    {
        if (_cachedCenter.y != center.y || _cachedCenter.x != center.x)
        {
            _cachedCenter = center;
            [self updateCenter:center];
        }
    }
    
    EOAMetricsConstant currentMetricSystem = [_settings.metricSystem get];
    _cacheMetricSystem = currentMetricSystem;
    _cachedMapZoom = _mapViewController.mapView.zoom;
    _cacheIntZoom = int(_mapViewController.getMapZoom);
    _cachedCenter31 = _mapViewController.mapView.target31;
    _cachedCenterLatLon = OsmAnd::Utilities::convert31ToLatLon(_mapViewController.mapView.target31);
    _cachedMapDensity = [_mapDensity get];
    _cachedMapElevation = _mapViewController.mapView.elevationAngle;
    _cachedHeading = _app.locationServices.lastKnownHeading;
    _cachedMapAzimuth = _mapViewController.mapView.azimuth;
    _cachedTimestamp = [[NSDate date] timeIntervalSince1970];
    _cachedViewportScale = _mapViewController.mapView.viewportYScale;
    _cachedWidth = self.bounds.size.width;
    _cachedHeight = self.bounds.size.height;
    
    [self updateDistance];
}

- (void) updateCenter:(CGPoint)center
{
    CGFloat topDist = center.y;
    CGFloat bottomDist = self.bounds.size.height - center.y;
    CGFloat leftDist = center.x;
    CGFloat rightDist = self.bounds.size.width - center.x;
    CGFloat maxVertical = topDist >= bottomDist ? topDist : bottomDist;
    CGFloat maxHorizontal = rightDist >= leftDist ? rightDist : leftDist;
    
    if (maxVertical >= maxHorizontal)
    {
        _maxRadius = maxVertical;
        _textSide = EOATextSideVertical;
    }
    else
    {
        _maxRadius = maxHorizontal;
        _textSide = EOATextSideHorizontal;
    }
    if (_radius != 0)
        [self updateText];
}

- (void) updateDistance
{
    _cachedMapDensity = _mapViewController.mapView.currentPixelsToMetersScaleFactor;
    double fullMapScale = _cachedMapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
    _mapScaleUnrounded = fullMapScale;
    _roundedDist = [OAOsmAndFormatter calculateRoundedDist:_mapScaleUnrounded];
    _radius = _mapScale / _cachedMapDensity / [[UIScreen mainScreen] scale];
    [self updateText];
}

- (void) updateText
{
    _cacheDistances = [NSMutableArray new];
    double maxCircleRadius = _maxRadius;
    int i = 1;
    while ((maxCircleRadius -= _radius) > 0)
        [_cacheDistances addObject:[OAOsmAndFormatter getFormattedDistance:(_roundedDist * i++)]];
}

- (void) drawCircle:(int)circleNumber center:(CGPoint)center inContext:(CGContextRef)ctx
{
    if (!_mapViewController.zoomingByGesture)
    {
        double circleRadius = _radius * circleNumber;
        NSString *text = _cacheDistances[circleNumber - 1];
        
        CGPoint topOrLeftPoint = CGPointZero;
        CGPoint rightOrBottomPoint = CGPointZero;
        NSMutableArray<NSMutableArray<NSValue *> *> *arrays = [NSMutableArray array];
        NSMutableArray<NSValue *> *points = [NSMutableArray array];
        auto centerLatLon = OsmAnd::Utilities::convert31ToLatLon(_mapViewController.mapView.target31);
        
        for (int a = -180; a <= 180; a+= CIRCLE_ANGLE_STEP)
        {
            double pixelDensity = _cachedMapDensity * [[UIScreen mainScreen] scale];
            auto latLon = OsmAnd::Utilities::rhumbDestinationPoint(centerLatLon, circleRadius * pixelDensity, a);
            if (ABS(latLon.latitude) > 90 || ABS(latLon.longitude) > 180)
            {
                if (points.count > 0)
                {
                    [arrays addObject:points];
                    points = [NSMutableArray array];
                }
                continue;
            }
            
            auto pos31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
            CGPoint screenPoint;
            [_mapViewController.mapView convert:&pos31 toScreen:&screenPoint checkOffScreen:YES];
            [points addObject:[NSValue valueWithCGPoint:screenPoint]];
            
            if (_textSide == EOATextSideVertical)
            {
                if (a == 0)
                    topOrLeftPoint = CGPointMake(screenPoint.x, screenPoint.y);
                else if (a == 180)
                    rightOrBottomPoint = CGPointMake(screenPoint.x, screenPoint.y);
            }
            else if (_textSide == EOATextSideHorizontal)
            {
                if (a == -90)
                    topOrLeftPoint = CGPointMake(screenPoint.x, screenPoint.y);
                else if (a == 90)
                    rightOrBottomPoint = CGPointMake(screenPoint.x, screenPoint.y);
            }
        }
        if (points.count > 0)
            [arrays addObject:points];

        for (NSMutableArray<NSValue *> *points in arrays)
        {
            [self drawLineByPoints:points color:_textShadowColor strokeWidth:_strokeWidth*3 inContext:ctx];
            [self drawLineByPoints:points color:_circleColor strokeWidth:_strokeWidth inContext:ctx];
        }
        
        NSArray<NSValue *> *textCoords = [self calculateTextCoords:text rightOrBottomText:text topOrLeftPoint:topOrLeftPoint rightOrBottomPoint:rightOrBottomPoint];
        [self drawTextCoords: text textCoords:textCoords font:_font];
    }
}

- (void) drawTextCoords:(NSString *)text textCoords:(NSArray<NSValue *> *)textCoords font:(UIFont *)font
{
    NSAttributedString *distString = [OAUtilities createAttributedString:text font:font color:_textColor strokeColor:nil strokeWidth:0 alignment:NSTextAlignmentCenter];
    NSAttributedString *distShadowString = [OAUtilities createAttributedString:text font:font color:_textColor strokeColor:_textShadowColor strokeWidth:_strokeWidthText alignment:NSTextAlignmentCenter];
    
    if (textCoords.count > 0 && textCoords[0])
    {
        [distShadowString drawAtPoint:CGPointMake(textCoords[0].CGPointValue.x, textCoords[0].CGPointValue.y)];
        [distString drawAtPoint:CGPointMake(textCoords[0].CGPointValue.x, textCoords[0].CGPointValue.y)];
    }
    if (textCoords.count > 1 && textCoords[1])
    {
        [distShadowString drawAtPoint:CGPointMake(textCoords[1].CGPointValue.x, textCoords[1].CGPointValue.y)];
        [distString drawAtPoint:CGPointMake(textCoords[1].CGPointValue.x, textCoords[1].CGPointValue.y)];
    }
}

- (NSArray<NSValue *> *) calculateTextCoords:(NSString *)topOrLeftText rightOrBottomText:(NSString *)rightOrBottomText topOrLeftPoint:(CGPoint)topOrLeftPoint rightOrBottomPoint:(CGPoint)rightOrBottomPoint
{
    CGSize boundsDistance;
    CGSize boundsHeading;
    
    boundsDistance = [[OAUtilities createAttributedString:topOrLeftText font:_font color:_textColor strokeColor:nil strokeWidth:0 alignment:NSTextAlignmentCenter] size];
    if ([topOrLeftText isEqualToString:rightOrBottomText])
        boundsHeading = boundsDistance;
    else
        boundsHeading = [[OAUtilities createAttributedString:rightOrBottomText font:_font color:_textColor strokeColor:nil strokeWidth:0 alignment:NSTextAlignmentCenter] size];
    
    CGPoint topOrLeftCoordinate = CGPointZero;
    CGPoint rightOrBottomCoordinate = CGPointZero;
    topOrLeftCoordinate.x = topOrLeftPoint.x - boundsHeading.width / 2;
    topOrLeftCoordinate.y = topOrLeftPoint.y - boundsHeading.height / 2;
    rightOrBottomCoordinate.x = rightOrBottomPoint.x - boundsDistance.width / 2;
    rightOrBottomCoordinate.y = rightOrBottomPoint.y - boundsDistance.height / 2;
    return @[ [NSValue valueWithCGPoint:topOrLeftCoordinate], [NSValue valueWithCGPoint:rightOrBottomCoordinate]];
}

- (NSArray<NSValue *> *) calculateTextCoords:(NSString *)topOrLeftText rightOrBottomText:(NSString *)rightOrBottomText drawingTextRadius:(double)drawingTextRadius center:(CGPoint)center
{
    CGSize boundsDistance;
    CGSize boundsHeading;
    
    boundsDistance = [[OAUtilities createAttributedString:rightOrBottomText font:_font color:_textColor strokeColor:nil strokeWidth:0 alignment:NSTextAlignmentCenter] size];
    if ([topOrLeftText isEqualToString:rightOrBottomText])
        boundsHeading = boundsDistance;
    else
        boundsHeading = [[OAUtilities createAttributedString:topOrLeftText font:_boldFont color:_textColor strokeColor:nil strokeWidth:0 alignment:NSTextAlignmentCenter] size];

    CGPoint topOrLeftCoordinate = CGPointZero;
    CGPoint rightOrBottomCoordinate = CGPointZero;
    
    if (_textSide == EOATextSideVertical)
    {
        topOrLeftCoordinate.x = center.x - boundsHeading.width / 2;
        topOrLeftCoordinate.y = center.y - drawingTextRadius - boundsHeading.height / 2;
        rightOrBottomCoordinate.x = center.x - boundsDistance.width / 2;
        rightOrBottomCoordinate.y = center.y + drawingTextRadius - boundsDistance.height / 2;
        return @[[NSValue valueWithCGPoint:[self transformTo3D:topOrLeftCoordinate compensateMapRotation:YES]], [NSValue valueWithCGPoint:[self transformTo3D:rightOrBottomCoordinate compensateMapRotation:YES]]];
    }
    else if (_textSide == EOATextSideHorizontal)
    {
        topOrLeftCoordinate.x = center.x - drawingTextRadius - boundsHeading.width;
        topOrLeftCoordinate.y = center.y - boundsHeading.height / 2;
        rightOrBottomCoordinate.x = center.x + drawingTextRadius;
        rightOrBottomCoordinate.y = center.y - boundsDistance.height / 2;
    }
    return @[[NSValue valueWithCGPoint:topOrLeftCoordinate], [NSValue valueWithCGPoint:rightOrBottomCoordinate]];
}

- (void) drawCompassCircle:(int)circleNumber center:(CGPoint)center inContext:(CGContextRef)ctx
{
    if (!_mapViewController.zoomingByGesture)
    {
        double radiusLength = _radius * circleNumber;
        double innerRadiusLength = radiusLength - _strokeWidth / 2;
        
        [self updateCompassPaths:center innerRadiusLength:innerRadiusLength radiusLength:radiusLength inContext:ctx];
        [self drawCardinalDirections:center radiusLength:radiusLength];
        
        //drawing circle
        NSMutableArray<NSMutableArray<NSValue *> *> *arrays = [NSMutableArray array];
        NSMutableArray<NSValue *> *points = [NSMutableArray array];
        auto centerLatLon = OsmAnd::Utilities::convert31ToLatLon(_mapViewController.mapView.target31);
        for (int a = -180; a <= 180; a+= CIRCLE_ANGLE_STEP)
        {
            double pixelDensity = _cachedMapDensity * [[UIScreen mainScreen] scale];
            auto latLon = OsmAnd::Utilities::rhumbDestinationPoint(centerLatLon, radiusLength * pixelDensity, a);
            
            if (ABS(latLon.latitude) > 90 || ABS(latLon.longitude) > 180)
            {
                if (points.count > 0)
                {
                    [arrays addObject:points];
                    points = [NSMutableArray array];
                }
                continue;
            }
            
            auto pos31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
            CGPoint screenPoint;
            [_mapViewController.mapView convert:&pos31 toScreen:&screenPoint checkOffScreen:YES];
            [points addObject:[NSValue valueWithCGPoint:screenPoint]];
        }
        if (points.count > 0)
            [arrays addObject:points];

        for (NSMutableArray<NSValue *> *points in arrays)
        {
            [self drawLineByPoints:points color:_textShadowColor strokeWidth:_strokeWidth*3 inContext:ctx];
            [self drawLineByPoints:points color:_circleColor strokeWidth:_strokeWidth inContext:ctx];
        }
        
        NSString *distance = _cacheDistances[circleNumber - 1];
        NSString *heading = [NSString stringWithFormat:@"%@ %@", [OAOsmAndFormatter getFormattedAzimuth:_cachedHeading], [self getCardinalDirectionForDegrees:_cachedHeading]];
        
        double offset = _textSide == EOATextSideHorizontal ? 5 : 20;
        double drawingTextRadius = radiusLength + offset;
        
        NSArray<NSValue *> *textCoords = [self calculateTextCoords:heading rightOrBottomText:distance drawingTextRadius:drawingTextRadius center:center];
        [self drawTextCoords: heading textCoords:@[textCoords[0]] font:_boldFont];
        [self drawTextCoords: distance textCoords:@[textCoords[1]] font:_font];
        
        [self drawTriangleArrowByRadius:radiusLength angle:0 center:center color:_northArrowColor inContext:ctx];
        [self drawTriangleArrowByRadius:radiusLength angle:_cachedHeading center:center color:_headingArrowColor inContext:ctx];
    }
}

- (void) updateCompassPaths:(CGPoint)center innerRadiusLength:(double)innerRadiusLength radiusLength:(double)radiusLength inContext:(CGContextRef)ctx
{
    for (int i = 0; i < _degrees.count; i++)
    {
        double degree = _degrees[i].floatValue;
        CGFloat x = cos(degree);
        CGFloat y = -sin(degree);
        
        CGFloat lineStartX = center.x + x * innerRadiusLength;
        CGFloat lineStartY = center.y + y * innerRadiusLength;
        
        CGFloat lineLength = [self getCompassLineHeight:i];
        
        CGFloat lineStopX = center.x + x * (innerRadiusLength - lineLength);
        CGFloat lineStopY = center.y + y * (innerRadiusLength - lineLength);
        
        if (i == 18)
        {
            CGFloat shortLineMargin = 5.66;
            CGFloat shortLineHeight = 5.66;
            CGFloat startY = center.y + y * (radiusLength - shortLineMargin);
            CGFloat stopY = center.y + y * (radiusLength - shortLineMargin - shortLineHeight);
            
            CGPoint startPoint3D = [self transformTo3D:CGPointMake(center.x, startY)];
            CGPoint stopPoint3D = [self transformTo3D:CGPointMake(center.x, stopY)];
            [self drawLineFrom:startPoint3D stopPoint:stopPoint3D color:_textShadowColor strokeWidth:_strokeWidth*3 inContext:ctx];
            [self drawLineFrom:startPoint3D stopPoint:stopPoint3D color:_cardinalLinesColor strokeWidth:_strokeWidth inContext:ctx];
        }
        else
        {
            CGPoint startPoint3D = [self transformTo3D:CGPointMake(lineStartX, lineStartY)];
            CGPoint stopPoint3D = [self transformTo3D:CGPointMake(lineStopX, lineStopY)];
            [self drawLineFrom:startPoint3D stopPoint:stopPoint3D color:_textShadowColor strokeWidth:_strokeWidth*3 inContext:ctx];
            [self drawLineFrom:startPoint3D stopPoint:stopPoint3D color:_circleColor strokeWidth:_strokeWidth inContext:ctx];
        }
        if (i % 9 == 0 && i != 18)
        {
            CGPoint startPoint3D = [self transformTo3D:CGPointMake(lineStartX, lineStartY)];
            CGPoint stopPoint3D = [self transformTo3D:CGPointMake(lineStopX, lineStopY)];
            [self drawLineFrom:startPoint3D stopPoint:stopPoint3D color:_textShadowColor strokeWidth:_strokeWidth*3 inContext:ctx];
            [self drawLineFrom:startPoint3D stopPoint:stopPoint3D color:_cardinalLinesColor strokeWidth:_strokeWidth inContext:ctx];
        }
    }
}

- (NSInteger) getCompassLineHeight:(int)index
{
    if (index % 6 == 0)
        return 8;
    else if (index % 9 == 0 || index % 2 != 0)
        return 3;
    else
        return 6;
}

- (void) drawCardinalDirections:(CGPoint)center radiusLength:(double)radiusLength
{
    double textMargin = 24; //was 14
    
    for (int i = 0; i < _degrees.count; i += 9)
    {
        NSString *cardinalDirection = [self getCardinalDirection:i];
        if (cardinalDirection)
        {
            NSAttributedString *cardinalString = [OAUtilities createAttributedString:cardinalDirection font:_boldFont color:_textColor strokeColor:nil strokeWidth:0 alignment:NSTextAlignmentCenter];
            NSAttributedString *cardinalShadowString = [OAUtilities createAttributedString:cardinalDirection font:_boldFont color:_textColor strokeColor:_textShadowColor strokeWidth:_strokeWidthText alignment:NSTextAlignmentCenter];
            CGFloat textWidth = cardinalString.size.width;
            CGFloat textHeight = cardinalString.size.height;
            
            double textRadius = radiusLength - textMargin;
            CGPoint point = [self getPointFromCenterByRadius:textRadius angle: -i*5 + 90];
            [cardinalShadowString drawAtPoint:CGPointMake(point.x - textWidth / 2, point.y - textHeight / 2)];
            [cardinalString drawAtPoint:CGPointMake(point.x - textWidth / 2, point.y - textHeight / 2)];
        }
    }
}

- (NSString *) getCardinalDirection:(int)i
{
    if (i == 0)
        return _cardinalDirections[2];
    else if (i == 9)
        return _cardinalDirections[1];
    else if (i == 18)
        return _cardinalDirections[0];
    else if (i == 27)
        return _cardinalDirections[7];
    else if (i == 36)
        return _cardinalDirections[6];
    else if (i == 45)
        return _cardinalDirections[5];
    else if (i == 54)
        return _cardinalDirections[4];
    else if (i == 63)
        return _cardinalDirections[3];
    return nil;
}

- (NSString *) getCardinalDirectionForDegrees:(double)doubleDegrees
{
    int degrees = (int)(doubleDegrees);
    while (degrees < 0)
        degrees += 360;
    
    int index = floor(((degrees + 23) % 360) / 45);
    if (index >= 0 && _cardinalDirections.count > index)
        return _cardinalDirections[index];
    else
        return @"";
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

- (void) drawTriangleArrowByRadius:(double)radius angle:(double)angle center:(CGPoint)center color:(UIColor*)color inContext:(CGContextRef)ctx
{
    double headOffsesFromRadius = 6;
    double triangleSideLength = 9;
    double triangleHeadAngle = 60;
    double zeroAngle = angle - 90;
    
    double radians = [self toRadians:zeroAngle];
    CGFloat firstPointX = center.x + cos(radians) * (radius + headOffsesFromRadius);
    CGFloat firstPointY = center.y + sin(radians) * (radius + headOffsesFromRadius);
    CGPoint firstPoint3D = [self transformTo3D:CGPointMake(firstPointX, firstPointY)];
    
    double radians2 = [self toRadians:zeroAngle + triangleHeadAngle / 2 + 180];
    CGFloat secondPointX = firstPointX + cos(radians2) * triangleSideLength;
    CGFloat secondPointY = firstPointY + sin(radians2) * triangleSideLength;
    CGPoint secondPoint3D = [self transformTo3D:CGPointMake(secondPointX, secondPointY)];
    
    double radians3 = [self toRadians:zeroAngle - triangleHeadAngle / 2 + 180];
    CGFloat thirdPointX = firstPointX + cos(radians3) * triangleSideLength;
    CGFloat thirdPointY = firstPointY + sin(radians3) * triangleSideLength;
    CGPoint thirdPoint3D = [self transformTo3D:CGPointMake(thirdPointX, thirdPointY)];
    
    [_textShadowColor set];
    CGContextSetLineWidth(ctx, _strokeWidth*2);
    CGContextMoveToPoint(ctx, firstPoint3D.x, firstPoint3D.y);
    CGContextAddLineToPoint(ctx, secondPoint3D.x, secondPoint3D.y);
    CGContextAddLineToPoint(ctx, thirdPoint3D.x, thirdPoint3D.y);
    CGContextAddLineToPoint(ctx, firstPoint3D.x, firstPoint3D.y);
    CGContextClosePath(ctx);
    CGContextStrokePath(ctx);
    
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextMoveToPoint(ctx, firstPoint3D.x, firstPoint3D.y);
    CGContextAddLineToPoint(ctx, secondPoint3D.x, secondPoint3D.y);
    CGContextAddLineToPoint(ctx, thirdPoint3D.x, thirdPoint3D.y);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

- (CGPoint) transformTo3D:(CGPoint)screenPoint
{
    return [self transformTo3D:screenPoint compensateMapRotation:false];
}

- (CGPoint) transformTo3D:(CGPoint)screenPoint compensateMapRotation:(BOOL)disableMapRotation
{
    auto circleCenterPos31 = _cachedCenter31;
    auto centerLatLon = _cachedCenterLatLon;
    CGPoint circleCenterPoint = _cachedCenter;

    [_mapViewController.mapView convert:&_cachedCenter31 toScreen:&circleCenterPoint checkOffScreen:YES];
    
    double dX = circleCenterPoint.x - screenPoint.x;
    double dY = circleCenterPoint.y - screenPoint.y;
    double distanceFromCenter = sqrt(dX * dX + dY * dY);
    double angleFromCenter = [self toDegrees:atan2(dY, dX)] - 90;
    angleFromCenter = disableMapRotation ? angleFromCenter + _cachedMapAzimuth : angleFromCenter;
    
    return [self getPointFromCenterByRadius:distanceFromCenter angle:angleFromCenter];
}

- (CGPoint) getPointFromCenterByRadius:(double)radius angle:(double)angle
{
    double pixelDensity = _cachedMapDensity * [[UIScreen mainScreen] scale];
    auto pointLatLon = OsmAnd::Utilities::rhumbDestinationPoint(_cachedCenterLatLon, radius * pixelDensity, angle);
    return [self latLonToScreenPoint:pointLatLon];
}

- (CGPoint) latLonToScreenPoint:(OsmAnd::LatLon)latLon
{
    auto pos31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
    CGPoint screenPoint;
    [_mapViewController.mapView convert:&pos31 toScreen:&screenPoint checkOffScreen:YES];
    return screenPoint;
}
- (double) toRadians:(double)degrees
{
    return degrees * M_PI / 180;
}

- (double) toDegrees:(double)radians
{
    return radians / M_PI * 180;
}

- (BOOL) updateInfo
{
    BOOL visible = [self rulerWidgetOn];
    if (visible)
    {
        if (_cachedMapMode != _settings.nightMode)
        {
            _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
            _cachedMapMode = _settings.nightMode;
        }
        
        OAMapRendererView *mapRendererView = _mapViewController.mapView;
        visible = [_mapViewController calculateMapRuler] != 0
            && !_mapViewController.zoomingByGesture
            && !_mapViewController.rotatingByGesture;
        
        CGSize viewSize = self.bounds.size;
        float viewportScale = mapRendererView.viewportYScale;
        BOOL centerChanged  = _cachedViewportScale != viewportScale || _cachedWidth != viewSize.width || _cachedHeight != viewSize.height;
        if (centerChanged)
            [self changeCenter];
        
        BOOL modeChanged = _cachedRulerMode != _settings.rulerMode.get;
        if ((visible && _cachedRulerMode != RULER_MODE_NO_CIRCLES) || modeChanged)
        {
            _cachedMapDensity = mapRendererView.currentPixelsToMetersScaleFactor;
            double fullMapScale = _cachedMapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
            float mapAzimuth = mapRendererView.azimuth;
            float mapZoom = mapRendererView.zoom;
            const auto target31 = mapRendererView.target31;
            const auto target31Delta = _cachedCenter31 - target31;
            
            BOOL wasTargetChanged = abs(target31Delta.y) > TARGET31_UPDATING_THRESHOLD;
            if (wasTargetChanged)
                _cachedCenter31 = target31;
            
            //BOOL wasZoomed = abs(_cachedMapZoom - mapZoom) > ZOOM_UPDATING_THRESHOLD;
            BOOL wasRotated = abs(mapAzimuth - _cachedMapAzimuth) > RULER_ROTATION_UPDATING_THRESHOLD;
            BOOL wasElevated = abs(_cachedMapElevation - _mapViewController.mapView.elevationAngle) > ELEVATION_UPDATING_THRESHOLD;

            double oneFrameTime = 1.0 / FRAMES_PER_SECOND;
            BOOL wasUpdatedRecently = ([[NSDate date] timeIntervalSince1970] - _cachedTimestamp) < oneFrameTime;

            BOOL mapMoved = (wasTargetChanged || centerChanged
                             || _cachedWidth != viewSize.width
                             || wasElevated
                             || wasRotated
                             || _cachedMapZoom != mapZoom
                             || modeChanged);
            
            BOOL compassVisible = _settings.showCompassControlRuler.get && [_mapViewController getMapZoom] > SHOW_COMPASS_MIN_ZOOM;
            double heading = _app.locationServices.lastKnownHeading;
            BOOL headingChanged = abs(int(_cachedHeading) - int(heading)) >= ARROW_ROTATION_UPDATING_THRESHOLD;
            BOOL shouldUpdateCompass = compassVisible && headingChanged;
            
            _cachedWidth = viewSize.width;
            _cachedHeight = viewSize.height;
            _cachedHeading = heading;
            _cachedMapAzimuth = mapAzimuth;
            _cachedViewportScale = viewportScale;
            _cachedHeading = _app.locationServices.lastKnownHeading;
            _mapScaleUnrounded = fullMapScale;
            _mapScale = [OAOsmAndFormatter calculateRoundedDist:_mapScaleUnrounded];
            _radius = (_mapScale / _cachedMapDensity) / [[UIScreen mainScreen] scale];
            _maxRadius = [self calculateMaxRadiusInPx];
            
            if ((mapMoved || shouldUpdateCompass) && !wasUpdatedRecently )
                [self setNeedsDisplay];
        }
        _cachedRulerMode = _settings.rulerMode.get;
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

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (void) changeCenter
{
    _imageView.center = CGPointMake(self.frame.size.width * 0.5,
                                    self.frame.size.height * 0.5 * _mapViewController.mapView.viewportYScale);
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
        return YES;
    }
    return NO;
}

@end
