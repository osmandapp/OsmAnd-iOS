//
//  OAContourLinesAction.m
//  OsmAnd Maps
//
//  Created by igor on 19.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAContourLinesAction.h"
#import "OAAppSettings.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAContourLinesAction
{
    OAAppSettings *_settings;
    OAMapStyleSettings *_styleSettings;
}

- (instancetype) init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsContourLinesActionId
                                            stringId:@"contourlines.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_contour_lines")]
              iconName:@"ic_custom_contour_lines"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _styleSettings = [OAMapStyleSettings sharedInstance];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
