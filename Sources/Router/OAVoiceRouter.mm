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
#import "OALocationPointWrapper.h"
#import "OAPointDescription.h"
#import "OAAlarmInfo.h"
#import "OARouteCalculationResult.h"
#import "OARouteDirectionInfo.h"

#import <AudioToolbox/AudioToolbox.h>


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

// turn types
static NSString * const A_LEFT = @"left";
static NSString * const A_LEFT_SH = @"left_sh";
static NSString * const A_LEFT_SL = @"left_sl";
static NSString * const A_LEFT_KEEP = @"left_keep";
static NSString * const A_RIGHT = @"right";
static NSString * const A_RIGHT_SH = @"right_sh";
static NSString * const A_RIGHT_SL = @"right_sl";
static NSString * const A_RIGHT_KEEP = @"right_keep";

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


- (instancetype) initWithHelper:(OARoutingHelper *)router
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
    float speed = _DEFAULT_SPEED;
    if (currentLocation != nil && currentLocation.speed) {
        speed = MAX(currentLocation.speed, speed);
    }
    
    OANextDirectionInfo *nextInfo = [_router getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] toSpeak:YES];
    const auto& currentSegment = [_router getCurrentSegmentResult];
    
    if (nextInfo == nil || nextInfo.directionInfo == nil) {
        return;
    }
    int dist = nextInfo.distanceTo;
    OARouteDirectionInfo *next = nextInfo.directionInfo;
    
    // If routing is changed update status to unknown
    if (next != nextRouteDirection) {
        nextRouteDirection = next;
        currentStatus = STATUS_UNKNOWN;
        suppressDest = false;
        playedAndArriveAtTarget = false;
        announceBackOnRoute = false;
        if (playGoAheadDist != -1) {
            playGoAheadDist = 0;
        }
    }
    
    if (!repeat) {
        if (dist <= 0) {
            return;
        } else if ([self needsInforming]) {
            [self playGoAhead:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
            return;
        } else if (currentStatus == STATUS_TOLD) {
            // nothing said possibly that's wrong case we should say before that
            // however it should be checked manually ?
            return;
        }
    }

    if (currentStatus == STATUS_UNKNOWN) {
        // Play "Continue for ..." if (1) after route calculation no other prompt is due, or (2) after a turn if next turn is more than PREPARE_LONG_DISTANCE away
        if ((playGoAheadDist == -1) || (dist > _PREPARE_LONG_DISTANCE)) {
            playGoAheadDist = dist - 3 * _TURN_DISTANCE;
        }
    }

    OANextDirectionInfo *nextNextInfo = [_router getNextRouteDirectionInfoAfter:nextInfo to:[[OANextDirectionInfo alloc] init] toSpeak:YES];
    // Note: getNextRouteDirectionInfoAfter(nextInfo, x, y).distanceTo is distance from nextInfo, not from current position!

    // STATUS_TURN = "Turn (now)"
    if ((repeat || [self statusNotPassed:STATUS_TURN]) && [self isDistanceLess:speed dist:dist etalon:_TURN_DISTANCE defSpeed:_TURN_DEFAULT_SPEED]) {
        if ([nextNextInfo distanceTo] < _TURN_IN_DISTANCE_END && nextNextInfo != nil) {
            [self playMakeTurn:currentSegment routeDirectionInfo:next nextDirectionInfo:nextNextInfo];
        } else {
            [self playMakeTurn:currentSegment routeDirectionInfo:next nextDirectionInfo:nil];
        }
    }
//        if (!next.getTurnType().goAhead() && isTargetPoint(nextNextInfo)) {   // !goAhead() avoids isolated "and arrive.." prompt, as goAhead() is not pronounced
//            if (nextNextInfo.distanceTo < TURN_IN_DISTANCE_END) {
//                // Issue #2865: Ensure a distance associated with the destination arrival is always announced, either here, or in subsequent "Turn in" prompt
//                // Distance fon non-straights already announced in "Turn (now)"'s nextnext  code above
//                if ((nextNextInfo != null) && (nextNextInfo.directionInfo != null) && nextNextInfo.directionInfo.getTurnType().goAhead()) {
//                    playThen();
//                    playGoAhead(nextNextInfo.distanceTo, empty);
//                }
//                playAndArriveAtDestination(nextNextInfo);
//            } else if (nextNextInfo.distanceTo < 1.2f * TURN_IN_DISTANCE_END) {
//                // 1.2 is safety margin should the subsequent "Turn in" prompt not fit in amy more
//                playThen();
//                playGoAhead(nextNextInfo.distanceTo, empty);
//                playAndArriveAtDestination(nextNextInfo);
//            }
//        }
//        nextStatusAfter(STATUS_TURN);
//
//        // STATUS_TURN_IN = "Turn in ..."
//    } else if ((repeat || statusNotPassed(STATUS_TURN_IN)) && isDistanceLess(speed, dist, TURN_IN_DISTANCE, 0f)) {
//        if (repeat || dist >= TURN_IN_DISTANCE_END) {
//            if ((isDistanceLess(speed, nextNextInfo.distanceTo, TURN_DISTANCE, 0f) || nextNextInfo.distanceTo < TURN_IN_DISTANCE_END) &&
//                nextNextInfo != null) {
//                playMakeTurnIn(currentSegment, next, dist - (int) btScoDelayDistance, nextNextInfo.directionInfo);
//            } else {
//                playMakeTurnIn(currentSegment, next, dist - (int) btScoDelayDistance, null);
//            }
//            playGoAndArriveAtDestination(repeat, nextInfo, currentSegment);
//        }
//        nextStatusAfter(STATUS_TURN_IN);
//
//        // STATUS_PREPARE = "Turn after ..."
//    } else if ((repeat || statusNotPassed(STATUS_PREPARE)) && (dist <= PREPARE_DISTANCE)) {
//        if (repeat || dist >= PREPARE_DISTANCE_END) {
//            if (!repeat && (next.getTurnType().keepLeft() || next.getTurnType().keepRight())) {
//                // Do not play prepare for keep left/right
//            } else {
//                playPrepareTurn(currentSegment, next, dist);
//                playGoAndArriveAtDestination(repeat, nextInfo, currentSegment);
//            }
//        }
//        nextStatusAfter(STATUS_PREPARE);
//
//        // STATUS_LONG_PREPARE =  also "Turn after ...", we skip this now, users said this is obsolete
//    } else if ((repeat || statusNotPassed(STATUS_LONG_PREPARE)) && (dist <= PREPARE_LONG_DISTANCE)) {
//        if (repeat || dist >= PREPARE_LONG_DISTANCE_END) {
//            playPrepareTurn(currentSegment, next, dist);
//            playGoAndArriveAtDestination(repeat, nextInfo, currentSegment);
//        }
//        nextStatusAfter(STATUS_LONG_PREPARE);
//
//        // STATUS_UNKNOWN = "Continue for ..." if (1) after route calculation no other prompt is due, or (2) after a turn if next turn is more than PREPARE_LONG_DISTANCE away
//    } else if (statusNotPassed(STATUS_UNKNOWN)) {
//        // Strange how we get here but
//        nextStatusAfter(STATUS_UNKNOWN);
//    } else if (repeat || (statusNotPassed(STATUS_PREPARE) && dist < playGoAheadDist)) {
//        playGoAheadDist = 0;
//        playGoAhead(dist, getSpeakableStreetName(currentSegment, next, false));
//    }
    
}

