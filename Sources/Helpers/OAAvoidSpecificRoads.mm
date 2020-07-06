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

#include <OsmAndCore/Utilities.h>

@implementation OAAvoidRoadInfo

- (NSUInteger) hash
{
    NSInteger result = self.roadId;
    result = 31 * result + (self.location.latitude * 10000.0);
    result = 31 * result + (self.location.longitude * 10000.0);
    result = 31 * result + [self.name hash];
    result = 31 * result + [self.appModeKey hash];
    return result;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[OAAvoidRoadInfo class]])
          return NO;
    
    OAAvoidRoadInfo *other = object;
    return [OAUtilities isCoordEqual:self.location.latitude srcLon:self.location.longitude destLat:other.location.latitude destLon:other.location.longitude] && (self.name == other.name || [self.name isEqualToString:other.name]);
}

@end

@implementation OAAvoidSpecificRoads
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    QList<std::shared_ptr<RouteDataObject>> _impassableRoads;
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

        [self initPreservedData];
    }
    return self;
}

- (const QList<std::shared_ptr<RouteDataObject>>) getImpassableRoads
{
    return _impassableRoads;
}

- (NSArray<OAAvoidRoadInfo *> *) getImpassableRoadsInfo
{
    NSMutableArray<OAAvoidRoadInfo *> *res = [NSMutableArray array];
    const auto& roads = _impassableRoads;
    for (const auto& r : roads)
    {
        OAAvoidRoadInfo *info = [[OAAvoidRoadInfo alloc] init];
        info.roadId = r->id;
        CLLocation *location = [self getLocation:r->id];
        info.location = location.coordinate;
        info.name = [self getName:r.get() loc:location];
        info.appModeKey = nil;
        [res addObject:info];
    }
    return res;
}

- (void) initPreservedData
{
    NSSet<CLLocation *> *impassableRoads = _settings.impassableRoads;
    for (CLLocation *impassableRoad in impassableRoads)
        [self addImpassableRoad:impassableRoad skipWritingSettings:YES];
}

- (void) addImpassableRoad:(CLLocation *)loc skipWritingSettings:(BOOL)skipWritingSettings
{
    OACurrentPositionHelper *positionHelper = [OACurrentPositionHelper instance];
    OARoadResultMatcher *matcher = [[OARoadResultMatcher alloc] initWithPublishFunc:^BOOL(const std::shared_ptr<RouteDataObject> road)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (road)
            {
                [self addImpassableRoadInternal:road loc:loc];
                if (!skipWritingSettings)
                    [_settings addImpassableRoad:loc];
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
    
    [positionHelper getRouteSegment:loc matcher:matcher];
}

- (CLLocation *) getLocation:(int64_t)roadId
{
    CLLocation *location = nil;
    const auto& roadLocations = _app.defaultRoutingConfig->getImpassableRoadLocations();
    const auto& it = roadLocations.find(roadId);
    if (it != roadLocations.end())
    {
        const auto& coordinate = it->second;
        const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(coordinate.first, coordinate.second));
        location = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
    return location;
}

- (NSString *) getName:(RouteDataObject *)road loc:(CLLocation *)loc
{
    string lang = [_settings settingPrefMapLanguage] ? [_settings settingPrefMapLanguage].UTF8String : "";
    bool transliterate = [_settings settingMapLanguageTranslit];
    NSString *name = [NSString stringWithUTF8String:road->getName(lang, transliterate).c_str()];
    if (name.length == 0)
        name = [OAPointDescription getLocationName:loc.coordinate.latitude lon:loc.coordinate.longitude sh:YES];
    
    return name;
}

- (void) addImpassableRoadInternal:(const std::shared_ptr<RouteDataObject>)road loc:(CLLocation *)loc
{
    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude));
    
    if (!_app.defaultRoutingConfig->addImpassableRoad(road->id, position31.x, position31.y))
    {
        CLLocation *location = [self getLocation:road->id];
        if (location)
        {
            [_settings removeImpassableRoad:[self getLocation:road->id]];
        }
    }
    else
    {
        _impassableRoads.push_back(road);
    }
    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    if ([rh isRouteCalculated] || [rh isRouteBeingCalculated])
        [rh recalculateRouteDueToSettingsChange];
        
    [self updateListeners];
}

- (void) removeImpassableRoad:(const std::shared_ptr<RouteDataObject>)road
{
    CLLocation *location = [self getLocation:road->id];
    if (location)
        [_settings removeImpassableRoad:[self getLocation:road->id]];

    [self removeImpassableRoadInternal:road];
    _app.defaultRoutingConfig->removeImpassableRoad(road->id);

    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    if ([rh isRouteCalculated] || [rh isRouteBeingCalculated])
        [rh recalculateRouteDueToSettingsChange];

    [self updateListeners];
}

- (void) removeImpassableRoadInternal:(const std::shared_ptr<RouteDataObject>)road
{
    for (int i = 0; i < _impassableRoads.size(); i++)
    {
        const auto& r = _impassableRoads[i];
        if (r->id == road->id)
        {
            _impassableRoads.removeAt(i);
            return;
        }
    }
}

- (std::shared_ptr<RouteDataObject>) getRoadById:(unsigned long long)id
{
    const auto& roads = _impassableRoads;
    for (const auto& r : roads)
    {
        if (r->id == id)
            return r;
    }
    return nullptr;
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
