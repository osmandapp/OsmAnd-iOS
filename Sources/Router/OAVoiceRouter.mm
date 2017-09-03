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

    BOOL _mute;
}

- (instancetype)initWithHelper:(OARoutingHelper *)router
{
    self = [super init];
    if (self)
    {
        _router = router;
        _settings = [OAAppSettings sharedManager];
        
         _mute = _settings.voiceMute;
         //empty = new Struct("");
         //voiceMessageListeners = new ConcurrentHashMap<VoiceRouter.VoiceMessageListener, Integer>();
    }
    return self;
}

- (void) updateAppMode
{
    // TODO voice
}

- (void) arrivedIntermediatePoint:(NSString *)name
{
    // TODO voice
}

- (void) arrivedDestinationPoint:(NSString *)name
{
    // TODO voice
}

- (void) updateStatus:(CLLocation *)currentLocation repeat:(BOOL)repeat
{
    // TODO voice
}

- (void) interruptRouteCommands
{
    // TODO voice
}

- (void) announceOffRoute:(double)dist
{
    // TODO voice
}

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    // TODO voice
}

- (void) announceBackOnRoute
{
    // TODO voice
}

- (void) setMute:(BOOL) mute
{
    _mute = mute;
}

- (BOOL) isMute
{
    return _mute;
}


@end
