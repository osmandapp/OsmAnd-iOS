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

@implementation OAShowHideGPXTracksAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeToggleGPX];
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

@end
