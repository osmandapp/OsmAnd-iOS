//
//  OAShowHideTransportLinesAction.m
//  OsmAnd Maps
//
//  Created by nnngrach on 21.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAShowHideTransportLinesAction.h"
#import "OAQuickActionType.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideTransportLinesAction
{
    OsmAndAppInstance _app;
    OAAppSettings* _settings;
    OAMapStyleSettings* _styleSettings;
}

- (instancetype)init
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _styleSettings = [OAMapStyleSettings sharedInstance];
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    if (!_settings.mapSettingShowPublicTransport && [self isAllParametersHidden])
    {
        [self showTransportSettingsMenu];
    }
    
    [_settings setMapSettingShowPublicTransport:!_settings.mapSettingShowPublicTransport];
    [[_app mapSettingsChangeObservable] notifyEvent];
}

- (BOOL)isActionWithSlash
{
    return _settings.mapSettingShowPublicTransport;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"public_transport_hide") : OALocalizedString(@"public_transport_show");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:4 stringId:@"favorites.showhide" class:self.class name:OALocalizedString(@"toggle_public_transport") category:CONFIGURE_MAP iconName:@"ic_profile_bus" secondaryIconName:nil editable:NO];
       
    return TYPE;
}


- (BOOL) isAllParametersHidden
{
    BOOL isBusRoutesVisible = [[_styleSettings getParameter:@"publicTransportMode"].value boolValue];
    BOOL isSubwayRoutesVisible = [[_styleSettings getParameter:@"subwayMode"].value boolValue];
    BOOL isTramTrainRoutesVisible = [[_styleSettings getParameter:@"tramTrainRoutes"].value boolValue];
    BOOL isTransportStopsVisible = [[_styleSettings getParameter:@"transportStops"].value boolValue];
    return !isBusRoutesVisible && !isSubwayRoutesVisible && !isTramTrainRoutesVisible && !isTransportStopsVisible;
}

- (void) showTransportSettingsMenu
{
    OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:@"transport"];
    [mapSettingsViewController show:[OARootViewController instance].mapPanel parentViewController:nil animated:YES];
}

@end
