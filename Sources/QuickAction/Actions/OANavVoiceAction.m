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
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

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
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavVoiceActionId
                                            stringId:@"nav.voice"
                                                  cl:self.class]
               name:OALocalizedString(@"voices")]
               nameAction:OALocalizedString(@"quick_action_verb_turn_on_off")]
              iconName:@"ic_custom_sound"]
             category:QuickActionTypeCategoryNavigation]
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