- (void) playGoAhead:(int) dist streetName:(NSString *)streetName
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
//        notifyOnVoiceMessage();
        [[play goAhead:dist streetName:streetName] play];
    }
}

- (void) playMakeTurn:(std::shared_ptr<RouteSegmentResult>) currentSegment routeDirectionInfo: (OARouteDirectionInfo *) nextInfo nextDirectionInfo: (OANextDirectionInfo *) nextNextInfo
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
        NSString *tParam = [self getTurnType:nextInfo.turnType];
        BOOL isplay = YES;
        if (tParam != nil) {
            [play turn:tParam streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:nextInfo includeDestination:!suppressDest]];
//        } else if (next.getTurnType().isRoundAbout()) {
//            play.roundAbout(next.getTurnType().getTurnAngle(), next.getTurnType().getExitOut(), getSpeakableStreetName(currentSegment, next, !suppressDest));
//        } else if (next.getTurnType().getValue() == TurnType.TU || next.getTurnType().getValue() == TurnType.TRU) {
//            play.makeUT(getSpeakableStreetName(currentSegment, next, !suppressDest));
            // Do not announce goAheads
            //} else if (next.getTurnType().getValue() == TurnType.C)) {
            //    play.goAhead();
        } else {
            isplay = false;
        }
        // Add turn after next
