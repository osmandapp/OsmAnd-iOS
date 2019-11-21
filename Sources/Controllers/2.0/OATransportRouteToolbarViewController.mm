//
//  OATransportRouteToolbarViewController.m
//  OsmAnd
//
//  Created by Alexey on 29/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportRouteToolbarViewController.h"
#import "OAUtilities.h"
#import "OATransportStopRoute.h"
#import "OATransportStop.h"
#import "OATransportRouteController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OANativeUtilities.h"
#import "OATargetPoint.h"
#import "OAMapLayers.h"
#import "OATransportStopsLayer.h"

#include <OsmAndCore/Utilities.h>

@interface OATransportRouteToolbarViewController ()

@end

@implementation OATransportRouteToolbarViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.titleButton setTitle:self.toolbarTitle forState:UIControlStateNormal];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setToolbarTitle:(NSString *)toolbarTitle
{
    _toolbarTitle = toolbarTitle;
    if (self.titleButton)
        [self.titleButton setTitle:toolbarTitle forState:UIControlStateNormal];
}

- (int) getPriority
{
    return TRANSPORT_ROUTE_TOOLBAR_PRIORITY;
}

- (UIStatusBarStyle)getPreferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIColor *) getStatusBarColor
{
    return UIColorFromRGB(0xFC7B08);
}

- (void) updateFrame:(BOOL)animated
{
    self.view.frame = CGRectMake(0.0, [self.delegate toolbarTopPosition], DeviceScreenWidth - OAUtilities.getLeftMargin * 2, self.navBarView.bounds.size.height);
    [self.delegate toolbarLayoutDidChange:self animated:animated];
}

- (IBAction) backPress:(id)sender
{
    if (self.transportStop)
    {
        [OATransportRouteController hideToolbar];
        
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OAMapViewController *mapController = mapPanel.mapViewController;
        [mapController.mapLayers.transportStopsLayer hideRoute];
        
        OATargetPoint *targetPoint = [mapController.mapLayers.transportStopsLayer getTargetPoint:self.transportStop];
        if (targetPoint)
        {
            targetPoint.centerMap = YES;
            [mapPanel showContextMenuWithPoints:@[targetPoint]];
        }
    }
    else
    {
        [self closePress:nil];
    }
}

- (IBAction) titlePress:(id)sender
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if ([mapPanel getCurrentTargetPoint].type != OATargetTransportRoute)
    {
        
        OATransportStopRoute *r = [self.transportRoute clone];
        OATargetPoint *targetPoint = [OATransportRouteController getTargetPoint:r];
        if (targetPoint)
        {
            CLLocationCoordinate2D latLon = targetPoint.location;
            
            Point31 point31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.latitude, latLon.longitude))];
            [mapPanel prepareMapForReuse:point31 zoom:12 newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
            [mapPanel.mapViewController.mapLayers.transportStopsLayer showStopsOnMap:r];
            
            [mapPanel showContextMenuWithPoints:@[targetPoint]];
        }
    }
}

- (IBAction) closePress:(id)sender
{
    [OATransportRouteController hideToolbar];
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapController = mapPanel.mapViewController;
    [mapController.mapLayers.transportStopsLayer hideRoute];

    OATargetPoint *targetPoint = [mapPanel getCurrentTargetPoint];
    if (targetPoint && targetPoint.type == OATargetTransportRoute)
        [[OARootViewController instance].mapPanel targetHide];
}

@end
