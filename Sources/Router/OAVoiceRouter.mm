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
#import "Localization.h"
#import "OAExitInfo.h"

#import <AudioToolbox/AudioToolbox.h>


@implementation OAVoiceRouter
{
    OARoutingHelper *_router;
    OAAppSettings *_settings;
    
    double _voicePromptDelayDistance;
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
std::string preferredLanguage;


- (instancetype) initWithHelper:(OARoutingHelper *)router
{
    self = [super init];
    if (self)
    {
        _router = router;
        _settings = [OAAppSettings sharedManager];
        
        NSString *prefLang =  _settings.settingPrefMapLanguage.get == nil ? OALocalizedString(@"local_names") : _settings.settingPrefMapLanguage.get;
        preferredLanguage = std::string([prefLang UTF8String]);
        
        _voicePromptDelayDistance = 0.0;
        //empty = new Struct("");
        //voiceMessageListeners = new ConcurrentHashMap<VoiceRouter.VoiceMessageListener, Integer>();
        
        // Default speed to have comfortable announcements (Speed in m/s)
        _DEFAULT_SPEED = 12;
        _TURN_NOW_SPEED = 5;
        
        _PREPARE_LONG_DISTANCE = 0;
        _PREPARE_LONG_DISTANCE_END = 0;
        _PREPARE_DISTANCE = 0;
        _PREPARE_DISTANCE_END = 0;
        _TURN_IN_DISTANCE = 0;
        _TURN_IN_DISTANCE_END = 0;
        _TURN_NOW_DISTANCE = 0;
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

- (void) setMute:(BOOL)mute
{
    [_settings.voiceMute set:mute];
}

- (void) setMute:(BOOL)mute mode:(OAApplicationMode *)mode
{
    [_settings.voiceMute set:mute mode:mode];
}

- (BOOL) isMute
{
    return [_settings.voiceMute get];
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
    OAApplicationMode *appMode = _router.getAppMode == nil ? _settings.applicationMode.get : _router.getAppMode;
    // could be changed in future as others by default in settings is 45 kmh
    if ([appMode isDerivedRoutingFrom:[OAApplicationMode CAR]])
    {
        _DEFAULT_SPEED = 14;                       //   ~50 km/h
        //DEFAULT speed is configurable
        //        } else if (router.getAppMode().isDerivedRoutingFrom(ApplicationMode.BICYCLE)) {
        //            DEFAULT_SPEED = 2.77f;   //   10 km/h
        //        } else if (router.getAppMode().isDerivedRoutingFrom(ApplicationMode.PEDESTRIAN)) {
        //            DEFAULT_SPEED = 1.11f; //4 km/h 2f;     // 7,2 km/h
    }
    else
    {
        // minimal is 1 meter for turn now
        _DEFAULT_SPEED = MAX([appMode getDefaultSpeed], 0.3);
    }
    // Do not play [issue 1411]: prepare_long_distance warning not needed, used only for goAhead prompt
    // 300 sec: 4 200 - 3 500 m - car [ 115 - 95 sec @ 120 km/h]
    _PREPARE_LONG_DISTANCE = (int) (_DEFAULT_SPEED * 300);
    _PREPARE_LONG_DISTANCE_END = (int) (_DEFAULT_SPEED * 250) ;
    
    if (_DEFAULT_SPEED < 30) {
        //        if (PREPARE_LONG_DISTANCE_END - PREPARE_DISTANCE < 4000) {
        // Play only for high speed vehicle with speed > 110 km/h
        _PREPARE_DISTANCE_END = _PREPARE_DISTANCE * 2;
    }
    
    // *#8749: Here the change for bicycle: 40-30 sec, 200-150 m -> 115-90 sec, 320-250m [ need to be tested ]
    // 115 sec: 1 500 m - car [45 sec @ 120 km/h], 320 m - bicycle [45 sec @ 25 km/h], 230 m - pedestrian
    _PREPARE_DISTANCE = (int) (_DEFAULT_SPEED * 115);
    // 90  sec: 1 200 m - car, 250 m - bicycle [36 sec @ 25 km/h],
    _PREPARE_DISTANCE_END = (int) (_DEFAULT_SPEED * 90);
    
    // 22 sec: 310 m - car, 60 m - bicycle, 50m - pedestrian
    _TURN_IN_DISTANCE = (int) (_DEFAULT_SPEED * 22);
    // 15 sec: 210 m - car, 40 m - bicycle, 30 m - pedestrian
    _TURN_IN_DISTANCE_END = (int) (_DEFAULT_SPEED * 15);
    
    // same as speed < 150/(90-22) m/s = 2.2 m/s = 8 km/h
    if (_PREPARE_DISTANCE_END - _TURN_IN_DISTANCE < 150) {
        // Do not play: for pedestrian and slow transport
        _PREPARE_DISTANCE_END = _PREPARE_DISTANCE * 2;
    }
    
    // Turn now: 3.5 sec normal speed, 7 second for halfspeed (default)
    // float TURN_NOW_TIME = 7;
    
    // ** #8749 to keep 1m / 1 sec precision (GPS_TOLERANCE - 12 m)
    // 1 kmh - 1 m, 4 kmh - 4 m (pedestrian), 10 kmh - 10 m (bicycle), 50 kmh - 50 m (car)
    // TURN_NOW_DISTANCE = (int) (DEFAULT_SPEED * 3.6); // 3.6 sec
    // 50 kmh - 48 m (car), 10 kmh - 20 m, 4 kmh - 15 m, 1 kmh - 12 m
    _TURN_NOW_DISTANCE = (int) (OARoutingHelper.getGpsTolerance + _DEFAULT_SPEED * 2.5 * OARoutingHelper.getArrivalDistanceFactor); // 3.6 sec
    // 1 kmh - 1 sec, 4 kmh - 2 sec (pedestrian), 10 kmh - 3 sec (*bicycle), 50 kmh - 7 sec (car)
    double _TURN_NOW_TIME = MIN(sqrt(_DEFAULT_SPEED * 3.6), 8);
    
    _TURN_NOW_SPEED = _TURN_NOW_DISTANCE / _TURN_NOW_TIME;
}

- (void) arrivedIntermediatePoint:(NSString *)name
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
        //        notifyOnVoiceMessage();
        [[play arrivedAtIntermediatePoint:name] play];
    }
}

- (void) arrivedDestinationPoint:(NSString *)name
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
        //        notifyOnVoiceMessage();
        [[play arrivedAtDestination:name] play];
    }
}

