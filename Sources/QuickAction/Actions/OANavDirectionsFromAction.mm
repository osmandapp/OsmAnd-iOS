//
//  OANavDirectionsFromAction.m
//  OsmAnd
//
//  Created by Paul on 30.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavDirectionsFromAction.h"
#import "OAQuickActionType.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>

static OAQuickActionType *TYPE;

@implementation OANavDirectionsFromAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    const auto latLon = OsmAnd::Utilities::convert31ToLatLon(mapPanel.mapViewController.mapView.target31);
    OATargetPoint *p = [[OATargetPoint alloc] init];
    p.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    [mapPanel navigateFrom:p];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_dir_from_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:32 stringId:@"nav.directions" class:self.class name:OALocalizedString(@"context_menu_item_directions_from") category:NAVIGATION iconName:@"ic_action_directions_from" secondaryIconName:nil editable:NO];
       
    return TYPE;
}


@end
