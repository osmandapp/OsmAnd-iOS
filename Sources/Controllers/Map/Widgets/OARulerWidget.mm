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

#include <OsmAndCore/Utilities.h>

#define kMapRulerMaxWidth 120


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
    
    UITapGestureRecognizer* _gestureRecognizer;
    
    BOOL _twoFingersDist;
    BOOL _oneFingerDist;
    
    CGPoint _tapPointOne;
    CGPoint _tapPointTwo;
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
    _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(tapDetected:)];
    _gestureRecognizer.delegate = self;
    [self addGestureRecognizer:_gestureRecognizer];
    self.multipleTouchEnabled = YES;
    [self setOpaque:NO];
    self.hidden = YES;
}

- (BOOL) updateInfo
{
    BOOL visible = [self rulerWidgetOn];
    if (visible)
    {
        OAMapRendererView *mapRendererView = _mapViewController.mapView;
        visible = [_mapViewController calculateMapRuler] != 0;
        
        if (visible && (_zoom != (int) mapRendererView.zoom
                 || _cachedViewportScale != _mapViewController.mapView.viewportYScale
                 || _cachedWidth != self.frame.size.width
                 || _cachedMapAngle != mapRendererView.elevationAngle)) {
            _cachedWidth = self.frame.size.width;
            _cachedMapAngle = mapRendererView.elevationAngle;
            _cachedViewportScale = _mapViewController.mapView.viewportYScale;
            float mapDensity = mapRendererView.currentPixelsToMetersScaleFactor;
            _mapScale = [_app calculateRoundedDist:mapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale]];
            _radius = (_mapScale / mapDensity) / [[UIScreen mainScreen] scale];
            _maxRadius = [self calculateMaxRadiusInPx];
            _zoom = (int) mapRendererView.zoom;
        }
        visible = _oneFingerDist || _twoFingersDist;
        [self setNeedsDisplay];
        
        
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

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
        [self.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
        CGContextSetLineWidth(ctx, 1.0);
        [[UIColor blackColor] set];
        CGContextSetShadowWithColor(ctx, CGSizeZero, 3.0, [UIColor whiteColor].CGColor);
        double maxRadiusCopy = _maxRadius;
        for (int i = 1; maxRadiusCopy > _radius && _radius != 0; i++) {
            maxRadiusCopy -= _radius;
            double currRadius = _radius * i;
            double cosine = cos(qDegreesToRadians(_cachedMapAngle - 90));
            CGRect circleRect = CGRectMake(self.frame.size.width/2 - currRadius, (self.frame.size.height/2 * _cachedViewportScale) - (currRadius * cosine), currRadius * 2, currRadius * 2 * cosine);
            CGContextStrokeEllipseInRect(ctx, circleRect);
            
            NSString *dist = [_app getFormattedDistance:_mapScale * i];
            UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
            CGSize titleSize = [dist sizeWithAttributes:@{NSFontAttributeName: font}];
            [self addTextLabel:dist font:font origX:circleRect.origin.x + circleRect.size.width/2 - titleSize.width/2
                         origY:circleRect.origin.y - titleSize.height/2 width:titleSize.width height:titleSize.height];
            [self addTextLabel:dist font:font origX:circleRect.origin.x + circleRect.size.width/2 - titleSize.width/2
                         origY:circleRect.origin.y + circleRect.size.height - titleSize.height/2
                         width:titleSize.width height:titleSize.height];
        }
    
    if (_oneFingerDist)
    {
        CGPoint currentPoint = [self getCurrentlocationPixelPoint];
        if (currentPoint.x != 0 && currentPoint.y != 0) {
            [self drawLineBetweenPoints:currentPoint end:_tapPointOne context:ctx];
        }
        _oneFingerDist = NO;
    }
    if (_twoFingersDist) {
        [self drawLineBetweenPoints:_tapPointOne end:_tapPointTwo context:ctx];
        _twoFingersDist = NO;
    }
    
    
    [self updateVisibility:YES];
}

- (void) drawLineBetweenPoints:(CGPoint) start end:(CGPoint) end context:(CGContextRef) ctx
{
    CGContextSetLineWidth(ctx, 5.0);
    CGFloat dashLengths[] = {10, 5};
    CGContextSetLineDash(ctx, 0.0, dashLengths , 2);
    CGContextMoveToPoint(ctx, start.x, start.y);
    CGContextAddLineToPoint(ctx, end.x, end.y);
    CGContextStrokePath(ctx);
}

- (void) addTextLabel:(NSString *)text font:(UIFont *)font origX:(CGFloat)x origY:(CGFloat)y width:(CGFloat)width height:(CGFloat)height
{
   
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    label.text = text;
    label.font = font;
    UIColor *glowColor = [UIColor whiteColor];
    label.layer.shadowColor = [glowColor CGColor];
    label.layer.shadowRadius = 3.0f;
    label.layer.shadowOpacity = 1.0;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.masksToBounds = NO;
    [self addSubview:label];
    
}

- (CGPoint) getCurrentlocationPixelPoint
{
    CLLocation *currLoc = [_app.locationServices lastKnownLocation];
    const OsmAnd::LatLon latLon(currLoc.coordinate.latitude, currLoc.coordinate.longitude);
    OsmAnd::PointI currentPositionI = OsmAnd::Utilities::convertLatLonTo31(latLon);
    
    CGPoint point;
    if ([_mapViewController.mapView convert:&currentPositionI toScreen:&point])
    {
        return point;
    }
    return CGPointMake(0, 0);
}

- (void) tapDetected:(UITapGestureRecognizer *)recognizer
{
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    if ([recognizer numberOfTouches] == 1) {
        _oneFingerDist = YES;
        _tapPointOne = [recognizer locationOfTouch:0 inView:self];
        [self updateInfo];
    }
    
    if ([recognizer numberOfTouches] == 2) {
        _twoFingersDist = YES;
        _tapPointOne = [recognizer locationOfTouch:0 inView:self];
        _tapPointTwo = [recognizer locationOfTouch:1 inView:self];
        [self updateInfo];
    }
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

@end