- (void) updateStatus:(CLLocation *)currentLocation repeat:(BOOL)repeat
{
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
            playGoAheadDist = dist - 3 * _TURN_NOW_DISTANCE;
        }
    }

    OANextDirectionInfo *nextNextInfo = [_router getNextRouteDirectionInfoAfter:nextInfo to:[[OANextDirectionInfo alloc] init] toSpeak:YES];
    // Note: getNextRouteDirectionInfoAfter(nextInfo, x, y).distanceTo is distance from nextInfo, not from current position!

    // STATUS_TURN = "Turn (now)"
    if ((repeat || [self statusNotPassed:STATUS_TURN]) && [self isDistanceLess:speed dist:dist etalon:_TURN_NOW_DISTANCE defSpeed:_TURN_NOW_SPEED]) {
        if ([nextNextInfo distanceTo] < _TURN_IN_DISTANCE_END && nextNextInfo != nil) {
            [self playMakeTurn:currentSegment routeDirectionInfo:next nextDirectionInfo:nextNextInfo];
        } else {
            [self playMakeTurn:currentSegment routeDirectionInfo:next nextDirectionInfo:nil];
        }
        if (!next.turnType->goAhead() && [self isTargetPoint:nextNextInfo]) {   // !goAhead() avoids isolated "and arrive.." prompt, as goAhead() is not pronounced
            if (nextNextInfo.distanceTo < _TURN_IN_DISTANCE_END) {
                // Issue #2865: Ensure a distance associated with the destination arrival is always announced, either here, or in subsequent "Turn in" prompt
                // Distance fon non-straights already announced in "Turn (now)"'s nextnext  code above
                if (nextNextInfo != nil && nextNextInfo.directionInfo != nil && nextNextInfo.directionInfo.turnType->goAhead()) {
                    [self playThen];
                    [self playGoAhead:nextNextInfo.distanceTo streetName:[NSMutableDictionary new]];
                }
                [self playAndArriveAtDestination:nextNextInfo];
            } else if (nextNextInfo.distanceTo < 1.2f * _TURN_IN_DISTANCE_END) {
                // 1.2 is safety margin should the subsequent "Turn in" prompt not fit in amy more
                [self playThen];
                [self playGoAhead:nextNextInfo.distanceTo streetName:[NSMutableDictionary new]];
                [self playAndArriveAtDestination:nextNextInfo];
            }
        }
        [self nextStatusAfter:STATUS_TURN];

        // STATUS_TURN_IN = "Turn in ..."
    } else if ((repeat || [self statusNotPassed:STATUS_TURN_IN]) && [self isDistanceLess:speed dist:dist etalon:_TURN_IN_DISTANCE]) {
        if (repeat || dist >= _TURN_IN_DISTANCE_END) {
            if (([self isDistanceLess:speed dist:nextNextInfo.distanceTo etalon:_TURN_NOW_DISTANCE] || nextNextInfo.distanceTo < _TURN_IN_DISTANCE_END) &&
                nextNextInfo != nil) {
                [self playMakeTurnIn:currentSegment info:next dist:(dist - (int) _voicePromptDelayDistance) nextInfo:nextNextInfo.directionInfo];
            } else {
                [self playMakeTurnIn:currentSegment info:next dist:(dist - (int) _voicePromptDelayDistance) nextInfo:nil];
            }
            [self playGoAndArriveAtDestination:repeat nextInfo:nextInfo currSegment:currentSegment];
        }
        [self nextStatusAfter:STATUS_TURN_IN];

        // STATUS_PREPARE = "Turn after ..."
    } else if ((repeat || [self statusNotPassed:STATUS_PREPARE]) && (dist <= _PREPARE_DISTANCE)) {
        if (repeat || dist >= _PREPARE_DISTANCE_END) {
            if (!repeat && (next.turnType->keepLeft() || next.turnType->keepRight())) {
                // Do not play prepare for keep left/right
            } else {
                [self playPrepareTurn:currentSegment next:next dist:dist];
                [self playGoAndArriveAtDestination:repeat nextInfo:nextInfo currSegment:currentSegment];
            }
        }
        [self nextStatusAfter:STATUS_PREPARE];

    // STATUS_LONG_PREPARE =  also "Turn after ...", we skip this now, users said this is obsolete
    } else if ((repeat || [self statusNotPassed:STATUS_LONG_PREPARE]) && (dist <= _PREPARE_LONG_DISTANCE)) {
        if (repeat || dist >= _PREPARE_LONG_DISTANCE_END) {
            [self playPrepareTurn:currentSegment next:next dist:dist];
            [self playGoAndArriveAtDestination:repeat nextInfo:nextInfo currSegment:currentSegment];
        }
        [self nextStatusAfter:STATUS_LONG_PREPARE];
//
        // STATUS_UNKNOWN = "Continue for ..." if (1) after route calculation no other prompt is due, or (2) after a turn if next turn is more than PREPARE_LONG_DISTANCE away
    } else if ([self statusNotPassed:STATUS_UNKNOWN]) {
        // Strange how we get here but
        [self nextStatusAfter:STATUS_UNKNOWN];
    } else if (repeat || ([self statusNotPassed:STATUS_PREPARE] && dist < playGoAheadDist)) {
        playGoAheadDist = 0;
        [self playGoAhead:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
    }
}

