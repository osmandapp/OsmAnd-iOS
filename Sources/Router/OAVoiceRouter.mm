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
        
        // Default speed to have comfortable announcements (Speed in m/s)
        _DEFAULT_SPEED = 12;
        _TURN_DEFAULT_SPEED = 5;
        
        _PREPARE_LONG_DISTANCE = 0;
        _PREPARE_LONG_DISTANCE_END = 0;
        _PREPARE_DISTANCE = 0;
        _PREPARE_DISTANCE_END = 0;
        _TURN_IN_DISTANCE = 0;
        _TURN_IN_DISTANCE_END = 0;
        _TURN_DISTANCE = 0;
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

- (void) announceCurrentDirection:(CLLocation *)currentLocation
{
    // TODO voice
}

- (int) calculateImminent:(float)dist loc:(CLLocation *)loc
{
    // TODO voice
    return -1;
}

- (BOOL) isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon defSpeed:(float)defSpeed
{
    // TODO voice
    return YES;
}

@end
