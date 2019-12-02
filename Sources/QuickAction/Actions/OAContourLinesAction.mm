//
//  OAContourLinesAction.m
//  OsmAnd Maps
//
//  Created by igor on 19.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAContourLinesAction.h"
#import "OAAppSettings.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"

@implementation OAContourLinesAction
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapStyleSettings *styleSettings;
    OAMapStyleParameter *parameter;
}

- (instancetype) init
{
    _settings = [OAAppSettings sharedManager];
    styleSettings = [OAMapStyleSettings sharedInstance];
    parameter = [styleSettings getParameter:@"contourLines"];
    
    return [super initWithType:EOAQuickActionTypeToggleContourLines];
}

- (BOOL) isContourLinesOn
{
    return [parameter.value isEqual:@"disabled"] ? false : true;
}

- (void)execute
{
    parameter.value = ![self isContourLinesOn] ? [_settings.contourLinesZoom get] : @"disabled";
    [styleSettings save:parameter];
}

- (NSString *)getIconResName
{
    return @"ic_custom_contour_lines";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_contour_lines_descr");
}

- (BOOL)isActionWithSlash
{
    return [self isContourLinesOn];
}

- (NSString *)getActionStateName
{
    return [self isContourLinesOn] ? OALocalizedString(@"hide_contour_lines") : OALocalizedString(@"show_contour_lines");
}

@end
