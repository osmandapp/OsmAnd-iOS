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
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideGPXTracksAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OASelectedGPXHelper *helper = [OASelectedGPXHelper instance];
    if (helper.isShowingAnyGpxFiles)
        [helper clearAllGpxFilesToShow:YES];
    else
        [helper restoreSelectedGpxFiles];
    
    [[OsmAndApp instance].mapSettingsChangeObservable notifyEvent];
}

- (BOOL)isActionWithSlash
{
    return [OAAppSettings sharedManager].mapSettingShowFavorites;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_show_gpx_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_gpx") : OALocalizedString(@"show_gpx");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:28 stringId:@"gpx.showhide" class:self.class name:OALocalizedString(@"add_first_inermediate") category:CONFIGURE_MAP iconName:@"ic_custom_trip" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
