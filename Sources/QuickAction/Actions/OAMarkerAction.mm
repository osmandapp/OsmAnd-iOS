//
//  OAMarkerAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMarkerAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAReverseGeocoder.h"

#include <OsmAndCore/Utilities.h>

@implementation OAMarkerAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeMarker];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(mapPanel.mapViewController.mapView.target31);
    
    [mapPanel addMapMarker:latLon.latitude lon:latLon.longitude description:[[OAReverseGeocoder instance] lookupAddressAtLat:latLon.latitude lon:latLon.longitude]];
}

@end
