//
//  OAMapViewHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAMapViewHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>

@implementation OAMapViewHelper
{
    OAMapViewController *_mapVC;
    OAMapRendererView *_mapView;
}

+ (instancetype) sharedInstance
{
    static OAMapViewHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAMapViewHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mapVC = OARootViewController.instance.mapPanel.mapViewController;
        _mapView = _mapVC.mapView;
    }
    return self;
}

- (CGFloat)getMapZoom
{
    return _mapView.zoom;
}

- (void)goToLocation:(nonnull CLLocation *)position zoom:(CGFloat)zoom animated:(BOOL)animated {
    CLLocationCoordinate2D coord = position.coordinate;
    OsmAnd::PointI newPositionI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(coord.latitude, coord.longitude));
    [_mapVC goToPosition:[OANativeUtilities convertFromPointI:newPositionI] andZoom:zoom animated:YES];
}

@end
