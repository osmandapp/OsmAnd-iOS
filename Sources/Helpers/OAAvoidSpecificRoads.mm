//
//  OAAvoidSpecificRoads.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAAvoidSpecificRoads.h"
#import "OAAppSettings.h"
#import "OACurrentPositionHelper.h"
#import "OARoutingHelper.h"
#import "OsmAndApp.h"
#import "OAStateChangedListener.h"
#import "PXAlertView.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OAPointDescription.h"
#import "OAApplicationMode.h"

#include <OsmAndCore/QtExtensions.h>
#include <QList>

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/Utilities.h>

@implementation OAAvoidSpecificRoads
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSArray<OAAvoidRoadInfo *> *_impassableRoads;
    NSMutableArray<id<OAStateChangedListener>> *_listeners;
}

+ (OAAvoidSpecificRoads *) instance
{
    static dispatch_once_t once;
    static OAAvoidSpecificRoads * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _listeners = [NSMutableArray array];

        [self loadImpassableRoads];
    }
    return self;
}

- (void) loadImpassableRoads
{
    _impassableRoads = _settings.impassableRoads;
}

- (NSArray<OAAvoidRoadInfo *> *) getImpassableRoads
{
    return _impassableRoads;
}

- (void) initRouteObjects:(BOOL)force
{
    for (OAAvoidRoadInfo *roadInfo in _impassableRoads)
    {
        if (roadInfo.roadId != 0)
        {
            for (const auto& config : _app.getAllRoutingConfigs)
            {
                if (force)
                {
                    config->removeImpassableRoad(roadInfo.roadId);
                }
                else
                {
                    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(roadInfo.location.coordinate.longitude),
                                                    OsmAnd::Utilities::get31TileNumberY(roadInfo.location.coordinate.latitude));
                    config->addImpassableRoad(roadInfo.roadId, position31.x, position31.y);
                }
            }
        }
        if (force || roadInfo.roadId == 0)
        {
            [self addImpassableRoad:roadInfo.location skipWritingSettings:YES appModeKey:roadInfo.appModeKey];
        }
    }
}

- (void) addImpassableRoad:(CLLocation *)loc skipWritingSettings:(BOOL)skipWritingSettings appModeKey:(NSString *)appModeKey
{
    OAApplicationMode *defaultAppMode = [[OARoutingHelper sharedInstance] getAppMode];
    if (defaultAppMode == OAApplicationMode.DEFAULT)
        defaultAppMode = OAApplicationMode.CAR;
    OAApplicationMode *appMode = appModeKey ? [OAApplicationMode valueOfStringKey:appModeKey def:defaultAppMode] : defaultAppMode;
    
    OACurrentPositionHelper *positionHelper = [OACurrentPositionHelper instance];
    OARoadResultMatcher *matcher = [[OARoadResultMatcher alloc] initWithPublishFunc:^BOOL(const std::shared_ptr<RouteDataObject> road)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (road)
            {
                OAAvoidRoadInfo *roadInfo = [self getAvoidRoadInfoForDataObject:road loc:loc appModeKey:appMode.stringKey];
                [self addImpassableRoadInternal:roadInfo];
            }
            else
            {
                [PXAlertView showAlertWithTitle:OALocalizedString(@"impassable_road") message:OALocalizedString(@"error_avoid_specific_road")];
            }
        });

        return NO;

    } cancelledFunc:^BOOL{
        return NO;
    }];
    
    if (!skipWritingSettings)
    {
        OAAvoidRoadInfo *roadInfo = [self getAvoidRoadInfoForDataObject:nullptr loc:loc appModeKey:appMode.stringKey];
        [_settings addImpassableRoad:roadInfo];
    }
    [positionHelper getRouteSegment:loc appMode:appMode matcher:matcher];
}

- (OAAvoidRoadInfo *) getAvoidRoadInfoForDataObject:(const std::shared_ptr<RouteDataObject>)object loc:(CLLocation *)loc appModeKey:(NSString *)appModeKey
{
    OAAvoidRoadInfo *avoidRoadInfo = [self getAvoidRoadInfoByLocation:loc];
    if (!avoidRoadInfo)
        avoidRoadInfo = [[OAAvoidRoadInfo alloc] init];
    
    avoidRoadInfo.roadId = object ? object->id : 0;
    avoidRoadInfo.location = loc;
    avoidRoadInfo.appModeKey = appModeKey;
    avoidRoadInfo.name = [self getName:object];
    return avoidRoadInfo;
}

- (OAAvoidRoadInfo *) getAvoidRoadInfoByLocation:(CLLocation *)loc
{
    for (OAAvoidRoadInfo *roadInfo in _impassableRoads)
        if ([OAUtilities isCoordEqual:roadInfo.location.coordinate.latitude srcLon:roadInfo.location.coordinate.longitude destLat:loc.coordinate.latitude destLon:loc.coordinate.longitude])
            return roadInfo;

    return nil;
}

