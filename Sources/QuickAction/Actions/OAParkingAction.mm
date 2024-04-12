//
//  OAParkingAction.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAParkingAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OATargetPoint.h"
#import "OAQuickActionType.h"
#import "OAPluginsHelper.h"

#include <OsmAndCore/Utilities.h>

static OAQuickActionType *TYPE;

@implementation OAParkingAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getEnabledPlugin:OAParkingPositionPlugin.class];
    if (plugin)
    {
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OAMapViewController *mapVC = mapPanel.mapViewController;
        const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(mapVC.mapView.target31);
        CLLocationCoordinate2D point = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetParking;
        targetPoint.location = point;
        
        [mapPanel showContextMenu:targetPoint];
        [mapPanel targetPointParking];
    }
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_parking_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:7 stringId:@"parking.add" class:self.class name:OALocalizedString(@"quick_action_add_parking") category:CREATE_CATEGORY iconName:@"ic_custom_parking" secondaryIconName:@"ic_custom_compound_action_add" editable:NO];
       
    return TYPE;
}

@end
