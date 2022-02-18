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
#import "OARouteDirectionInfo.h"
#import "OAVoiceRouter.h"

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
//    AnnounceTimeDistances adt = routingHelper.getVoiceRouter().getAnnounceTimeDistances();
    BOOL isSet = false;
    float speed = 0;
    if (l && l.speed >=0)
        speed = l.speed;
    // 1. turn is imminent
    if (n.distanceTo > 0  && n.directionInfo && !n.directionInfo.turnType->isSkipToSpeak() &&
        [voiceRouter isDistanceLess:speed dist:n.distanceTo etalon:voiceRouter.PREPARE_DISTANCE * 0.75f])
    {
        NSString *nm = n.directionInfo.streetName;
        NSString *rf = n.directionInfo.ref;
        NSString *dn = n.directionInfo.destinationName;
        isSet = !(nm.length == 0 && rf.length == 0 && dn.length == 0);
        streetName.text = [OARoutingHelperUtils formatStreetName:nm ref:rf destination:dn towards:@"»"];
        streetName.turnType = n.directionInfo.turnType;
        streetName.shieldObject = n.directionInfo.routeDataObject;
        if (streetName.turnType)
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
            streetName.shieldObject = rs->object;
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
            streetName.shieldObject = rs->object;
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
    if (self.shieldObject != otherName.shieldObject)
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
    result = 31 * result + self.shieldObject->id;
    result = 31 * result + [self.exitRef hash];
    return result;
}

@end