//        if ((nextNextInfo != nil) && (nextNextInfo.directionInfo != null)) {
//
//            // This case only needed should we want a prompt at the end of straight segments (equivalent of makeTurn) when nextNextInfo should be announced again there.
//            if (nextNextInfo.directionInfo.getTurnType().getValue() != TurnType.C && next.getTurnType().getValue() == TurnType.C) {
//                play.goAhead();
//                isplay = true;
//            }
//
//            String t2Param = getTurnType(nextNextInfo.directionInfo.getTurnType());
//            if (t2Param != null) {
//                if (isplay) {
//                    play.then();
//                    play.turn(t2Param, nextNextInfo.distanceTo, empty);
//                }
//            } else if (nextNextInfo.directionInfo.getTurnType().isRoundAbout()) {
//                if (isplay) {
//                    play.then();
//                    play.roundAbout(nextNextInfo.distanceTo, nextNextInfo.directionInfo.getTurnType().getTurnAngle(), nextNextInfo.directionInfo.getTurnType().getExitOut(), empty);
//                }
//            } else if (nextNextInfo.directionInfo.getTurnType().getValue() == TurnType.TU) {
//                if (isplay) {
//                    play.then();
//                    play.makeUT(nextNextInfo.distanceTo, empty);
//                }
//            }
//        }
//        if (isplay) {
//            notifyOnVoiceMessage();
//            play.play();
//        }
    }
}

- (BOOL) needsInforming {
//    int repeat = _settings.KEEP_INFORMING.get();
//    if (repeat == null || repeat == 0) return false;
    
    long notBefore = lastAnnouncement * 60 * 1000L;
    return (CACurrentMediaTime() * 1000) > notBefore;
}

- (BOOL) statusNotPassed:(int) statusToCheck
{
    return currentStatus <= statusToCheck;
}

- (NSString *) getTurnType:(std::shared_ptr<TurnType>) turnType
{
    if (TurnType::TL == turnType->getValue()) {
        return A_LEFT;
    } else if (TurnType::TSHL == turnType->getValue()) {
        return A_LEFT_SH;
    } else if (TurnType::TSLL == turnType->getValue()) {
        return A_LEFT_SL;
    } else if (TurnType::TR == turnType->getValue()) {
        return A_RIGHT;
    } else if (TurnType::TSHR == turnType->getValue()) {
        return A_RIGHT_SH;
    } else if (TurnType::TSLR == turnType->getValue()) {
        return A_RIGHT_SL;
    } else if (TurnType::KL == turnType->getValue()) {
        return A_LEFT_KEEP;
    } else if (TurnType::KR == turnType->getValue()) {
        return A_RIGHT_KEEP;
    }
    return nil;
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
    OACommandBuilder *builder = [self getNewCommandPlayerToPlay];
    if (builder != nil) {
        if (!newRoute)
        {
            [[builder routeRecalculated:[_router getLeftDistance] time:[_router getLeftTime]] play];
        }
        else
        {
            [[builder newRouteCalculated:[_router getLeftDistance] time:[_router getLeftTime]] play];
        }
        
    }
    else if (player == nil)
    {
        pendingCommand = [[OAVoiceCommandPending alloc] initWithType:((!newRoute) ? ROUTE_RECALCULATED : ROUTE_CALCULATED) voiceRouter:self];
    }
    if (newRoute)
    {
        playGoAheadDist = -1;
    }
    currentStatus = STATUS_UNKNOWN;
    suppressDest = NO;
    nextRouteDirection = nil;
}

