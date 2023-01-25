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
#import "OAQuickActionType.h"

#include <OsmAndCore/Utilities.h>

static OAQuickActionType *TYPE;

@implementation OAMarkerAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(mapPanel.mapViewController.mapView.target31);
    
    [mapPanel addMapMarker:latLon.latitude lon:latLon.longitude description:[[OAReverseGeocoder instance] lookupAddressAtLat:latLon.latitude lon:latLon.longitude]];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_add_marker_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:2 stringId:@"marker.add" class:self.class name:OALocalizedString(@"quick_action_add_marker") category:CREATE_CATEGORY iconName:@"ic_custom_favorites" secondaryIconName:@"ic_custom_compound_action_add"];
       
    return TYPE;
}

@end
