//
//  OARulerWidget.m
//  OsmAnd
//
//  Created by Paul on 10/5/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARulerWidget.h"
#import "OALanesControl.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OALanesDrawable.h"
#import "OAMapViewTrackingUtilities.h"
#import "OALocationServices.h"
#import "OARouteCalculationResult.h"
#import "OARouteInfoView.h"
#import "OARouteDirectionInfo.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"

#define kMapRulerMaxWidth 120

@interface OARulerWidget ()

@property (weak, nonatomic) IBOutlet UIView *imageView;

@end


@implementation OARulerWidget
{
    OALocationServices *_locationProvider;
    OARoutingHelper *_rh;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    int _zoom;
    double _radius;
    double _maxRadius;
    float _cachedViewportScale;
    float _cachedDensity;
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
    _rh = [OARoutingHelper sharedInstance];
    _app = [OsmAndApp instance];
    _locationProvider = _app.locationServices;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    [self setOpaque:NO];
    
}

- (BOOL) updateInfo
{
    OAMapRendererView *mapRendererView = (OAMapRendererView *) _mapViewController.mapRendererView;
    BOOL mapMoved = /*_mapViewController.mapView.zoom != _zoom || _mapViewController.mapView.viewportYScale != _cachedViewportScale*/YES;
    const auto currentZoomAnimation = _mapViewController.mapView.animator->getCurrentAnimation(kUserInteractionAnimationKey,
                                                                             OsmAnd::MapAnimator::AnimatedValue::Zoom);
    if ( mapMoved) {
        NSLog(@"%@", @"Refreshing ruler");
        _cachedViewportScale = _mapViewController.mapView.viewportYScale;
        _cachedDensity = mapRendererView.currentPixelsToMetersScaleFactor;
        double mapScale = _cachedDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
        _radius = ([_app calculateRoundedDist:mapScale] / _cachedDensity) / [[UIScreen mainScreen] scale];
        _maxRadius = [self calculateMaxRadiusInPx];
        _zoom = (int) mapRendererView.zoom;
        [self setNeedsDisplay];
        
    }
    return YES;
}

- (double) calculateMaxRadiusInPx
{
    float topDist = self.center.y;
    float bottomDist = self.frame.size.height - self.center.y;
    float leftDist = self.center.x;
    float rightDist = self.frame.size.width - self.center.x;
    float maxVertical = topDist >= bottomDist ? topDist : bottomDist;
    float maxHorizontal = rightDist >= leftDist ? rightDist : leftDist;
    return (double) (maxVertical >= maxHorizontal ? maxVertical : maxHorizontal) * _cachedViewportScale;
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(ctx, 2.0);
    [[UIColor redColor] set];
    double maxRadiusCopy = _maxRadius;
    for (int i = 1; maxRadiusCopy > _radius && _radius != 0; i++) {
        maxRadiusCopy -= _radius;
        double currRadius = _radius * i;
        CGRect circleRect = CGRectMake(self.frame.size.width/2 - currRadius, (self.frame.size.height/2 * _cachedViewportScale) - currRadius, currRadius * 2, currRadius * 2);
        CGContextStrokeEllipseInRect(ctx, circleRect);
    }
    [self updateVisibility:YES];
    
}

//- (BOOL) rulerWidgetOn
//{
//    return mapActivity.getMapLayers().getMapWidgetRegistry().isVisible("ruler") &&
//    rightWidgetsPanel.getVisibility() == View.VISIBLE;
//}

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
