//
//  OAAnnounceTimeDistances.m
//  OsmAnd
//
//  Created by Skalii on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAAnnounceTimeDistances.h"
#import "OALocationServices.h"
#import "OALocationSimulation.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "Localization.h"

// Avoids false negatives: Pre-pone close announcements by this distance to allow for the possible over-estimation of the 'true' lead distance due to positioning error.
// A smaller value will increase the timing precision, but at the risk of missing prompts which do not meet the precision limit.
// We can research if a flexible value like min(12, x * gps-hdop) has advantages over a constant (x could be 2 or so).
#define kPositioningTolerance 12

@implementation OAAnnounceTimeDistances
{
    // Default speed to have comfortable announcements (m/s)
    // initial value is updated from default speed settings anyway
    float _defaultSpeed;
    double _voicePromptDelayTimeSec;

    float _arrivalDistance;
    float _offRouteDistance;

    float _turnNowSpeed;
    int _prepareLongDistance;
    int _prepareLongDistanceEnd;
    int _prepareDistance;
    int _prepareDistanceEnd;
    int _turnInDistance;
    int _turnInDistanceEnd;
    int _turnNowDistance;
    int _longPntAnnounceRadius;
    int _shortPntAnnounceRadius;
    int _longAlarmAnnounceRadius;
    int _shortAlarmAnnounceRadius;
    OALocationServices *_locationProvider;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _defaultSpeed = 10;
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _locationProvider = [OsmAndApp instance].locationServices;
        if ([appMode isDerivedRoutingFrom:OAApplicationMode.CAR])
        {
            // keep it as minimum 30 km/h for voice announcement
            _defaultSpeed = (float) MAX(8, [appMode getDefaultSpeed]);
        }
        else
        {
            // minimal is 1 meter for turn now
            _defaultSpeed = (float) MAX(.3, [appMode getDefaultSpeed]);
        }

        // 300 s: car 3750 m (113 s @ 120 km/h)
        _prepareLongDistance = _defaultSpeed * 300;
        // 250 s: car 3125 m (94 s @ 120 km/h)
        _prepareLongDistanceEnd = _defaultSpeed * 250;
        if (_defaultSpeed < 30)
        {
            // Play only for high speed vehicle with speed > 110 km/h
            // [issue 1411] - used only for goAhead prompt
            _prepareLongDistanceEnd = _prepareLongDistance * 2;
        }

        // 115 s: car 1438 m (45 s @ 120 km/h), bicycle 319 m (46 s @ 25 km/h), pedestrian 128 m
        _prepareDistance = _defaultSpeed * 115;
        // 90  s: car 1136 m, bicycle 250 m (36 s @ 25 km/h)
        _prepareDistanceEnd = _defaultSpeed * 90;

        // 22 s: car 275 m, bicycle 61 m, pedestrian 24 m
        _turnInDistance = _defaultSpeed * 22;
        // 15 s: car 189 m, bicycle 42 m, pedestrian 17 m
        _turnInDistanceEnd = _defaultSpeed * 15;

        // Do not play prepare: for pedestrian and slow transport
        // same check as speed < 150/(90-22) m/s = 2.2 m/s = 8 km/h
        // if (_defaultSpeed < 2.3) {
        if (_prepareDistanceEnd - _turnInDistance < 150)
            _prepareDistanceEnd = _prepareDistance * 2;

        [self setArrivalDistances:[settings.arrivalDistanceFactor get:appMode]];

        // Trigger close prompts earlier to allow BT SCO link being established, or when VOICE_PROMPT_DELAY is set >0 for the other stream types
//        int ams = settings.AUDIO_MANAGER_STREAM.getModeValue(appMode);
//        if ((ams == 0 && !CommandPlayer.isBluetoothScoRunning()) || ams > 0) {
//            if (settings.VOICE_PROMPT_DELAY[ams] != null) {
//                voicePromptDelayTimeSec = (double) settings.VOICE_PROMPT_DELAY[ams].get() / 1000;
//            }
//        }
    }
    return self;
}

- (void)setArrivalDistances:(float)arrivalDistanceFactor
{
    arrivalDistanceFactor = (float) MAX(arrivalDistanceFactor, .1);
    // Turn now: 3.5 s normal speed, 7 s for half speed (default)
    // float TURN_NOW_TIME = 7;
    // ** #8749 to keep 1m / 1 sec precision (kPositioningTolerance = 12 m)
    // car 50 km/h - 7 s, bicycle 10 km/h - 3 s, pedestrian 4 km/h - 2 s, 1 km/h - 1 s
    float turnNowTime = (float) MIN(sqrt(_defaultSpeed * 3.6), 8);

    // 3.6 s: car 45 m, bicycle 10 m -> 12 m, pedestrian 4 m -> 12 m (capped by kPositioningTolerance)
    _turnNowDistance = MAX(kPositioningTolerance, _defaultSpeed * 3.6) * arrivalDistanceFactor;
    _turnNowSpeed = _turnNowDistance / turnNowTime;

    // 5 s: car 63 m, bicycle 14 m, pedestrian 6 m -> 12 m (capped by kPositioningTolerance)
    _arrivalDistance = MAX(kPositioningTolerance, _defaultSpeed * 5.) * arrivalDistanceFactor;

    // 20 s: car 250 m, bicycle 56 m, pedestrian 22 m
    _offRouteDistance = _defaultSpeed * 20 * arrivalDistanceFactor; // 20 seconds

    // assume for backward compatibility speed - 10 m/s
    _shortAlarmAnnounceRadius = 7 * _defaultSpeed * arrivalDistanceFactor; // 70 m
    _longAlarmAnnounceRadius = 12 * _defaultSpeed * arrivalDistanceFactor; // 120 m
    _shortPntAnnounceRadius = 15 * _defaultSpeed * arrivalDistanceFactor; // 150 m
    _longPntAnnounceRadius = 60 * _defaultSpeed * arrivalDistanceFactor; // 600 m
}

