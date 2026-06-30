//
//  OAAisTrackerLayerBridge.mm
//  OsmAnd
//
//  Created by OpenAI on 12.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAAisTrackerLayerBridge.h"
#import "OAAisTrackerLayer.h"
#import "OAMapLayers.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAAisTrackerLayerBridge

+ (OAAisTrackerLayer *)aisTrackerLayer
{
    return OARootViewController.instance.mapPanel.mapViewController.mapLayers.aisTrackerLayer;
}

+ (void)reloadAisObjects
{
    [[self aisTrackerLayer] reloadAisObjects];
}

+ (void)onAisObjectReceived:(OASAisObject *)object
{
    [[self aisTrackerLayer] onAisObjectReceived:object];
}

+ (void)onAisObjectRemoved:(OASAisObject *)object
{
    [[self aisTrackerLayer] onAisObjectRemoved:object];
}

@end
