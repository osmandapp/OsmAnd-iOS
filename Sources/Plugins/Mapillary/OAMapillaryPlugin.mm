//
//  OAOsmEditingPlugin.m
//  OsmAnd
//
//  Created by Paul on 1/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryPlugin.h"

#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAPlugin.h"
#import "OAProducts.h"
#import "OAIAPHelper.h"
#import "OAMapHudViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAMapViewController.h"
#import "OATextInfoWidget.h"
#import "OAMapInfoController.h"
#import "OAInstallMapillaryBottomSheetViewController.h"
#import "OAShowHideMapillaryAction.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapInfoController.h"
#import "OAMapLayers.h"
#import "OAMapLayer.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define PLUGIN_ID kInAppId_Addon_Mapillary

#define MAPILLARY_URL_BASE @"mapillary://"

@interface OAMapillaryPlugin ()

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;

@end

@implementation OAMapillaryPlugin
{
    OATextInfoWidget *_mapillaryControl;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (NSString *) getName
{
    return OALocalizedString(@"mapillary");
}

- (void) registerLayers
{
    [self createLayers];
    [self registerWidget];
}

- (void) createLayers
{
    _mapillaryControl = [self createMapillaryInfoControl];
}

- (void) updateLayers
{
    [self updateMapLayers];
}

- (void) updateMapLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_mapillaryControl)
            [self createLayers];

        OAMapInfoController *mapInfoController = [self getMapInfoController];
        if (OAIAPHelper.sharedInstance.mapillary.disabled)
        {
            [mapInfoController removeSideWidget:_mapillaryControl];
            [mapInfoController recreateControls];
        }
        else
        {
            [self registerWidget];
        }
    });
}

- (BOOL) isVisible
{
    return NO;
}

- (void) registerWidget
{
    OAMapInfoController *mapInfoController = [self getMapInfoController];
    if (mapInfoController)
    {
        [mapInfoController registerSideWidget:_mapillaryControl imageId:@"ic_custom_mapillary_symbol" message:[self getName] key:PLUGIN_ID left:NO priorityOrder:19];
        [mapInfoController recreateControls];
    }
}

- (OATextInfoWidget *) createMapillaryInfoControl
{
    _mapillaryControl = [[OATextInfoWidget alloc] init];
    [_mapillaryControl setText:[self getName] subtext:nil];
    
    _mapillaryControl.onClickFunction = ^(id sender) {
        [OAMapillaryPlugin installOrOpenMapillary];
    };
    [_mapillaryControl setIcons:@"widget_mapillary_day" widgetNightIcon:@"widget_mapillary_night"];
    return _mapillaryControl;
}

+ (void) installOrOpenMapillary
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:MAPILLARY_URL_BASE]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:MAPILLARY_URL_BASE]];
    else
    {
        OAInstallMapillaryBottomSheetViewController *bottomSheet = [[OAInstallMapillaryBottomSheetViewController alloc] init];
        [bottomSheet show];
    }
}

- (NSArray *)getQuickActionTypes
{
    return @[OAShowHideMapillaryAction.TYPE];
}

@end