- (void) announceBackOnRoute
{
    // TODO voice
}

- (void) announceCurrentDirection:(CLLocation *)currentLocation
{
    // TODO voice
}

- (NSString *) getSpeakableStreetName:(std::shared_ptr<RouteSegmentResult>) currentSegment routeDirectionInfo:(OARouteDirectionInfo *)next includeDestination:(BOOL) includeDest
{
    // TODO check for announcement settings if we should anounce streeet names
    if (next == nil) {
        return [NSString new];
    }
    NSString *nextStreet;
    NSString *currentStreet;
    if (player != nil) {
        // Issue 2377: Play Dest here only if not already previously announced, to avoid repetition
        if (includeDest == YES) {
            NSString *name = next.ref == nil ? (next.streetName == nil ? next.destinationName : next.streetName) : next.ref;
            nextStreet = [self getSpeakablePointName:name];
        } else {
            nextStreet = [self getSpeakablePointName:(next.ref == nil) ? [self getSpeakablePointName:next.streetName] : [self getSpeakablePointName:next.ref]];
        }
        if (currentSegment != nil) {
            // Issue 2377: Play Dest here only if not already previously announced, to avoid repetition
            if (includeDest == true) {
                const auto& obj = currentSegment->object;
//                currentStreet = getSpeakablePointName(obj.getRef(settings.MAP_PREFERRED_LOCALE.get(),
//                                                                                                 settings.MAP_TRANSLITERATE_NAMES.get(), currentSegment.isForwardDirection()))),
//                    getTermString(getSpeakablePointName(obj.getName(settings.MAP_PREFERRED_LOCALE.get(), settings.MAP_TRANSLITERATE_NAMES.get()))),
//                    getTermString(getSpeakablePointName(obj.getDestinationName(settings.MAP_PREFERRED_LOCALE.get(),
//                                                                               settings.MAP_TRANSLITERATE_NAMES.get(), currentSegment.isForwardDirection()))) });
            } else {
                const auto& obj = currentSegment->object;
//                current = new Struct(new Term[] { getTermString(getSpeakablePointName(obj.getRef(settings.MAP_PREFERRED_LOCALE.get(),
//                                                                                                 settings.MAP_TRANSLITERATE_NAMES.get(), currentSegment.isForwardDirection()))),
//                    getTermString(getSpeakablePointName(obj.getName(settings.MAP_PREFERRED_LOCALE.get(),
//                                                                    settings.MAP_TRANSLITERATE_NAMES.get()))),
//                    empty });
            }
        }
//        Struct voice = new Struct("voice", next, current );
//        return voice;
    } else {
//        Term rf = getTermString(getSpeakablePointName(i.getRef()));
//        if (rf == empty) {
//            rf = getTermString(getSpeakablePointName(i.getStreetName()));
//        }
//        return rf;
    }
    return @"Test";
}

- (NSString *) getSpeakablePointName: (NSString *) streetName
{
    if (streetName != nil) {
        return [[[[streetName stringByReplacingOccurrencesOfString:@"-" withString:@" "] stringByReplacingOccurrencesOfString:@":" withString:@" "] stringByReplacingOccurrencesOfString:@";" withString:@", "] stringByReplacingOccurrencesOfString:@"/" withString:@", "];
    
        // TODO add the settings
        //    if ((player != null) && (!player.getLanguage().equals("de"))) {
        //        pn = pn.replace("\u00df", "ss"); // Helps non-German TTS voices to pronounce German Straße (=street)
        //    }
        //    if ((player != null) && (player.getLanguage().startsWith("en"))) {
        //        pn = pn.replace("SR", "S R");    // Avoid SR (as for State Route or Strada Regionale) be pronounced as "Senior" in English TTS voice
        //        pn = pn.replace("Dr.", "Dr ");   // Avoid pause many English TTS voices introduce after period
        //    }
//        return res;
    }
    return [NSString new];
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
    //if ((settings.AUDIO_STREAM_GUIDANCE.getModeValue(router.getAppMode()) == 0) && !OAAbstractPrologCommandBuilder.btScoStatus) {
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

- (void) announceAlarm:(OAAlarmInfo *)info speed:(float)speed
{
    EOAAlarmInfoType type = info.type;
    if (type == AIT_SPEED_LIMIT)
    {
        [self announceSpeedAlarm:info.intValue speed:speed];
    }
    else if (type == AIT_SPEED_CAMERA)
    {
        if ([_settings.speakCameras get])
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p)
            {
                [self notifyOnVoiceMessage];
                [[p attention:@(type).stringValue] play];
            }
        }
    }
    else if (type == AIT_PEDESTRIAN)
    {
        if ([_settings.speakPedestrian get])
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p)
            {
                [self notifyOnVoiceMessage];
                [[p attention:@(type).stringValue] play];
            }
        }
    }
    else
    {
        if ([_settings.speakTrafficWarnings get])
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p)
            {
                [self notifyOnVoiceMessage];
                [[p attention:@(type).stringValue] play];
            }
            // See Issue 2377: Announce destination again - after some motorway tolls roads split shortly after the toll
            if (type == AIT_TOLL_BOOTH) {
                suppressDest = false;
            }
        }
    }
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

