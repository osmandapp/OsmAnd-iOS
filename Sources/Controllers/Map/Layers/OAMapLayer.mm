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
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>

@interface OAMapLayer()

@property (nonatomic) BOOL nightMode;
@property (nonatomic) CGFloat displayDensityFactor;

@end

@implementation OAMapLayer

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

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint
{
    OsmAnd::PointI touchLocation;
    [self.mapView convert:touchPoint toLocation:&touchLocation];
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

- (int) getScaledTouchRadius:(int)radiusPoi
{
    double textSize = [[OAAppSettings.sharedManager textSize] get];
    if (textSize < 1)
        textSize = 1;
    return ((int) textSize * radiusPoi);
}

- (int) getDefaultRadiusPoi
{
    int r;
    double zoom = self.mapView.zoom;
    if (zoom <= 15) {
        r = 10;
    } else if (zoom <= 16) {
        r = 14;
    } else if (zoom <= 17) {
        r = 16;
    } else {
        r = 18;
    }
    return (int) (r * self.mapView.displayDensityFactor);
}

- (int) pointsOrder
{
    return _pointsOrder != 0 ? _pointsOrder : _baseOrder;
}

- (void) setPointsOrder:(int)pointsOrder
{
    _pointsOrder = pointsOrder;
}

- (int)pointOrder:(id)object
{
    return self.pointsOrder;
}

@end
