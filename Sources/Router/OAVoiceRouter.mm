//
//  OAVoiceRouter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAVoiceRouter.h"
#import "OARoutingHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"

@implementation OAVoiceRouter
{
    OARoutingHelper *_router;
    OAAppSettings *_settings;

}

- (instancetype)initWithHelper:(OARoutingHelper *)router
{
    self = [super init];
    if (self)
    {
        _router = router;
        _settings = [OAAppSettings sharedManager];
        
        /*
         this.mute = settings.VOICE_MUTE.get();
         empty = new Struct("");
         voiceMessageListeners = new ConcurrentHashMap<VoiceRouter.VoiceMessageListener, Integer>();
         */
    }
    return self;
}

- (void) updateAppMode
{
    // TODO
}

@end