- (void) playMakeTurnIn:(std::shared_ptr<RouteSegmentResult>) currentSegment info:(OARouteDirectionInfo *) next dist:(int) dist nextInfo:(OARouteDirectionInfo *) pronounceNextNext
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
        NSString *tParam = [self getTurnType:next.turnType];
        BOOL isPlay = YES;
        OAExitInfo *exitInfo = next.exitInfo;
        if (tParam != nil) {
            if (exitInfo != nil && exitInfo.ref.length > 0)
            {
                NSString *stringRef = [self getSpeakableExitRef:exitInfo.ref];
                [play takeExit:tParam dist:dist exitString:stringRef exitInt:[self getIntRef:exitInfo.ref] streetName:[self getSpeakableExitName:next exitInfo:exitInfo includeDest:YES]];
            }
            else
            {
                [play turn:tParam dist:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]];
            }
            suppressDest = YES;
        } else if (next.turnType->isRoundAbout()) {
            [play roundAbout:dist angle:next.turnType->getTurnAngle() exit:next.turnType->getExitOut() streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]];
            // Other than in prepareTurn, in prepareRoundabout we do not announce destination, so we can repeat it one more time
            suppressDest = false;
        } else if (next.turnType->getValue() == TurnType::TU || next.turnType->getValue() == TurnType::TRU) {
            [play makeUT:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]];
            suppressDest = true;
        } else {
            isPlay = false;
        }
        // 'then keep' preparation for next after next. (Also announces an interim straight segment, which is not pronounced above.)
        if (pronounceNextNext != nil) {
            std::shared_ptr<TurnType> t = pronounceNextNext.turnType;
            isPlay = true;
            if (t->getValue() != TurnType::C && next.turnType->getValue() == TurnType::C) {
                [play goAhead:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]];
            }
            if (t->getValue() == TurnType::TL || t->getValue() == TurnType::TSHL || t->getValue() == TurnType::TSLL
                || t->getValue() == TurnType::TU || t->getValue() == TurnType::KL ) {
                [[play then] bearLeft:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
            } else if (t->getValue() == TurnType::TR || t->getValue() == TurnType::TSHR || t->getValue() == TurnType::TSLR
                       || t->getValue() == TurnType::TRU || t->getValue() == TurnType::KR) {
                [[play then] bearRight:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
            }
        }
        if (isPlay) {
            [play play];
        }
    }
}

