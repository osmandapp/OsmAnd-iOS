//
//  OAMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import <MBProgressHUD.h>
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>

@interface OAMapLayer()

@property (nonatomic) BOOL nightMode;
@property (nonatomic) CGFloat displayDensityFactor;

@end

@implementation OAMapLayer
{
    MBProgressHUD *_progressHUD;
}

@synthesize pointsOrder = _pointsOrder;

- (instancetype)initWithMapViewController:(OAMapViewController *)mapViewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _mapViewController = mapViewController;
        _mapView = mapViewController.mapView;
        _displayDensityFactor = mapViewController.displayDensityFactor;
    }
    return self;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [self initWithMapViewController:mapViewController];
    if (self)
    {
        _baseOrder = baseOrder;
        _pointsOrder = 0;
    }
    return self;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder pointsOrder:(int)pointsOrder
{
    self = [self initWithMapViewController:mapViewController];
    if (self)
    {
        _baseOrder = baseOrder;
        _pointsOrder = pointsOrder;
    }
    return self;
}

- (void) initLayer
{
    _nightMode = OAAppSettings.sharedManager.nightMode;
}

- (void) deinitLayer
{
}

- (void) resetLayer
{
}

- (BOOL) updateLayer
{
    if (OsmAndApp.instance.isInBackground)
    {
        self.invalidated = YES;
        return NO;
    }
    _nightMode = OAAppSettings.sharedManager.nightMode;
    self.invalidated = NO;
    return YES;
}

- (void) show
{
}

- (void) hide
{
}

- (void) onMapFrameAnimatorsUpdated
{
}

- (void) onMapFrameRendered
{
}

- (void) didReceiveMemoryWarning
{
}

- (BOOL)isVisible
{
    return YES;
}

- (void) showProgressHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL wasVisible = NO;
        if (_progressHUD)
        {
            wasVisible = YES;
            [_progressHUD hide:NO];
        }
        UIView *topView = [UIApplication sharedApplication].mainWindow;
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = .5f;
        [topView addSubview:_progressHUD];
        
        [_progressHUD show:!wasVisible];
    });
}

- (void) hideProgressHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressHUD)
        {
            [_progressHUD hide:YES];
            _progressHUD = nil;
        }
    });
}

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint
{
    OsmAnd::PointI touchLocation;
    [self.mapView convert:touchPoint toLocation:&touchLocation];
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

- (int) pointsOrder
{
    return _pointsOrder != 0 ? _pointsOrder : _baseOrder;
}

- (void) setPointsOrder:(int)pointsOrder
{
    _pointsOrder = pointsOrder;
}

@end