- (int)getImminentTurnStatus:(float)dist loc:(CLLocation *)loc
{
    float speed = [self getSpeed:loc];
    if ([self isTurnStateActive:speed dist:dist turnType:kStateTurnNow])
    {
        return 0;
    }
    else if ([self isTurnStateActive:speed dist:dist turnType:kStatePrepareTurn])
    {
        // STATE_TURN_IN included
        return 1;
    }
    else
    {
        return -1;
    }
}

- (BOOL)isTurnStateActive:(float)currentSpeed dist:(double)dist turnType:(int)turnType
{
    switch (turnType)
    {
        case kStateTurnNow:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_turnNowDistance defSpeed:_turnNowSpeed];
        case kStateTurnIn:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_turnInDistance];
        case kStatePrepareTurn:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_prepareDistance];
        case kStateLongPrepareTurn:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_prepareLongDistance];
        case kStateShortAlarmAnnounce:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_shortAlarmAnnounceRadius];
        case kStateLongAlarmAnnounce:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_longAlarmAnnounceRadius];
        case kStateShortPntApproach:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_shortPntAnnounceRadius];
        case kStateLongPntApproach:
            return [self isDistanceLess:currentSpeed dist:dist etalon:_longPntAnnounceRadius];
    }
    return NO;
}

- (BOOL)isTurnStateNotPassed:(float)currentSpeed dist:(double)dist turnType:(int)turnType
{
    switch (turnType)
    {
        case kStateTurnIn:
            return ![self isDistanceLess:currentSpeed dist:dist etalon:_turnInDistanceEnd];
        case kStatePrepareTurn:
            return ![self isDistanceLess:currentSpeed dist:dist etalon:_prepareDistanceEnd];
        case kStateLongPrepareTurn:
            return ![self isDistanceLess:currentSpeed dist:dist etalon:_prepareLongDistance];
        case kStateLongPntApproach:
            return ![self isDistanceLess:currentSpeed dist:dist etalon:_longPntAnnounceRadius * .5];
        case kStateLongAlarmAnnounce:
            return ![self isDistanceLess:currentSpeed dist:dist etalon:_longAlarmAnnounceRadius * .5];
    }
    return YES;
}

- (BOOL)isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon
{
    return [self isDistanceLess:currentSpeed dist:dist etalon:etalon defSpeed:_defaultSpeed];
}

- (BOOL)isDistanceLess:(float)currentSpeed dist:(double)dist etalon:(double)etalon defSpeed:(float)defSpeed
{
    // Check triggers:
    // (1) distance < etalon?
    if (dist - _voicePromptDelayTimeSec * currentSpeed <= etalon)
        return YES;

    // (2) time_with_current_speed < etalon_time_with_default_speed?
    // check only if speed > 0
    return currentSpeed > 0 && (dist / currentSpeed - _voicePromptDelayTimeSec) <= etalon / defSpeed;
}

- (float)getSpeed:(CLLocation *)loc
{
    BOOL simulation = NO;
    if (_locationProvider)
        simulation = [_locationProvider.locationSimulation isRouteAnimating];
    float speed = _defaultSpeed;
    if (loc && loc.speed > 0 && !simulation)
        speed = (float) MAX(loc.speed, speed);
    return speed;
}

- (float)getOffRouteDistance
{
    return _offRouteDistance;
}

- (float)getArrivalDistance
{
    return _arrivalDistance;
}

- (int)calcDistanceWithoutDelay:(float)speed dist:(int)dist
{
    return dist - _voicePromptDelayTimeSec * speed;
}

- (void)appendTurnDesc:(NSMutableAttributedString *)builder name:(NSString *)name dist:(int)dist meter:(NSString *)meter second:(NSString *)second
{
    [self appendTurnDesc:builder name:name dist:dist speed:_defaultSpeed meter:meter second:second colorize:YES];
}

