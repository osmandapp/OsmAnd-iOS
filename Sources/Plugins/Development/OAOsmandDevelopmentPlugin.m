//
//  OAOsmandDevelopmentPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 31.05.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentPlugin.h"
#import "OAProducts.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAMapInfoController.h"
#import "OATextInfoWidget.h"
#import "OAFPSTextInfoWidget.h"

#define PLUGIN_ID kInAppId_Addon_OsmandDevelopment

@implementation OAOsmandDevelopmentPlugin
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAFPSTextInfoWidget *_fpsWidgetControl;
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

- (BOOL)isEnableByDefault
{
    return NO;
}

- (void) registerLayers
{
    [self registerWidget];
}

- (void) registerWidget
{
    OAMapInfoController *mapInfoController = [self getMapInfoController];
    if (mapInfoController)
    {
        _fpsWidgetControl = [[OAFPSTextInfoWidget alloc] init];
        [mapInfoController registerSideWidget:_fpsWidgetControl imageId:@"ic_custom_fps" message:OALocalizedString(@"map_widget_rendering_fps") key:PLUGIN_ID left:false priorityOrder:99];
        [mapInfoController recreateControls];
    }
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isEnabled])
        {
            if (!_fpsWidgetControl)
                [self registerWidget];
        }
        else
        {
            if (_fpsWidgetControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_fpsWidgetControl];
                [mapInfoController recreateControls];
                _fpsWidgetControl = nil;
            }
        }
    });
}

@end
