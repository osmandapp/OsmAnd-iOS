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
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OAContourLinesAction
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapStyleSettings *_styleSettings;
}

- (instancetype) init
{
    self = [super initWithActionType:self.class.TYPE];
    if (self) {
        _settings = [OAAppSettings sharedManager];
        _styleSettings = [OAMapStyleSettings sharedInstance];
    }
    return self;
}

- (OAMapStyleParameter *) parameter
{
    return [_styleSettings getParameter:CONTOUR_LINES];
}

- (BOOL) isContourLinesOn
{
    return ![[self parameter].value isEqual:@"disabled"];
}

- (void)execute
{
    OAMapStyleParameter *parameter = [self parameter];
    parameter.value = [self isContourLinesOn] ? @"disabled" : [_settings.contourLinesZoom get];
    [_styleSettings save:parameter];
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
    return [self isContourLinesOn] ? OALocalizedString(@"hide_contour_lines") : OALocalizedString(@"rendering_attr_contourLines_name");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:29 stringId:@"contourlines.showhide" class:self.class name:OALocalizedString(@"toggle_contour_lines") category:CONFIGURE_MAP iconName:@"ic_custom_contour_lines" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
