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
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideGPXTracksAction
{
    OASelectedGPXHelper *_helper;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideGpxTracksActionId
                                            stringId:@"gpx.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"show_hide_gpx")]
              iconName:@"ic_custom_trip"]
             category:EOAQuickActionTypeCategoryConfigureMap]
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
    return [self isActionWithSlash] ? OALocalizedString(@"hide_gpx") : OALocalizedString(@"show_gpx");
}

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
