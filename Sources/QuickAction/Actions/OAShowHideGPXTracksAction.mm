//
//  OAShowHideGPXTracksAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideGPXTracksAction.h"
#import "OAAppSettings.h"
#import "OASelectedGPXHelper.h"
#import "OsmAndApp.h"
#import "OAObservable.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideGPXTracksAction
{
    OASelectedGPXHelper *_helper;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideGpxTracksActionId
                                            stringId:@"gpx.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"show_gpx")]
               nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_trip"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)commonInit
{
    _helper = [OASelectedGPXHelper instance];
}

- (void)execute
{
    if (_helper.isShowingAnyGpxFiles)
        [_helper clearAllGpxFilesToShow:YES];
    else
        [_helper restoreSelectedGpxFiles];
    
    [[OsmAndApp instance].mapSettingsChangeObservable notifyEvent];
}

- (BOOL)isActionWithSlash
{
    return _helper.isShowingAnyGpxFiles;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_show_gpx_descr");
}

- (NSString *)getActionStateName
{
    NSString *nameRes = OALocalizedString(@"show_gpx");
    NSString *actionName = [self isActionWithSlash] ? OALocalizedString(@"shared_string_hide") : OALocalizedString(@"shared_string_show");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), actionName, nameRes];
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

@end