- (void) playPrepareTurn:(std::shared_ptr<RouteSegmentResult>) currentSegment next:(OARouteDirectionInfo *) next dist:(int) dist
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
        NSString *tParam = [self getTurnType:next.turnType];
        if (tParam != nil) {
//            notifyOnVoiceMessage();
            [[play prepareTurn:tParam dist:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]] play];
        } else if (next.turnType->isRoundAbout()) {
//            notifyOnVoiceMessage();
            [[play prepareRoundAbout:dist exit:next.turnType->getExitOut() streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]] play];
        } else if (next.turnType->getValue() == TurnType::TU || next.turnType->getValue() == TurnType::TRU) {
//            notifyOnVoiceMessage();
            [[play prepareMakeUT:dist streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:YES]] play];
        }
    }
}

- (void) playGoAndArriveAtDestination:(BOOL) repeat nextInfo:(OANextDirectionInfo *) nextInfo currSegment:(std::shared_ptr<RouteSegmentResult>) currentSegment
{
    OARouteDirectionInfo *next = nextInfo.directionInfo;
    if ([self isTargetPoint:nextInfo] && (!playedAndArriveAtTarget || repeat)) {
        if (next.turnType->goAhead()) {
            [self playGoAhead:nextInfo.distanceTo streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
            [self playAndArriveAtDestination:nextInfo];
            playedAndArriveAtTarget = true;
        } else if (nextInfo.distanceTo <= 2 * _TURN_IN_DISTANCE) {
            [self playAndArriveAtDestination:nextInfo];
            playedAndArriveAtTarget = true;
        }
    }
}

- (void) playAndArriveAtDestination:(OANextDirectionInfo *) info
{
    if ([self isTargetPoint:info]) {
        NSString *pointName = info == nil ? @"" : info.pointName;
        OACommandBuilder *play = [self getNewCommandPlayerToPlay];
        if (play != nil) {
//            notifyOnVoiceMessage();
            if (info != nil && info.intermediatePoint) {
                [[play andArriveAtIntermediatePoint:[self getSpeakablePointName:pointName]] play];
            } else {
                [[play andArriveAtDestination:[self getSpeakablePointName:pointName]] play];
            }
        }
    }
}

- (void) playGoAhead:(int) dist streetName:(NSMutableDictionary *)streetName
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
//        notifyOnVoiceMessage();
        [[play goAhead:dist streetName:streetName] play];
    }
}

- (void) playThen
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil)
    {
//      notifyOnVoiceMessage();
        [[play then] play];
    }
}

