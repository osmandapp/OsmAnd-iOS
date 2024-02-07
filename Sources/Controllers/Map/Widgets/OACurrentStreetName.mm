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

@implementation OACurrentStreetName

+ (NSString *) getRouteSegmentStreetName:(std::shared_ptr<RouteSegmentResult> &)rs includeRef:(BOOL)includeRef
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    if (!lang)
        lang = [OAUtilities currentLang];
    
    auto locale = std::string([lang UTF8String]);
    BOOL transliterate = settings.settingMapLanguageTranslit.get;
    NSString *nm = [NSString stringWithUTF8String:rs->object->getName(locale, transliterate).c_str()];;
    NSString *rf = [NSString stringWithUTF8String:rs->object->getRef(locale, transliterate, rs->isForwardDirection()).c_str()];
    NSString *dn = [NSString stringWithUTF8String:rs->object->getDestinationName(locale, transliterate, rs->isForwardDirection()).c_str()];
    return [OARoutingHelperUtils formatStreetName:nm ref:includeRef ? rf : nil destination:dn towards:@"»"];
}

+ (OACurrentStreetName *) getCurrentName:(OANextDirectionInfo *)n
{
    OARoutingHelper *routingHelper = OARoutingHelper.sharedInstance;
    OAVoiceRouter *voiceRouter = routingHelper.getVoiceRouter;
    OACurrentStreetName *streetName = [[OACurrentStreetName alloc] init];
    CLLocation *l = routingHelper.getLastFixedLocation;
    OAAnnounceTimeDistances *adt = [[routingHelper getVoiceRouter] getAnnounceTimeDistances];
    BOOL isSet = false;
    float speed = 0;
    if (l && l.speed >=0)
        speed = l.speed;
    // 1. turn is imminent
    if (n.distanceTo > 0  && n.directionInfo && !n.directionInfo.turnType->isSkipToSpeak() &&
        [adt isTurnStateActive:[adt getSpeed:l] dist:n.distanceTo * 1.3 turnType:kStatePrepareTurn])
    {
        NSString *nm = n.directionInfo.streetName;
        NSString *rf = n.directionInfo.ref;
        NSString *dn = n.directionInfo.destinationName;
        isSet = !(nm.length == 0 && rf.length == 0 && dn.length == 0);
        std::shared_ptr<RouteDataObject> rdo = n.directionInfo.routeDataObject;
        streetName.shields = [RoadShield create:rdo];
        streetName.text = [OARoutingHelperUtils formatStreetName:nm ref:rf destination:dn towards:@"»" shields:streetName.shields];
        streetName.turnType = n.directionInfo.turnType;
        if (!streetName.turnType)
            streetName.turnType = TurnType::ptrValueOf(TurnType::C, false);
        if (n.directionInfo.exitInfo != nil)
        {
            // don't display name of exit street name
            streetName.exitRef = n.directionInfo.exitInfo.ref;
            if (!isSet && n.directionInfo.destinationName.length > 0)
            {
                streetName.text = n.directionInfo.destinationName;
                isSet = YES;
            }
        }
    }
    // 2. display current road street name
    if (!isSet)
    {
        auto rs = routingHelper.getCurrentSegmentResult;
        if (rs)
        {
            streetName.text = [self.class getRouteSegmentStreetName:rs includeRef:NO];
            if (streetName.text.length == 0)
            {
                streetName.text = [self.class getRouteSegmentStreetName:rs includeRef:YES];
                isSet = streetName.text.length > 0;
            }
            else
            {
                isSet = YES;
            }
            streetName.showMarker = YES;
            streetName.shields = [RoadShield create:rs->object];
        }
    }
    // 3. display next road street name if this one empty
    if (!isSet)
    {
        auto rs = routingHelper.getNextStreetSegmentResult;
        if (rs)
        {
            streetName.text = [self.class getRouteSegmentStreetName:rs includeRef:NO];
            streetName.turnType = TurnType::ptrValueOf(TurnType::C, false);
            streetName.shields = [RoadShield create:rs->object];
        }
    }
    if (streetName.turnType)
        streetName.showMarker = YES;
    
    return streetName;
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

@end

@implementation RoadShield

- (instancetype)initWithRDO:(std::shared_ptr<RouteDataObject>)rdo tag:(NSString *)tag value:(NSString *)value {
    self = [super init];
    if (self) {
        _rdo = rdo;
        _tag = [tag copy];
        _value = [value copy];
    }
    return self;
}

+ (NSArray<RoadShield *> *)create:(std::shared_ptr<RouteDataObject>)rdo {
    NSMutableArray<RoadShield *> *shields = [NSMutableArray array];
    NSMutableString *additional = [NSMutableString string];
    
    if (rdo && !rdo->namesIds.empty()) {
        for (NSInteger i = 0; i < rdo->namesIds.size(); i++) {
            NSString *tag = [NSString stringWithUTF8String:rdo->region->quickGetEncodingRule(rdo->namesIds[i].first).getTag().c_str()];

            NSString *val = [NSString stringWithUTF8String:rdo->names[rdo->namesIds[i].first].c_str()];
            if (![tag hasSuffix:@"_ref"] && ![tag hasPrefix:@"route_road"])
            {
                [additional appendFormat:@"%@=%@;", tag, val];
            } else if ([tag hasPrefix:@"route_road"] && [tag hasSuffix:@"_ref"]) {
                RoadShield *shield = [[RoadShield alloc] initWithRDO:rdo tag:tag value:val];
                [shields addObject:shield];
            }
        }
        if (shields.count > 0) {
            for (RoadShield *shield in shields) {
                shield.additional = additional;
            }
        }
    }
    
    return [shields copy];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
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
