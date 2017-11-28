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
    double _btScoDelayDistance;
}

- (instancetype)initWithHelper:(OARoutingHelper *)router
{
    self = [super init];
    if (self)
    {
        _router = router;
        _settings = [OAAppSettings sharedManager];
        
         _mute = _settings.voiceMute;
        _btScoDelayDistance = 0.0;
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
    // Turn prompt starts either at distance, or additionally (TURN_IN and TURN only) if actual-lead-time(currentSpeed) < maximum-lead-time(defined by default speed)
    if ([[_router getAppMode] isDerivedRoutingFrom:[OAApplicationMode CAR]])
    {
        _PREPARE_LONG_DISTANCE = 3500;             // [105 sec @ 120 km/h]
        // Issue 1411: Do not play prompts for PREPARE_LONG_DISTANCE, not needed.
        _PREPARE_LONG_DISTANCE_END = 3000 + 1000;  // [ 90 sec @ 120 km/h]
        _PREPARE_DISTANCE = 1500;                  // [125 sec]
        _PREPARE_DISTANCE_END = 1200;            // [100 sec]
        _TURN_IN_DISTANCE = 300;              //   23 sec
        _TURN_IN_DISTANCE_END = 210;               //   16 sec
        _TURN_DISTANCE = 50;                       //    7 sec
        _TURN_DEFAULT_SPEED = 7.f;                  //   25 km/h
        _DEFAULT_SPEED = 13;                       //   48 km/h
    }
    else if ([[_router getAppMode] isDerivedRoutingFrom:[OAApplicationMode BICYCLE]])
    {
        _PREPARE_LONG_DISTANCE = 500;              // [100 sec]
        // Do not play:
        _PREPARE_LONG_DISTANCE_END = 300 + 1000;   // [ 60 sec]
        _PREPARE_DISTANCE = 200;                   // [ 40 sec]
        _PREPARE_DISTANCE_END = 120;               // [ 24 sec]
        _TURN_IN_DISTANCE = 80;                    //   16 sec
        _TURN_IN_DISTANCE_END = 60;                //   12 sec
        _TURN_DISTANCE = 30;                       //    6 sec. Check if this works with GPS accuracy!
        _TURN_DEFAULT_SPEED = _DEFAULT_SPEED = 5;   //   18 km/h
    }
    else if ([[_router getAppMode] isDerivedRoutingFrom:[OAApplicationMode PEDESTRIAN]])
    {
        // prepare_long_distance warning not needed for pedestrian, but for goAhead prompt
        _PREPARE_LONG_DISTANCE = 500;
        // Do not play:
        _PREPARE_LONG_DISTANCE_END = 300 + 300;
        // Prepare distance is not needed for pedestrian
        _PREPARE_DISTANCE = 200;                    // [100 sec]
        // Do not play:
        _PREPARE_DISTANCE_END = 150 + 100;          // [ 75 sec]
        _TURN_IN_DISTANCE = 50;                     //   25 sec
        _TURN_IN_DISTANCE_END = 30;                 //   15 sec
        _TURN_DISTANCE = 15;                        //   7,5sec. Check if this works with GPS accuracy!
        _TURN_DEFAULT_SPEED = _DEFAULT_SPEED = 2.f;   //   7,2 km/h
    }
    else
    {
        _DEFAULT_SPEED = [_router getAppMode].defaultSpeed;
        _TURN_DEFAULT_SPEED = _DEFAULT_SPEED / 2;
        _PREPARE_LONG_DISTANCE = (int) (_DEFAULT_SPEED * 270);
        // Do not play:
        _PREPARE_LONG_DISTANCE_END = (int) (_DEFAULT_SPEED * 230) * 2;
        _PREPARE_DISTANCE = (int) (_DEFAULT_SPEED * 115);
        _PREPARE_DISTANCE_END = (int) (_DEFAULT_SPEED * 92);
        _TURN_IN_DISTANCE = (int) (_DEFAULT_SPEED * 23);
        _TURN_IN_DISTANCE_END = (int) (_DEFAULT_SPEED * 16);
        _TURN_DISTANCE = (int) (_DEFAULT_SPEED * 7);
    }
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
    float speed = _DEFAULT_SPEED;
    if (loc && loc.speed >= 0)
        speed = loc.speed;
    
    if ([self isDistanceLess:speed dist:dist etalon:_TURN_DISTANCE defSpeed:0])
        return 0;
    else if (dist <= _PREPARE_DISTANCE)
        return 1;
    else if (dist <= _PREPARE_LONG_DISTANCE)
        return 2;
    else
        return -1;
}

- (BOOL) isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon defSpeed:(float)defSpeed
{
    if (defSpeed <= 0)
        defSpeed = _DEFAULT_SPEED;
    
    if (currentSpeed <= 0)
        currentSpeed = _DEFAULT_SPEED;
    
    // Trigger close prompts earlier if delayed for BT SCO connection establishment
    // TODO: Java > Obj-C
    //if ((settings.AUDIO_STREAM_GUIDANCE.getModeValue(router.getAppMode()) == 0) && !AbstractPrologCommandPlayer.btScoStatus) {
    //    btScoDelayDistance = currentSpeed * (double) settings.BT_SCO_DELAY.get() / 1000;
    //}
    
    if ((dist < etalon + _btScoDelayDistance) || ((dist - _btScoDelayDistance) / currentSpeed) < (etalon / defSpeed))
        return YES;
    
    return NO;
}

- (void) gpsLocationLost
{
    // TODO voice
}

- (void) gpsLocationRecover
{
    // TODO voice
}

@end