- (void) approachWaypoint:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    [self notifyOnVoiceMessage];
    double dist;
    [self makeSound];
    NSString *text = [self getText:location points:points dist:&dist];
    [[[p goAhead:dist streetName:nil] andArriveAtWayPoint:text] play];
}

- (void) approachFavorite:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    [self notifyOnVoiceMessage];
    double dist;
    [self makeSound];
    NSString *text = [self getText:location points:points dist:&dist];
    [[[p goAhead:dist streetName:nil] andArriveAtFavorite:text] play];
}

- (void) approachPoi:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    [self notifyOnVoiceMessage];
    double dist;
    [self makeSound];
    NSString *text = [self getText:location points:points dist:&dist];
    [[[p goAhead:dist streetName:nil] andArriveAtPoi:text] play];
}

- (void) announceWaypoint:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    [self notifyOnVoiceMessage];
    [self makeSound];
    NSString *text = [self getText:nil points:points dist:nullptr];
    [[p arrivedAtWayPoint:text] play];
}

- (void) announceFavorite:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    [self notifyOnVoiceMessage];
    [self makeSound];
    NSString *text = [self getText:nil points:points dist:nullptr];
    [[p arrivedAtFavorite:text] play];
}

- (void) announcePoi:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    [self notifyOnVoiceMessage];
    [self makeSound];
    NSString *text = [self getText:nil points:points dist:nullptr];
    [[p arrivedAtPoi:text] play];
}

- (NSString *) getText:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points dist:(double *)dist
{
    NSString *text = @"";
    for (OALocationPointWrapper *point in points)
    {
        // Need to calculate distance to nearest point
        if (text.length == 0)
        {
            if (location && dist != nullptr)
            {
                *dist = point.deviationDistance + [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:[point.point getLatitude] longitude:[point.point getLongitude]]];
            }
        }
        else
        {
            text = [text stringByAppendingString:@", "];
        }
        text = [text stringByAppendingString:[OAPointDescription getSimpleName:point.point]];
    }
    return text;
}

- (void) makeSound
{
    if ([self isMute])
        return;
    
    // Taken unaltered from https://freesound.org/people/Corsica_S/sounds/91926/ under license http://creativecommons.org/licenses/by/3.0/ :
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"ding" ofType:@"aiff"];
    if (soundPath)
    {
        SystemSoundID soundID;
        CFURLRef soundPathRef = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath: soundPath]);
        AudioServicesCreateSystemSoundID(soundPathRef, &soundID);
        AudioServicesPlaySystemSoundWithCompletion(soundID, nil);
        CFRelease(soundPathRef);
    }
}

- (void) notifyOnVoiceMessage
{
    // TODO: is wake possible on ios?
    /*
    if (settings.WAKE_ON_VOICE_INT.get() > 0) {
        router.getApplication().runInUIThread(new Runnable() {
            @Override
            public void run() {
                for (VoiceMessageListener lnt : voiceMessageListeners.keySet()) {
                    lnt.onVoiceMessage();
                }
            }
        });
    }
     */
}

@end
