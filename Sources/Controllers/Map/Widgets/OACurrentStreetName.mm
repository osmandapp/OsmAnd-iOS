//
//  OACurrentStreetName.m
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACurrentStreetName.h"
#import "OARouteCalculationResult.h"
#import "OAAppSettings.h"
#import "OARoutingHelperUtils.h"
#import "OARoutingHelper.h"
#import "OARoutingHelper+cpp.h"
#import "OARouteDirectionInfo.h"
#import "OAVoiceRouter.h"
#import "OAAnnounceTimeDistances.h"

#include "routeSegmentResult.h"
#include <OsmAndCore/Utilities.h>

@implementation OACurrentStreetName

- (instancetype)initWithStreetName:(OANextDirectionInfo *)info
{
    self = [super init];
    if (self)
    {
        [self setupNextTurnStreetName:info];
    }
    return self;
}

- (instancetype)initWithStreetName:(OANextDirectionInfo *)info useDestination:(BOOL)useDestination
{
    self = [super init];
    if (self)
    {
        _useDestination = useDestination;
        [self setupNextTurnStreetName:info];
    }
    return self;
}

- (instancetype)initWithStreetName:(OARoutingHelper *)routingHelper info:(OANextDirectionInfo *)info showNextTurn:(BOOL)showNextTurn
{
    self = [super init];
    if (self)
    {
        [self setupCurrentName:routingHelper info:info showNextTurn:showNextTurn];
    }
    return self;
}

- (BOOL)isTurnIsImminent:(OARoutingHelper *)routingHelper info:(OANextDirectionInfo *)info
{
    if (info.distanceTo > 0)
    {
        OAAnnounceTimeDistances *timeDistances = [[routingHelper getVoiceRouter] getAnnounceTimeDistances];
        CLLocation *location = [routingHelper getLastFixedLocation];
        float speed = [timeDistances getSpeed:location];
        double increasedDistance = info.distanceTo * 1.3;
        return [timeDistances isTurnStateActive:speed dist:increasedDistance turnType:kStatePrepareTurn];
    }
    return NO;
}

- (BOOL)setupNextTurnStreetName:(OANextDirectionInfo *)info
{
    BOOL isSet = NO;
    if (info.directionInfo && !info.directionInfo.turnType->isSkipToSpeak()) {
        NSString *name = info.directionInfo.streetName;
        NSString *ref = info.directionInfo.ref;
        NSString *destinationName = info.directionInfo.destinationName;
        isSet = !(name.length == 0 && ref.length == 0 && destinationName.length == 0);

        const auto& dataObject = info.directionInfo.routeDataObject;
        if (_useDestination)
            _shields = [RoadShield createDestination:info.directionInfo.routeDataObject destRef:info.directionInfo.destinationRef];
        else
            _shields = [RoadShield createShields:info.directionInfo.routeDataObject];
        
        if (_shields.count == 0)
            destinationName = [info.directionInfo getDestinationRefAndName];
        
        _text = [OARoutingHelperUtils formatStreetName:name ref:ref destination:destinationName towards:@"" shields:_shields];
        _turnType = info.directionInfo.turnType;
        if (!_turnType)
            _turnType = TurnType::ptrValueOf(TurnType::C, false);
        
        OAExitInfo *exitInfo = info.directionInfo.exitInfo;
        if (exitInfo)
        {
            // don't display name of exit street name
            _exitRef = exitInfo.ref;
            if (!isSet && info.directionInfo.destinationName.length > 0)
            {
                _text = info.directionInfo.destinationName;
                isSet = YES;
            }
        }
    }
    return isSet;
}

- (void)setupCurrentName:(OARoutingHelper *)routingHelper info:(OANextDirectionInfo *)info showNextTurn:(BOOL)showNextTurn
{
    BOOL isSet = NO;
    // 1. display next turn and turn is imminent
    if (showNextTurn && [self isTurnIsImminent:routingHelper info:info])
    {
        _useDestination = YES;
        isSet = [self setupNextTurnStreetName:info];
    }
    // 2. display current road street name
    if (!isSet)
    {
        _useDestination = NO;
        isSet = [self setupCurrentRoadStreetName:routingHelper];
    }
    // 3. display next road street name if this one empty
    if (!isSet)
        [self setupNextRoadStreetName:routingHelper];
    
    if (!showNextTurn)
        _turnType = nullptr;
    if (!_turnType)
        _showMarker = YES;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object || ![object isKindOfClass:self.class])
        return NO;
    
    OACurrentStreetName *otherName = (OACurrentStreetName *) object;
    if (![self.text isEqualToString:otherName.text])
        return NO;
    if (self.turnType && otherName.turnType && self.turnType->getValue() != otherName.turnType->getValue())
        return NO;
    if (self.showMarker != otherName.showMarker)
        return NO;
    if (![self.shields isEqual: otherName.shields])
        return NO;
    if (self.exitRef && otherName.exitRef && ![self.exitRef isEqualToString:otherName.exitRef])
        return NO;
    
    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = [self.text hash];
    result = 31 * result + (self.turnType ? self.turnType->getValue() : 0.);
    result = 31 * result + (self.showMarker ? 1 : 0);
    result = 31 * result + [self.shields hash];
    result = 31 * result + [self.exitRef hash];
    return result;
}

