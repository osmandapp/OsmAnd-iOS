//
//  OAAddPOIAction.m
//  OsmAnd
//
//  Created by Paul on 8/7/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddPOIAction.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OANode.h"
#import "OAEntity.h"
#import "OAEditPOIData.h"
#import "OrderedDictionary.h"
#import "OAOsmEditingViewController.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAPOIType.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmEditsDBHelper.h"

#include <OsmAndCore/Utilities.h>

#define KEY_TAG @"key_tag"
#define KEY_DIALOG @"dialog"

@implementation OAAddPOIAction

- (instancetype) init
{
    return [super initWithType:EOAQuickActionTypeAddPOI];
}

- (void) execute
{
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    
    if (plugin)
    {
        const auto& latLon = OsmAnd::Utilities::convert31ToLatLon([OARootViewController instance].mapPanel.mapViewController.mapView.target31);
        OANode *node = [[OANode alloc] initWithId:-1 latitude:latLon.latitude longitude:latLon.longitude];
        [node replaceTags:[self getTagsFromParams]];
        
        OAEditPOIData *data = [[OAEditPOIData alloc] initWithEntity:node];
        if ([[self getParams][KEY_DIALOG] boolValue])
        {
            OAEntity *entity = data.getEntity;
            OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithEntity:entity];
            [[OARootViewController instance].navigationController pushViewController:editingScreen animated:YES];
        }
        else
        {
            [OAOsmEditingViewController savePoi:@"" poiData:data editingUtil:plugin.getOfflineModificationUtil closeChangeSet:NO];
        }
    }
}

- (OrderedDictionary<NSString *, NSString *> *) getTagsFromParams
{
    OrderedDictionary<NSString *, NSString *> *actions = nil;
    NSString *json = [self getParams][KEY_TAG];
    if (json)
        actions = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    return actions != nil ? actions : [[OrderedDictionary alloc] init];
}

@end