- (void) playMakeTurn:(std::shared_ptr<RouteSegmentResult>)currentSegment routeDirectionInfo: (OARouteDirectionInfo *)nextInfo nextDirectionInfo:(OANextDirectionInfo *)nextNextInfo
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil)
    {
        NSString *tParam = [self getTurnType:nextInfo.turnType];
        OAExitInfo *exitInfo = nextInfo.exitInfo;
        BOOL isplay = YES;
        if (tParam != nil) {
            if (exitInfo != nil && exitInfo.ref.length > 0)
            {
                NSString *stringRef = [self getSpeakableExitRef:exitInfo.ref];
                [play takeExit:tParam exitString:stringRef exitInt:[self getIntRef:exitInfo.ref] streetName:[self getSpeakableExitName:nextInfo exitInfo:exitInfo includeDest:!suppressDest]];
            }
            else
            {
                [play turn:tParam streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:nextInfo includeDestination:!suppressDest]];
            }
        } else if (nextInfo.turnType->isRoundAbout()) {
            [play roundAbout:nextInfo.turnType->getTurnAngle() exit:nextInfo.turnType->getExitOut() streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:nextInfo includeDestination:!suppressDest]];
        } else if (nextInfo.turnType->getValue() == TurnType::TU || nextInfo.turnType->getValue() == TurnType::TRU) {
            [play makeUT:[self getSpeakableStreetName:currentSegment routeDirectionInfo:nextInfo includeDestination:!suppressDest]];
//          Do not announce goAheads
        } else if (nextInfo.turnType->getValue() == TurnType::C) {
                [play goAhead];
        } else {
            isplay = false;
        }
        // Add turn after next
        if ((nextNextInfo != nil) && (nextNextInfo.directionInfo != nil)) {

            // This case only needed should we want a prompt at the end of straight segments (equivalent of makeTurn) when nextNextInfo should be announced again there.
            if (nextNextInfo.directionInfo.turnType->getValue() != TurnType::C && nextInfo.turnType->getValue() == TurnType::C) {
                [play goAhead];
                isplay = true;
            }

            NSString *t2Param = [self getTurnType:nextNextInfo.directionInfo.turnType];
            if (t2Param != nil)
            {
                if (isplay) {
                    [play then];
                    [play turn:t2Param dist:nextNextInfo.distanceTo streetName:[NSMutableDictionary new]];
                }
            }
            else if (nextNextInfo.directionInfo.turnType->isRoundAbout()) {
                if (isplay) {
                    [play then];
                    [play roundAbout:nextNextInfo.distanceTo angle:nextNextInfo.directionInfo.turnType->getTurnAngle() exit:nextNextInfo.directionInfo.turnType->getExitOut() streetName:[NSMutableDictionary new]];
                }
            } else if (nextNextInfo.directionInfo.turnType->getValue() == TurnType::TU) {
                if (isplay) {
                    [play then];
                    [play makeUT:nextNextInfo.distanceTo streetName:[NSMutableArray new]];
                }
            }
        }
        if (isplay) {
//          notifyOnVoiceMessage();
            [play play];
        }
    }
}

- (void) nextStatusAfter:(int) previousStatus
{
    if (previousStatus != STATUS_TOLD) {
        currentStatus = previousStatus + 1;
    } else {
        currentStatus = previousStatus;
    }
}

- (BOOL) isTargetPoint:(OANextDirectionInfo *) info
{
    BOOL intermediate = info != nil && info.intermediatePoint;
    BOOL target = info == nil || info.directionInfo == nil
    || info.directionInfo.distance == 0;
    return intermediate || target;
}

- (BOOL) needsInforming
{
    int repeat = [_settings.keepInforming get];
    if (repeat == 0)
        return NO;
    double notBefore = lastAnnouncement + repeat * 60 * 1000L;
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
    if (player != nil) {
        [player stop];
    }
}

- (void) announceOffRoute:(double)dist
{
    long ms = CACurrentMediaTime() * 1000;
    if (waitAnnouncedOffRoute == 0 || ms - lastAnnouncedOffRoute > waitAnnouncedOffRoute) {
        OACommandBuilder *p = [self getNewCommandPlayerToPlay];
        if (p != nil) {
//            notifyOnVoiceMessage();
            [[p offRoute:dist] play];
            announceBackOnRoute = true;
        }
        if (waitAnnouncedOffRoute == 0) {
            waitAnnouncedOffRoute = 60000;
        } else {
            waitAnnouncedOffRoute *= 2.5;
        }
        lastAnnouncedOffRoute = ms;
    }
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
    if (announceBackOnRoute) {
        OACommandBuilder *p = [self getNewCommandPlayerToPlay];
        if (p != nil) {
//            notifyOnVoiceMessage();
            [[p backOnRoute] play];
        }
        announceBackOnRoute = false;
    }
}