- (void)appendTurnDesc:(NSMutableAttributedString *)builder name:(NSString *)name dist:(int)dist speed:(float)speed meter:(NSString *)meter second:(NSString *)second colorize:(BOOL)colorize
{
    int minDist = (dist / 5) * 5;
    int time = (int) (dist / speed);
    if (time > 15)
    {
        // round to 5
        time = (time / 5) * 5;
    }
    name = [name stringByAppendingString:@":"];
    NSString *distStr = [NSString stringWithFormat:@"\n%@ %d - %d %@", name, minDist, minDist + 5, meter];
    NSString *timeStr = [NSString stringWithFormat:@"%d %@.", time, second];
    NSString *str = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_comma"), distStr, timeStr];
    [builder addString:str fontWeight:UIFontWeightRegular size:colorize ? 15. : 17.];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = colorize ? 18 : 22.;
    paragraphStyle.lineSpacing = colorize ? 19. : 25;
    [builder addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:[builder.string rangeOfString:str]];
    [builder addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorPrimary] range:[builder.string rangeOfString:str]];
    [builder addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorPrimary] range:[builder.string rangeOfString:name options:NSBackwardsSearch]];

    if (colorize)
        [builder addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorSecondary] range:[builder.string rangeOfString:name options:NSBackwardsSearch]];
}

- (NSAttributedString *)getIntervalsDescription
{
    NSString *meter = OALocalizedString(@"m");
    NSString *second = OALocalizedString(@"shared_string_sec");
    NSString *turn = OALocalizedString(@"shared_string_turn");
    NSString *arrive = OALocalizedString(@"announcement_time_arrive");
    NSString *offRoute = OALocalizedString(@"announcement_time_off_route");
    NSString *traffic = [@"\n" stringByAppendingString:OALocalizedString(@"speak_traffic_warnings")];
    NSString *point = [NSString stringWithFormat:@"\n%@ / %@ / %@", OALocalizedString(@"shared_string_waypoint"), OALocalizedString(@"favorite"), OALocalizedString(@"poi")];

    NSString *prepare = [@"   • " stringByAppendingString:OALocalizedString(@"announcement_time_prepare")];
    NSString *longPrepare = [@"   • " stringByAppendingString:OALocalizedString(@"announcement_time_prepare_long")];
    NSString *approach = [@"   • " stringByAppendingString:OALocalizedString(@"announcement_time_approach")];
    NSString *passing = [@"   • " stringByAppendingString:OALocalizedString(@"announcement_time_passing")];

    NSMutableAttributedString *builder = [[NSMutableAttributedString alloc] init];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 22.;
    paragraphStyle.lineSpacing = 25.;

    // Turn
    [builder addString:turn fontWeight:UIFontWeightRegular size:17.];
    [builder addAttribute:NSForegroundColorAttributeName 
                    value:[UIColor colorNamed:ACColorNameTextColorPrimary]
                    range:[builder.string rangeOfString:turn]];
    [builder addAttribute:NSParagraphStyleAttributeName
                    value:paragraphStyle
                    range:[builder.string rangeOfString:turn]];
    if (_prepareDistanceEnd <= _prepareDistance)
        [self appendTurnDesc:builder name:prepare dist:_prepareDistance meter:meter second:second];
    if (_prepareLongDistanceEnd <= _prepareLongDistance)
        [self appendTurnDesc:builder name:longPrepare dist:_prepareLongDistance meter:meter second:second];
    [self appendTurnDesc:builder name:approach dist:_turnInDistance meter:meter second:second];
    [self appendTurnDesc:builder name:passing dist:_turnNowDistance speed:_turnNowSpeed meter:meter second:second colorize:YES];

    // Arrive at destination
    [self appendTurnDesc:builder name:arrive dist:(int) [self getArrivalDistance] speed:_defaultSpeed meter:meter second:second colorize:NO];

    // Off-route
    if ([self getOffRouteDistance] > 0)
        [self appendTurnDesc:builder name:offRoute dist:(int) [self getOffRouteDistance] speed:_defaultSpeed meter:meter second:second colorize:NO];

    // Traffic warnings
    [builder addString:traffic fontWeight:UIFontWeightRegular size:17.];
    [builder addAttribute:NSForegroundColorAttributeName 
                    value:[UIColor colorNamed:ACColorNameTextColorPrimary]
                    range:[builder.string rangeOfString:traffic]];
    [builder addAttribute:NSParagraphStyleAttributeName
                    value:paragraphStyle
                    range:[builder.string rangeOfString:traffic]];
    [self appendTurnDesc:builder name:approach dist:_longAlarmAnnounceRadius meter:meter second:second];
    [self appendTurnDesc:builder name:passing dist:_shortAlarmAnnounceRadius meter:meter second:second];

    // Waypoint / Favorite / POI
    [builder addString:point fontWeight:UIFontWeightRegular size:17.];
    [builder addAttribute:NSForegroundColorAttributeName 
                    value:[UIColor colorNamed:ACColorNameTextColorPrimary]
                    range:[builder.string rangeOfString:point]];
    [builder addAttribute:NSParagraphStyleAttributeName
                    value:paragraphStyle
                    range:[builder.string rangeOfString:point]];
    [self appendTurnDesc:builder name:approach dist:_longPntAnnounceRadius meter:meter second:second];
    [self appendTurnDesc:builder name:passing dist:_shortPntAnnounceRadius meter:meter second:second];

    return builder;
}

@end
