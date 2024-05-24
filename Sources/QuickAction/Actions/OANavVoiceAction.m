//
//  OANavVoiceAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavVoiceAction.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OANavVoiceAction
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsNavVoiceActionId
                                            stringId:@"nav.voice"
                                                  cl:self.class]
               name:OALocalizedString(@"quick_action_navigation_voice")]
              iconName:@"ic_custom_sound"]
             category:EOAQuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)execute
{
    BOOL voice = [_settings.voiceMute get];
    [[OARoutingHelper sharedInstance].getVoiceRouter setMute:!voice];
}

- (BOOL)isActionWithSlash
{
    return ![_settings.voiceMute get];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_voice_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"quick_action_navigation_voice_on") : OALocalizedString(@"quick_action_navigation_voice_off");
}

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
