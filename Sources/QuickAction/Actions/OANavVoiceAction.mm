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

@implementation OANavVoiceAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeNavVoice];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL voice = settings.voiceMute;
    
    [settings setVoiceMute:!voice];
    [[OARoutingHelper sharedInstance].getVoiceRouter setMute:!voice];
}

- (BOOL)isActionWithSlash
{
    return ![OAAppSettings sharedManager].voiceMute;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_voice_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"mute_voice") : OALocalizedString(@"unmute_voice");
}

@end
