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
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAPublicTransportOptionsBottomSheet.h"

#define KEY_DIALOG @"dialog"


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
    if ([self isTurningOnWithAllTransportLayersHidden])
        [self showDashboardMenu];

    if (_settings.mapSettingShowPublicTransport)
        [self hideAllTransportLayers];
    else
        [self showEnabledTransportLayers];
    
    [_settings setMapSettingShowPublicTransport:!_settings.mapSettingShowPublicTransport];
}

- (BOOL) isTurningOnWithAllTransportLayersHidden
{
    return !_settings.mapSettingShowPublicTransport && ![_settings.transportLayersVisible get];
}

- (void)showDashboardMenu
{
    OAPublicTransportOptionsBottomSheetViewController *bottomSheet = [[OAPublicTransportOptionsBottomSheetViewController alloc] init];
    [bottomSheet show];
}

- (void)showEnabledTransportLayers
{
    NSMutableArray* storedVisibleParamNames = [_settings.transportLayersVisible get];
    for (NSString *visibleParamName in storedVisibleParamNames)
    {
        OAMapStyleParameter *renderParam = [_styleSettings getParameter:visibleParamName];
        renderParam.value = @"true";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_styleSettings saveParameters];
        [[_app mapSettingsChangeObservable] notifyEvent];
    });
}

- (void)hideAllTransportLayers
{
    NSArray* renderParams = [_styleSettings getParameters:@"transport"];
    for (OAMapStyleParameter *renderParam in renderParams)
    {
        renderParam.value = @"false";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_styleSettings saveParameters];
        [[_app mapSettingsChangeObservable] notifyEvent];
    });
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
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:4 stringId:@"favorites.showhide" class:self.class name:OALocalizedString(@"toggle_public_transport") category:CONFIGURE_MAP iconName:@"ic_custom_transport_bus" secondaryIconName:nil];
       
    return TYPE;
}

- (OrderedDictionary *)getUIModel
{
    
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : @"OASwitchTableViewCell",
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    return data;
}

@end
