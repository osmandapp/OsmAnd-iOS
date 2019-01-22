//
//  OAOsmEditingPlugin.m
//  OsmAnd
//
//  Created by Paul on 1/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditingPlugin.h"

#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OATextInfoWidget.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "PXAlertView.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OARoutingHelper.h"
#import "OAMapViewController.h"
#import "OANativeUtilities.h"
#import "OAOsmEditsLayer.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAMapLayers.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define PLUGIN_ID kInAppId_Addon_OsmEditing

@interface OAOsmEditingPlugin ()

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OADestinationsHelper *helper;
@property (nonatomic) OAMapViewController *mapViewController;

@property (nonatomic) OAOsmEditsLayer *editsLayer;

@end

@implementation OAOsmEditingPlugin

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _helper = [OADestinationsHelper instance];
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    }
    return self;
}

+ (NSString *) getId
{
    return PLUGIN_ID;
}

- (void) registerLayers
{
    _editsLayer = [[OAOsmEditsLayer alloc] init];
}

- (void) updateLayers
{
    if ([self isActive])
        [_mapViewController.mapLayers showLayer:kOsmEditsLayerId];
    else
        [_mapViewController.mapLayers hideLayer:kOsmEditsLayerId];
}

@end
