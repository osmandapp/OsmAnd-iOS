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
#import "OsmAnd_Maps-Swift.h"

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

- (NSString *) getDescription
{
    return OALocalizedString(@"plugin_mapillary_descr");
}

- (void) registerLayers
{
}

- (void)disable
{
    [super disable];
    [OsmAndApp.instance.data setMapillary:NO];
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isEnabled])
        {
            if (_mapillaryControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_mapillaryControl];
                _mapillaryControl = nil;
            }
        }
//        [[OARootViewController instance].mapPanel recreateControls];
    });
}

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
    OABaseWidgetView *widget = [[OAMapillaryWidget alloc] init];
    [delegate addWidget:[creator createWidgetInfoWithWidget:widget]];
}

- (BOOL) isVisible
{
    return NO;
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