- (void) announceCurrentDirection:(CLLocation *)currentLocation
{
    @synchronized (_router) {
        if (currentStatus != STATUS_UTWP_TOLD) {
            [self updateStatus:currentLocation repeat:YES];
        } else if ([self playMakeUTwp]) {
            playGoAheadDist = 0;
        }
    }
}

- (BOOL) playMakeUTwp
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
//        notifyOnVoiceMessage();
        [[play makeUTwp] play];
        return true;
    }
    return false;
}

- (NSMutableDictionary *) getSpeakableStreetName:(std::shared_ptr<RouteSegmentResult>) currentSegment routeDirectionInfo:(OARouteDirectionInfo *)next includeDestination:(BOOL) includeDest
{
    // TODO check for announcement settings if we should anounce streeet names
    NSMutableDictionary *result = [NSMutableDictionary new];
    if (next == nil || ![_settings.speakStreetNames get:_settings.applicationMode.get]) {
        return result;
    }
    if (player != nil) {
        // Issue 2377: Play Dest here only if not already previously announced, to avoid repetition
        if (includeDest == YES) {
            result[@"toRef"] = [self getSpeakablePointName:next.ref];
            result[@"toStreetName"] = [self getSpeakablePointName:next.streetName];
            result[@"toDest"] = [self getSpeakablePointName:next.destinationName];
        } else {
            result[@"toRef"] = [self getSpeakablePointName:next.ref];
            result[@"toStreetName"] = [self getSpeakablePointName:next.streetName];
            result[@"toDest"] = @"";
        }
        if (currentSegment != nil) {
            // Issue 2377: Play Dest here only if not already previously announced, to avoid repetition
            if (includeDest == true) {
                const auto& obj = currentSegment->object;
                result[@"fromRef"] = [self getSpeakablePointName:[NSString stringWithUTF8String:obj->getRef(preferredLanguage, _settings.settingMapLanguageTranslit.get, currentSegment->isForwardDirection()).c_str()]];
                result[@"fromStreetName"] = [self getSpeakablePointName:[NSString stringWithUTF8String:obj->getName(preferredLanguage, _settings.settingMapLanguageTranslit.get).c_str()]];
                result[@"fromDest"] = [self getSpeakablePointName:[NSString stringWithUTF8String:obj->getDestinationName(preferredLanguage, _settings.settingMapLanguageTranslit.get, currentSegment->isForwardDirection()).c_str()]];
            } else {
                std::string val = std::string("en");
                const auto& obj = currentSegment->object;
                result[@"fromRef"] = [self getSpeakablePointName:[NSString stringWithUTF8String:obj->getRef(preferredLanguage, _settings.settingMapLanguageTranslit.get, currentSegment->isForwardDirection()).c_str()]];
                result[@"fromStreetName"] = [self getSpeakablePointName:[NSString stringWithUTF8String:obj->getName(preferredLanguage, _settings.settingMapLanguageTranslit.get).c_str()]];
                result[@"fromDest"] = @"";
            }
        }
        return result;
    } else {
        [result setObject:[self getSpeakablePointName:next.ref] forKey:@"toRef"];
        [result setObject:[self getSpeakablePointName:next.streetName] forKey:@"toStreetName"];
        return result;
    }
}

- (NSDictionary *) getSpeakableExitName:(OARouteDirectionInfo *)routeInfo exitInfo:(OAExitInfo *)exitInfo includeDest:(BOOL)includeDest
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
    if (![_settings.speakStreetNames get])
        return result;
    if (player != nil && player.supportsStructuredStreetNames)
    {
        result[@"toRef"] = [self getSpeakablePointName:exitInfo.ref];
        result[@"toStreetName"] = [self getSpeakablePointName:exitInfo.exitStreetName];
        result[@"toDest"] = includeDest ? [self getSpeakablePointName:routeInfo.ref] : @"";
    }
    else
    {
        result[@"toRef"] = [self getSpeakablePointName:exitInfo.ref];
        result[@"toStreetName"] = [self getSpeakablePointName:exitInfo.exitStreetName];
        result[@"toDest"] = @"";
    }
    return result;
}

- (BOOL) charIsDigit:(unichar)ch
{
    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
    return [numericSet characterIsMember:ch];
}

- (BOOL) charIsLetter:(unichar)ch
{
    NSCharacterSet *numericSet = [NSCharacterSet letterCharacterSet];
    return [numericSet characterIsMember:ch];
}

