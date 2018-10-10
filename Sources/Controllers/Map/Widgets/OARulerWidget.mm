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
    OAMapRendererView *_mapRendererView;
    int _zoom;
    
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
    _mapRendererView = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.mapRendererView;
    
    [self setOpaque:NO];
    
}

- (BOOL) updateInfo
{
    if (_mapRendererView.zoom != _zoom) {
        
        float pxToMetersFactor = _mapRendererView.currentPixelsToMetersScaleFactor;
        double metersPerMaxSize = pxToMetersFactor * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
        double roundedDist = [_app calculateRoundedDist:metersPerMaxSize];
        double maxDistance = MAX(self.frame.size.width, self.frame.size.height)*[[UIScreen mainScreen] scale]*pxToMetersFactor;
        _zoom = _mapRendererView.zoom;
        [self setNeedsDisplay];
        
    }
    return YES;
}

-(void)drawRect:(CGRect)rect {
    
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 2.0);
//    CGContextSetBlendMode(ctx,kCGBlendModeClear);
    [[UIColor redColor] set];
    
//    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, 5.0, 0.0, M_PI * 2.0, YES);
    CGRect circleRect = CGRectMake(self.frame.size.width/2 - 5.0, self.frame.size.height/2 - 5.0, 10.0, 10.0);
    CGContextStrokeEllipseInRect(ctx, circleRect);
    
    circleRect = CGRectMake(self.frame.size.width/2 - _zoom, self.frame.size.height/2 - _zoom, _zoom*2, _zoom*2);
    CGContextStrokeEllipseInRect(ctx, circleRect);

    [self updateVisibility:YES];
    
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
