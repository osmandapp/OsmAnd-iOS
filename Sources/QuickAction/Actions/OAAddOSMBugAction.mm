//
//  OAAddOSMBugAction.m
//  OsmAnd
//
//  Created by Paul on 8/6/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddOSMBugAction.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>

#define KEY_MESSAGE @"message"
#define KEY_SHOW_DIALOG @"dialog"

@implementation OAAddOSMBugAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeAddNote];
}

- (void)execute
{
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    
    if (plugin)
    {
        const auto& latLon = OsmAnd::Utilities::convert31ToLatLon([OARootViewController instance].mapPanel.mapViewController.mapView.target31);
        
        if (self.getParams.count == 0)
            [plugin openOsmNote:latLon.latitude longitude:latLon.longitude message:@"" autoFill:YES];
        else
            [plugin openOsmNote:latLon.latitude longitude:latLon.longitude message:self.params[KEY_MESSAGE] autoFill:![self.params[KEY_SHOW_DIALOG] boolValue]];
    }
}

@end
