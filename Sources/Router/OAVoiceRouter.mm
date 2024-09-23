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
#import "OAApplicationMode.h"
#import "OAAnnounceTimeDistances.h"
#import "OARoutingHelper+cpp.h"
#import <AudioToolbox/AudioToolbox.h>

#include <routeSegmentResult.h>

@implementation OAVoiceRouter
{
    OARoutingHelper *_router;
    OAAppSettings *_settings;
    OAAnnounceTimeDistances *_atd;
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
        
        NSString *prefLang =  _settings.settingPrefMapLanguage.get == nil ? OALocalizedString(@"local_map_names") : _settings.settingPrefMapLanguage.get;
        preferredLanguage = std::string([prefLang UTF8String]);
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
    _atd = [[OAAnnounceTimeDistances alloc] initWithAppMode:appMode];
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
    float speed = [_atd getSpeed:currentLocation];

    OANextDirectionInfo *nextInfo = [_router getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] toSpeak:YES];
    const auto& currentSegment = [_router getCurrentSegmentResult];
    
    if (nextInfo == nil || nextInfo.directionInfo == nil)
        return;
    int dist = nextInfo.distanceTo;
    OARouteDirectionInfo *next = nextInfo.directionInfo;

    // If routing is changed update status to unknown
    if (next != nextRouteDirection)
    {
        nextRouteDirection = next;
        currentStatus = STATUS_UNKNOWN;
        suppressDest = NO;
        playedAndArriveAtTarget = NO;
        announceBackOnRoute = NO;
        if (playGoAheadDist != -1)
            playGoAheadDist = 0;
    }

    if (!repeat)
    {
        if (dist <= 0)
        {
            return;
        }
        else if ([self needsInforming])
        {
            [self playGoAhead:dist next:next streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
            return;
        }
        else if (currentStatus == STATUS_TOLD)
        {
            // nothing said possibly that's wrong case we should say before that
            // however it should be checked manually ?
            return;
        }
    }

    if (currentStatus == STATUS_UNKNOWN)
    {
        // Play "Continue for ..." if (1) after route calculation no other prompt is due, or (2) after a turn if next turn is more than PREPARE_LONG_DISTANCE away
        if ((playGoAheadDist == -1) || ![_atd isTurnStateActive:0 dist:dist turnType:kStateLongPrepareTurn])
        {
            // 10 seconds
            playGoAheadDist = dist - 10 * speed;
        }
    }

    OANextDirectionInfo *nextNextInfo = [_router getNextRouteDirectionInfoAfter:nextInfo to:[[OANextDirectionInfo alloc] init] toSpeak:YES];  //I think "true" is correct here, not "!repeat"
    // Note: getNextRouteDirectionInfoAfter(nextInfo, x, y).distanceTo is distance from nextInfo, not from current position!
    // STATUS_TURN = "Turn (now)"
    if ((repeat || [self statusNotPassed:STATUS_TURN]) && [_atd isTurnStateActive:speed dist:dist turnType:kStateTurnNow])
    {
        if (nextNextInfo != nil && ![_atd isTurnStateNotPassed:0 dist:nextNextInfo.distanceTo turnType:kStateTurnIn])
        {
            [self playMakeTurn:currentSegment routeDirectionInfo:next nextDirectionInfo:nextNextInfo];
        }
        else
        {
            [self playMakeTurn:currentSegment routeDirectionInfo:next nextDirectionInfo:nil];
        }
        if (!next.turnType->goAhead() && [self isTargetPoint:nextNextInfo] && nextNextInfo != nil)
        {   // !goAhead() avoids isolated "and arrive.." prompt, as goAhead() is not pronounced
            if (![_atd isTurnStateNotPassed:0 dist:nextNextInfo.distanceTo turnType:kStateTurnIn])
            {
                // Issue #2865: Ensure a distance associated with the destination arrival is always announced, either here, or in subsequent "Turn in" prompt
                // Distance fon non-straights already announced in "Turn (now)"'s nextnext  code above
                if (nextNextInfo != nil && nextNextInfo.directionInfo != nil && nextNextInfo.directionInfo.turnType->goAhead())
                {
                    [self playThen];
                    [self playGoAhead:nextNextInfo.distanceTo next:next streetName:[NSMutableDictionary new]];
                }
                [self playAndArriveAtDestination:nextNextInfo];
            }
            else if (![_atd isTurnStateNotPassed:0 dist:nextNextInfo.distanceTo / 1.2f turnType:kStateTurnIn])
            {
                // 1.2 is safety margin should the subsequent "Turn in" prompt not fit in amy more
                [self playThen];
                [self playGoAhead:nextNextInfo.distanceTo next:next streetName:[NSMutableDictionary new]];
                [self playAndArriveAtDestination:nextNextInfo];
            }
        }
        [self nextStatusAfter:STATUS_TURN];

        // STATUS_TURN_IN = "Turn in ..."
    }
    else if ((repeat || [self statusNotPassed:STATUS_TURN_IN]) && [_atd isTurnStateActive:speed dist:dist turnType:kStateTurnIn])
    {
        if (repeat || [_atd isTurnStateNotPassed:0 dist:dist turnType:kStateTurnIn])
        {
            if (nextNextInfo != nil && ([_atd isTurnStateActive:speed dist:nextNextInfo.distanceTo turnType:kStateTurnNow]
                || ![_atd isTurnStateNotPassed:speed dist:nextNextInfo.distanceTo turnType:kStateTurnIn]))
            {
                [self playMakeTurnIn:currentSegment info:next dist:[_atd calcDistanceWithoutDelay:speed dist:dist] nextInfo:nextNextInfo.directionInfo];
            }
            else
            {
                [self playMakeTurnIn:currentSegment info:next dist:[_atd calcDistanceWithoutDelay:speed dist:dist] nextInfo:nil];
            }
            [self playGoAndArriveAtDestination:repeat nextInfo:nextInfo currSegment:currentSegment];
        }
        [self nextStatusAfter:STATUS_TURN_IN];

        // STATUS_PREPARE = "Turn after ..."
    }
    else if ((repeat || [self statusNotPassed:STATUS_PREPARE]) && [_atd isTurnStateActive:0 dist:dist turnType:kStatePrepareTurn])
    {
        if (repeat || [_atd isTurnStateNotPassed:0 dist:dist turnType:kStatePrepareTurn])
        {
            if (!repeat && (next.turnType->keepLeft() || next.turnType->keepRight()))
            {
                // Do not play prepare for keep left/right
            }
            else
            {
                [self playPrepareTurn:currentSegment next:next dist: [_atd calcDistanceWithoutDelay:speed dist:dist]];
                [self playGoAndArriveAtDestination:repeat nextInfo:nextInfo currSegment:currentSegment];
            }
        }
        [self nextStatusAfter:STATUS_PREPARE];

    // STATUS_LONG_PREPARE =  also "Turn after ...", we skip this now, users said this is obsolete
    }
    else if ((repeat || [self statusNotPassed:STATUS_LONG_PREPARE]) && [_atd isTurnStateActive:0 dist:dist turnType:kStateLongPrepareTurn])
    {
        if (repeat || [_atd isTurnStateNotPassed:0 dist:dist turnType:kStateLongPrepareTurn])
        {
            [self playPrepareTurn:currentSegment next:next dist:dist];
            [self playGoAndArriveAtDestination:repeat nextInfo:nextInfo currSegment:currentSegment];
        }
        [self nextStatusAfter:STATUS_LONG_PREPARE];
//
        // STATUS_UNKNOWN = "Continue for ..." if (1) after route calculation no other prompt is due, or (2) after a turn if next turn is more than PREPARE_LONG_DISTANCE away
    }
    else if ([self statusNotPassed:STATUS_UNKNOWN])
    {
        // Strange how we get here but
        [self nextStatusAfter:STATUS_UNKNOWN];
    }
    else if (repeat || ([self statusNotPassed:STATUS_PREPARE] && dist < playGoAheadDist))
    {
        playGoAheadDist = 0;
        [self playGoAhead:dist next:next streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
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
            if (exitInfo != nil && exitInfo.ref.length > 0 && [_settings.speakExitNumberNames get])
            {
                NSString *stringRef = [self getSpeakableExitRef:exitInfo.ref];
                [play takeExit:tParam dist:dist exitString:stringRef exitInt:[self getIntRef:exitInfo.ref] streetName:[self getSpeakableExitName:next exitInfo:exitInfo]];
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
    if ([self isTargetPoint:nextInfo] && (!playedAndArriveAtTarget || repeat))
    {
        if (next.turnType->goAhead())
        {
            [self playGoAhead:nextInfo.distanceTo next:next streetName:[self getSpeakableStreetName:currentSegment routeDirectionInfo:next includeDestination:NO]];
            [self playAndArriveAtDestination:nextInfo];
            playedAndArriveAtTarget = true;
        }
        else if (nextInfo != nil && [_atd isTurnStateActive:0 dist:nextInfo.distanceTo / 2 turnType:kStateTurnIn])
        {
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

- (void) playGoAhead:(int)dist next:(OARouteDirectionInfo *)next streetName:(NSMutableDictionary *)streetName
{
    OACommandBuilder *p = [self getNewCommandPlayerToPlay];
    NSString *tParam = [self getTurnType:next.turnType];
    OAExitInfo *exitInfo = next.exitInfo;
    if (p)
    {
        //        notifyOnVoiceMessage();
        [[p goAhead:dist streetName:streetName] play];
        if (tParam && exitInfo && exitInfo.ref && exitInfo.ref.length > 0 && [_settings.speakExitNumberNames get])
        {
            NSString *stringRef = [self getSpeakableExitRef:exitInfo.ref];
            [[p then] takeExit:tParam exitString:stringRef exitInt:[self getIntRef:exitInfo.ref] streetName:[self getSpeakableExitName:next exitInfo:exitInfo]];
        }
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
            if (exitInfo != nil && exitInfo.ref.length > 0 && [_settings.speakExitNumberNames get])
            {
                NSString *stringRef = [self getSpeakableExitRef:exitInfo.ref];
                [play takeExit:tParam exitString:stringRef exitInt:[self getIntRef:exitInfo.ref] streetName:[self getSpeakableExitName:nextInfo exitInfo:exitInfo]];
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
    //STATUS_UNKNOWN=0 -> STATUS_LONG_PREPARE=1 -> STATUS_PREPARE=2 -> STATUS_TURN_IN=3 -> STATUS_TURN=4 -> STATUS_TOLD=5
    if (previousStatus != STATUS_TOLD)
    {
        currentStatus = previousStatus + 1;
        if (previousStatus == STATUS_TURN)
            waitAnnouncedOffRoute = 0;
    }
    else
    {
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
    if ([_settings.speakRouteDeviation get] && dist > [_atd getOffRouteDistance])
    {
        long ms = CACurrentMediaTime() * 1000;
        if (waitAnnouncedOffRoute == 0 || ms - lastAnnouncedOffRoute > waitAnnouncedOffRoute)
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p != nil)
            {
//                notifyOnVoiceMessage();
                [[p offRoute:dist] play];
                announceBackOnRoute = YES;
            }
            if (waitAnnouncedOffRoute == 0)
            {
                waitAnnouncedOffRoute = 60000;
            }
            else
            {
                waitAnnouncedOffRoute *= 2.5;
            }
            lastAnnouncedOffRoute = ms;
        } // Avoid offRoute/onRoute loop, #16571:
        else if (announceBackOnRoute && (dist < 0.3 * [_atd getOffRouteDistance]))
        {
            [self announceBackOnRoute];
        }
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
        else if ([_settings.speakRouteRecalculation get])
        {
            [[builder newRouteCalculated:[_router getLeftDistance] time:[_router getLeftTime]] play];
        }
        
    }
    else if (player == nil && (newRoute || [_settings.speakRouteRecalculation get]))
    {
        pendingCommand = [[OAVoiceCommandPending alloc] initWithType:((!newRoute) ? ROUTE_RECALCULATED : ROUTE_CALCULATED) voiceRouter:self];
    }
    if (newRoute)
    {
        playGoAheadDist = -1;
        waitAnnouncedOffRoute = 0;
    }
    currentStatus = STATUS_UNKNOWN;
    suppressDest = NO;
    nextRouteDirection = nil;
}

- (void) announceBackOnRoute
{
//    if (announceBackOnRoute) {
        if ([_settings.speakRouteDeviation get])
        {
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p != nil) {
                //            notifyOnVoiceMessage();
                [[p backOnRoute] play];
            }
            announceBackOnRoute = false;
            waitAnnouncedOffRoute = 0;
        }
//    }
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
    if (player != nil && [player supportsStructuredStreetNames]) {
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

- (NSDictionary *) getSpeakableExitName:(OARouteDirectionInfo *)routeInfo exitInfo:(OAExitInfo *)exitInfo
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
    if (!exitInfo || ![_settings.speakStreetNames get])
        return result;
    
    result[@"toRef"] = [self getNonNilString:[self getSpeakablePointName:exitInfo.ref]];
    NSString *destination = [self getSpeakablePointName:[self cutLongDestination:routeInfo.destinationName]];
    result[@"toDest"] = [self getNonNilString:destination];
    result[@"toStreetName"] = @"";
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

- (NSString *) getNonNilString:(NSString *)speakablePointName
{
    return speakablePointName ?: @"";
}

- (NSString *) cutLongDestination:(NSString *)destination
{
    if (!destination)
        return nil;
    
    NSArray *words = [destination componentsSeparatedByString:@";"];
    if ([words count] > 3)
        return [NSString stringWithFormat:@"%@;%@;%@", words[0], words[1], words[2]];
    
    return destination;
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
    return [_atd getImminentTurnStatus:dist loc:loc];
}

- (void) gpsLocationLost
{
    if ([_settings.speakGpsSignalStatus get])
    {
        OACommandBuilder *play = [self getNewCommandPlayerToPlay];
        if (play != nil)
        {
            //        notifyOnVoiceMessage();
            [[play gpsLocationLost] play];
        }
    }
}

- (void) gpsLocationRecover
{
    if ([_settings.speakGpsSignalStatus get])
    {
        OACommandBuilder *play = [self getNewCommandPlayerToPlay];
        if (play != nil)
        {
            //        notifyOnVoiceMessage();
            [[play gpsLocationRecover] play];
        }
    }
}

- (void) announceAlarm:(OAAlarmInfo *)info speed:(float)speed
{
    EOAAlarmInfoType type = info.type;
    if (type == AIT_SPEED_LIMIT)
    {
        [self announceSpeedAlarm:info.intValue speed:speed];
    }
    else
    {
        BOOL speakTrafficWarnings = [_settings.speakTrafficWarnings get];
        BOOL speakTunnels = type == AIT_TUNNEL && [_settings.speakTunnels get];
        BOOL speakPedestrian = type == AIT_PEDESTRIAN && [_settings.speakPedestrian get];
        BOOL speakSpeedCamera = type == AIT_SPEED_CAMERA && [_settings.speakCameras get];
        BOOL speakPrefType = type == AIT_TUNNEL || type == AIT_PEDESTRIAN || type == AIT_SPEED_CAMERA;

        if (speakSpeedCamera || speakPedestrian || speakTunnels || (speakTrafficWarnings && !speakPrefType))
        {
            NSString *typeName = [OAAlarmInfo getName:type];
            OACommandBuilder *p = [self getNewCommandPlayerToPlay];
            if (p)
                [[p attention:typeName] play];

            // See Issue 2377: Announce destination again - after some motorway tolls roads split shortly after the toll
            if (type == AIT_TOLL_BOOTH)
                suppressDest = false;
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
    
    // Taken unaltered from https://freesound.org/people/Corsica_S/sounds/91926/ under license https://creativecommons.org/licenses/by/3.0/ :
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

- (OAAnnounceTimeDistances *)getAnnounceTimeDistances
{
    return _atd;
}

- (OARouteDirectionInfo *)getNextRouteDirection
{
    return nextRouteDirection;
}

@end
