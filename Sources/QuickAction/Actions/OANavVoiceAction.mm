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
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OANavVoiceAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL voice = [settings.voiceMute get];
    
    [[OARoutingHelper sharedInstance].getVoiceRouter setMute:!voice];
}

- (BOOL)isActionWithSlash
{
    return ![[OAAppSettings sharedManager].voiceMute get];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_voice_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"mute_voice") : OALocalizedString(@"unmute_voice");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:11 stringId:@"nav.voice" class:self.class name:OALocalizedString(@"quick_action_navigation_voice") category:NAVIGATION iconName:@"ic_custom_sound" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