- (BOOL)setupCurrentRoadStreetName:(OARoutingHelper *)routingHelper
{
    const auto& rs = [routingHelper getCurrentSegmentResult];
    if (rs)
    {
        _text = [self.class getRouteSegmentStreetName:routingHelper rs:rs includeRef:NO];
        _showMarker = YES;
        _shields = [RoadShield createShields:rs->object];
        if (_text.length == 0 && _shields.count == 0)
            _text = [self.class getRouteSegmentStreetName:routingHelper rs:rs includeRef:YES];
        
        return _text.length > 0 || _shields.count > 0;
    }
    return NO;
}

- (void)setupNextRoadStreetName:(OARoutingHelper *)routingHelper
{
    const auto& rs = [routingHelper getNextStreetSegmentResult];
    if (rs)
    {
        _text = [self.class getRouteSegmentStreetName:routingHelper rs:rs includeRef:NO];
        _turnType = TurnType::ptrValueOf(TurnType::C, false);
        _shields = [RoadShield createShields:rs->object];
    }
}

+ (NSString *)getRouteSegmentStreetName:(OARoutingHelper *)routingHelper rs:(const std::shared_ptr<RouteSegmentResult> &)rs includeRef:(BOOL)includeRef
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    if (!lang)
        lang = [OAUtilities currentLang];
    
    auto locale = std::string([lang UTF8String]);
    BOOL transliterate = settings.settingMapLanguageTranslit.get;
    NSString *nm = [NSString stringWithUTF8String:rs->object->getName(locale, transliterate).c_str()];
    NSString *rf = [NSString stringWithUTF8String:rs->object->getRef(locale, transliterate, rs->isForwardDirection()).c_str()];
    NSString *dn = [NSString stringWithUTF8String:rs->object->getDestinationName(locale, transliterate, rs->isForwardDirection()).c_str()];
    return [OARoutingHelperUtils formatStreetName:nm ref:includeRef ? rf : nil destination:dn towards:@"»"];
}

@end

@implementation RoadShield

- (instancetype)initWithRDO:(std::shared_ptr<RouteDataObject>)rdo tag:(NSString *)tag value:(NSString *)value
{
    self = [super init];
    if (self)
    {
        _rdo = rdo;
        _tag = [tag copy];
        _value = [value copy];
    }
    return self;
}

+ (NSArray<RoadShield *> *)createShields:(std::shared_ptr<RouteDataObject>)rdo
{
    NSMutableArray<RoadShield *> *shields = [NSMutableArray array];
    NSMutableString *additional = [NSMutableString string];
    
    if (rdo && !rdo->namesIds.empty()) {
        for (NSInteger i = 0; i < rdo->namesIds.size(); i++) {
            NSString *tag = [NSString stringWithUTF8String:rdo->region->quickGetEncodingRule(rdo->namesIds[i].first).getTag().c_str()];
            NSString *val = [NSString stringWithUTF8String:rdo->names[rdo->namesIds[i].first].c_str()];
            if (![tag hasSuffix:@"_ref"] && ![tag hasPrefix:@"route_road"])
            {
                [additional appendFormat:@"%@=%@;", tag, val];
            }
            else if ([tag hasPrefix:@"route_road"] && [tag hasSuffix:@"_ref"])
            {
                RoadShield *shield = [[RoadShield alloc] initWithRDO:rdo tag:tag value:val];
                [shields addObject:shield];
            }
        }
        for (RoadShield *shield in shields)
            shield.additional = additional;
    }
    
    return [shields copy];
}

+ (NSArray<RoadShield *> *)createDestination:(std::shared_ptr<RouteDataObject>)rdo destRef:(NSString *)destRef
{
    NSMutableArray<RoadShield *> * shields = [[self createShields:rdo] mutableCopy];
    if (rdo && destRef.length > 0 && shields.count > 0)
    {
        QString refs = OsmAnd::Utilities::splitAndClearRepeats(QString::fromNSString(destRef), ";");
        NSArray<NSString *> *split = [refs.toNSString() componentsSeparatedByString:@";"];
        
        NSMutableDictionary<NSString *, RoadShield *> *map = [NSMutableDictionary dictionary];
        NSString *tag = nil;
        NSString *additional = [NSMutableString string];

        for (RoadShield *s in shields)
        {
            map[s.value] = s;
            if ([split containsObject:s.value])
                tag = s.tag;

            additional = s.additional;
        }

        [shields removeAllObjects];
        if (tag == nil)
            return shields;
        
        for (NSString *s in split)
        {
            RoadShield *shield = map[s];
            if (shield == nil)
            {
                shield = [[RoadShield alloc] initWithRDO:rdo tag:tag value:s];
                shield.additional = additional;
            }
            [shields addObject:shield];
            [map removeObjectForKey:s];
        }
        [shields addObjectsFromArray:map.allValues];
    }
    return shields;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:self.class])
        return NO;
    
    RoadShield *shield = (RoadShield *)object;
    
    return [self.tag isEqualToString:shield.tag] &&
           [self.value isEqualToString:shield.value];
}

- (NSUInteger) hash
{
    NSUInteger result = [self.tag hash];
    result = 31 * result + [self.value hash];
    result = 31 * result + (self.rdo ? self.rdo->id : 0);
    return result;
}

@end