- (CLLocation *) getLocation:(int64_t)roadId
{
    CLLocation *location = nil;
    for (const auto& config : _app.getAllRoutingConfigs)
    {
        const auto& roadLocations = config->getImpassableRoadLocations();
        const auto& it = roadLocations.find(roadId);
        if (it != roadLocations.end())
        {
            const auto& coordinate = it->second;
            const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(coordinate.first, coordinate.second));
            location = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
        }
    }
    return location;
}

- (NSString *) getName:(const std::shared_ptr<RouteDataObject>)road
{
    NSString *name = nil;
    if (road)
    {
        string locale = [_settings settingPrefMapLanguage] ? [_settings settingPrefMapLanguage].UTF8String : "";
        bool transliterate = [_settings settingMapLanguageTranslit];
        
        string rStreetName = road->getName(locale, transliterate);
        string rRefName = road->getRef(locale, transliterate, true);
        string rDestinationName = road->getDestinationName(locale, transliterate, true);
        
        NSString *streetName = [NSString stringWithUTF8String:rStreetName.c_str()];
        NSString *refName = [NSString stringWithUTF8String:rRefName.c_str()];
        NSString *destinationName = [NSString stringWithUTF8String:rDestinationName.c_str()];
        
        NSString *towards = OALocalizedString(@"towards");
        
        name = [OARoutingHelper formatStreetName:streetName ref:refName destination:destinationName towards:towards];
    }
    return !name || name.length == 0 ? OALocalizedString(@"shared_string_road") : name;
}

- (void) addImpassableRoadInternal:(OAAvoidRoadInfo *)roadInfo
{
    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(roadInfo.location.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(roadInfo.location.coordinate.latitude));
    BOOL roadAdded = NO;
    for (const auto& builder : _app.getAllRoutingConfigs)
    {
        roadAdded |= builder->addImpassableRoad(roadInfo.roadId, position31.x, position31.y);
    }
    if (!roadAdded)
    {
        CLLocation *loc = [self getLocation:roadInfo.roadId];
        if (loc)
            [_settings removeImpassableRoad:loc];
    }
    else
    {
        [_settings updateImpassableRoad:roadInfo];
        [self updateImpassableRoad:roadInfo];
    }

    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    if ([rh isRouteCalculated] || [rh isRouteBeingCalculated])
        [rh recalculateRouteDueToSettingsChange];
        
    [self updateListeners];
}

- (void) updateImpassableRoad:(OAAvoidRoadInfo *)roadInfo
{
    BOOL updated = NO;
    NSMutableArray<OAAvoidRoadInfo *> *arr = [NSMutableArray arrayWithArray:_impassableRoads];
    for (OAAvoidRoadInfo *r in arr)
    {
        if ([OAUtilities isCoordEqual:roadInfo.location.coordinate.latitude srcLon:roadInfo.location.coordinate.longitude destLat:r.location.coordinate.latitude destLon:r.location.coordinate.longitude])
        {
            r.roadId = roadInfo.roadId;
            r.name = roadInfo.name;
            r.appModeKey = roadInfo.appModeKey;
            updated = YES;
        }
    }
    if (!updated)
        [arr addObject:roadInfo];
    
    _impassableRoads = [NSArray arrayWithArray:arr];
}

- (void) removeImpassableRoad:(OAAvoidRoadInfo *)roadInfo
{
    CLLocation *location = [self getLocation:roadInfo.roadId];
    if (location)
        [_settings removeImpassableRoad:location];

    [self removeImpassableRoadInternal:roadInfo];
    for (const auto& config : _app.getAllRoutingConfigs)
        config->removeImpassableRoad(roadInfo.roadId);

    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    if ([rh isRouteCalculated] || [rh isRouteBeingCalculated])
        [rh recalculateRouteDueToSettingsChange];

    [self updateListeners];
}

- (void) removeImpassableRoadInternal:(OAAvoidRoadInfo *)roadInfo
{
    _impassableRoads = [_impassableRoads filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(roadId != %llu)", roadInfo.roadId]];
}

- (OAAvoidRoadInfo *) getRoadInfoById:(unsigned long long)id
{
    for (OAAvoidRoadInfo *roadInfo in _impassableRoads)
        if (roadInfo.roadId == id)
            return roadInfo;
    
    return nil;
}

- (void) addListener:(id<OAStateChangedListener>)l
{
    [_listeners addObject:l];
}

- (void) removeListener:(id<OAStateChangedListener>)l
{
    [_listeners removeObject:l];
}

- (void) updateListeners
{
    for (id<OAStateChangedListener> l in _listeners)
        [l stateChanged:(nil)];
}

@end