- (NSString *) getSpeakableExitRef:(NSString *)exit
{
    NSMutableString *sb = [NSMutableString new];
    if (exit != nil)
    {
        exit = [exit stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        exit = [exit stringByReplacingOccurrencesOfString:@":" withString:@" "];
        //    Add spaces between digits and letters for better pronunciation
        NSUInteger length = exit.length;
        for (int i = 0; i < length; i++)
        {
            if (i + 1 < length &&  [self charIsDigit:[exit characterAtIndex:i]] && [self charIsLetter:[exit characterAtIndex:i + 1]])
            {
                [sb appendFormat:@"%C", [exit characterAtIndex:i]];
                [sb appendString:@" "];
            }
            else
            {
                [sb appendFormat:@"%C", [exit characterAtIndex:i]];
            }
        }
    }
    return sb;
}

- (NSInteger) getIntRef:(NSString *)stringRef
{
    NSInteger intRef = [OAUtilities findFirstNumberEndIndex:stringRef];
    if (intRef > 0)
        intRef = [[stringRef substringToIndex:intRef] integerValue];
    
    return intRef;
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
    return @"";
}
- (int) calculateImminent:(float)dist loc:(CLLocation *)loc
{
    float speed = _DEFAULT_SPEED;
    if (loc && loc.speed >= 0)
        speed = loc.speed;
    
    if ([self isDistanceLess:speed dist:dist etalon:_TURN_NOW_DISTANCE])
        return 0;
    else if (dist <= _PREPARE_DISTANCE)
        return 1;
    else if (dist <= _PREPARE_LONG_DISTANCE)
        return 2;
    else
        return -1;
}

- (BOOL) isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon
{
    return [self isDistanceLess:currentSpeed dist:dist etalon:etalon defSpeed:_DEFAULT_SPEED];
}

- (BOOL) isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon defSpeed:(float)defSpeed
{
    if (currentSpeed <= 0)
        currentSpeed = _DEFAULT_SPEED;
    
    // Trigger close prompts earlier if delayed for BT SCO connection establishment
    // TODO: Java > Obj-C
    //if ((settings.AUDIO_STREAM_GUIDANCE.getModeValue(router.getAppMode()) == 0) && !OAAbstractPrologCommandBuilder.btScoStatus) {
    //    btScoDelayDistance = currentSpeed * (double) settings.BT_SCO_DELAY.get() / 1000;
    //}
    
    if ((dist - _voicePromptDelayDistance < etalon) || ((dist - _voicePromptDelayDistance) / currentSpeed) < (etalon / defSpeed))
        return YES;
    
    return NO;
}

- (void) gpsLocationLost
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
//        notifyOnVoiceMessage();
        [[play gpsLocationLost] play];
    }
}

- (void) gpsLocationRecover
{
    OACommandBuilder *play = [self getNewCommandPlayerToPlay];
    if (play != nil) {
        //        notifyOnVoiceMessage();
        [[play gpsLocationRecover] play];
    }
}

- (void) announceAlarm:(OAAlarmInfo *)info speed:(float)speed
{
    EOAAlarmInfoType type = info.type;
    NSString *typeName = [OAAlarmInfo getName:type];
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
                [[p attention:typeName] play];
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
                [[p attention:typeName] play];
            }
        }
    }
    else if (type == AIT_TUNNEL)
    {
        if ([_settings.speakTunnels get])
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p)
            {
                [self notifyOnVoiceMessage];
                [[p attention:typeName] play];
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
                [[p attention:typeName] play];
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
    
    double dist;
    [self makeSound];
    NSString *text = [self getText:location points:points dist:&dist];
    [[[p goAhead:dist streetName:[NSMutableArray new]] andArriveAtWayPoint:text] play];
}

- (void) approachFavorite:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;
    
    double dist;
    [self makeSound];
    NSString *text = [self getText:location points:points dist:&dist];
    [[[p goAhead:dist streetName:[NSMutableDictionary new]] andArriveAtFavorite:text] play];
}

- (void) approachPoi:(CLLocation *)location points:(NSArray<OALocationPointWrapper *> *)points
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    if (!p)
        return;

    double dist;
    [self makeSound];
    NSString *text = [self getText:location points:points dist:&dist];
    [[[p goAhead:dist streetName:[NSMutableDictionary new]] andArriveAtPoi:text] play];
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
