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
#import "OACommandBuilder.h"
#import "OACommandPlayer.h"
#import "OAVoiceCommandPending.h"

@implementation OAVoiceRouter
{
    OARoutingHelper *_router;
    OAAppSettings *_settings;
    
    double _btScoDelayDistance;
}

const int STATUS_UTWP_TOLD = -1;
const int STATUS_UNKNOWN = 0;
const int STATUS_LONG_PREPARE = 1;
const int STATUS_PREPARE = 2;
const int STATUS_TURN_IN = 3;
const int STATUS_TURN = 4;
const int STATUS_TOLD = 5;

id<OACommandPlayer> player;
OAVoiceCommandPending *pendingCommand;
OARouteDirectionInfo *nextRouteDirection;

BOOL mute = false;
int currentStatus = STATUS_UNKNOWN;
BOOL playedAndArriveAtTarget = false;
float playGoAheadDist = 0;
long lastAnnouncedSpeedLimit = 0;
long waitAnnouncedSpeedLimit = 0;
long lastAnnouncedOffRoute = 0;
long waitAnnouncedOffRoute = 0;
BOOL suppressDest = false;
BOOL announceBackOnRoute = false;
// Remember when last announcement was made
long lastAnnouncement = 0;


- (instancetype)initWithHelper:(OARoutingHelper *)router
{
    self = [super init];
    if (self)
    {
        _router = router;
        _settings = [OAAppSettings sharedManager];
        
        mute = _settings.voiceMute;
        
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

- (void) setPlayer:(id<OACommandPlayer>)player_
{
    player = player_;
    if (pendingCommand && player_)
    {
        OACommandBuilder *newCommand = [self getNewCommandPlayerToPlay];
        if (newCommand)
            [pendingCommand play:newCommand];
        
        pendingCommand = nil;
    }
}

- (id<OACommandPlayer>) getPlayer
{
    return player;
}

- (void) setMute:(BOOL)mute_
{
    mute = mute_;
}

- (BOOL) isMute
{
    return mute;
}

- (OACommandBuilder *) getNewCommandPlayerToPlay
{
    if (!player)
        return nil;
    
    lastAnnouncement = CACurrentMediaTime() * 1000;
    return [player newCommandBuilder];
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

- (void) announceSpeedAlarm:(int)maxSpeed speed:(float)speed
{
    long ms = CACurrentMediaTime() * 1000;
    if (waitAnnouncedSpeedLimit == 0)
    {
        //  Wait 10 seconds before announcement
        if (ms - lastAnnouncedSpeedLimit > 120 * 1000)
            waitAnnouncedSpeedLimit = ms;
    }
    else
    {
        // If we wait before more than 20 sec (reset counter)
        if (ms - waitAnnouncedSpeedLimit > 20 * 1000)
        {
            waitAnnouncedSpeedLimit = 0;
        }
        else if ([_settings.speakSpeedLimit get] && ms - waitAnnouncedSpeedLimit > 10 * 1000)
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p)
            {
                [self notifyOnVoiceMessage];
                lastAnnouncedSpeedLimit = ms;
                waitAnnouncedSpeedLimit = 0;
                [[p speedAlarm:maxSpeed speed:speed] play];
            }
        }
    }
}

- (void) notifyOnVoiceMessage
{
    // TODO
}

@end
