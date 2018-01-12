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
#import "Localization.h"

#include <OsmAndCore/Utilities.h>

@implementation OAAvoidSpecificRoads
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    QList<std::shared_ptr<const OsmAnd::Road>> _impassableRoads;
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

- (const QList<std::shared_ptr<const OsmAnd::Road>>) getImpassableRoads
{
    return _impassableRoads;
}

- (void) initPreservedData
{
    NSSet<CLLocation *> *impassableRoads = _settings.impassableRoads;
    for (CLLocation *impassableRoad in impassableRoads)
        [self addImpassableRoad:impassableRoad showDialog:NO skipWritingSettings:YES];
}

- (void) addImpassableRoad:(CLLocation *)loc showDialog:(BOOL)showDialog skipWritingSettings:(BOOL)skipWritingSettings
{
    OACurrentPositionHelper *positionHelper = [OACurrentPositionHelper instance];
    OARoadResultMatcher *matcher = [[OARoadResultMatcher alloc] initWithPublishFunc:^BOOL(const std::shared_ptr<const OsmAnd::Road> road)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (road)
            {
                [self addImpassableRoadInternal:road loc:loc showDialog:showDialog];
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

- (CLLocation *) getLocation:(const std::shared_ptr<const OsmAnd::Road>)road
{
    CLLocation *location = nil;
    const auto& roadLocations = _app.defaultRoutingConfig->getImpassableRoadLocations();
    const auto& it = roadLocations.find(road->id);
    if (it != roadLocations.end())
    {
        const auto& coordinate = it->second;
        const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(coordinate.first, coordinate.second));
        location = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
    return location;
}

- (void) addImpassableRoadInternal:(const std::shared_ptr<const OsmAnd::Road>)road loc:(CLLocation *)loc showDialog:(BOOL)showDialog
{
    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude));
    
    if (!_app.defaultRoutingConfig->addImpassableRoad(road->id, position31.x, position31.y))
    {
        CLLocation *location = [self getLocation:road];
        if (location)
        {
            [_settings removeImpassableRoad:[self getLocation:road]];
        }
    }
    else
    {
        _impassableRoads.push_back(road);
    }
    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    if ([rh isRouteCalculated] || [rh isRouteBeingCalculated])
        [rh recalculateRouteDueToSettingsChange];
    
    if (showDialog)
        [self showDialog];
    
    [self updateListeners];

    /*
    MapContextMenu menu = activity.getContextMenu();
    if (menu.isActive() && menu.getLatLon().equals(loc)) {
        menu.close();
    }
    activity.refreshMap();
     */
}

- (void) removeImpassableRoad:(const std::shared_ptr<const OsmAnd::Road>)road
{
    CLLocation *location = [self getLocation:road];
    if (location)
        [_settings removeImpassableRoad:[self getLocation:road]];

    [self removeImpassableRoadInternal:road];
    _app.defaultRoutingConfig->removeImpassableRoad(road->id);

    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    if ([rh isRouteCalculated] || [rh isRouteBeingCalculated])
        [rh recalculateRouteDueToSettingsChange];

    [self updateListeners];
}

- (void) removeImpassableRoadInternal:(const std::shared_ptr<const OsmAnd::Road>)road
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

- (std::shared_ptr<const OsmAnd::Road>) getRoadById:(unsigned long long)id
{
    const auto& roads = _impassableRoads;
    for (const auto& r : roads)
    {
        if (r->id == id)
            return r;
    }
    return nullptr;
}

- (void) showDialog
{
    /*
    AlertDialog.Builder bld = new AlertDialog.Builder(mapActivity);
    bld.setTitle(R.string.impassable_road);
    if (getImpassableRoads().size() == 0) {
        bld.setMessage(R.string.avoid_roads_msg);
    } else {
        final ArrayAdapter<?> listAdapter = createAdapter(mapActivity);
        bld.setAdapter(listAdapter, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                RouteDataObject obj = getImpassableRoads().get(which);
                double lat = MapUtils.get31LatitudeY(obj.getPoint31YTile(0));
                double lon = MapUtils.get31LongitudeX(obj.getPoint31XTile(0));
                showOnMap(mapActivity, lat, lon, getText(obj), dialog);
            }
            
        });
    }
    
    bld.setPositiveButton(R.string.shared_string_select_on_map, new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialogInterface, int i) {
            selectFromMap(mapActivity);
        }
    });
    bld.setNegativeButton(R.string.shared_string_close, null);
    bld.show();
     */
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
