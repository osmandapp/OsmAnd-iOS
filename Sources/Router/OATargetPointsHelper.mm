//
//  OATargetPointsHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OALocationServices.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OARTargetPoint.h"
#import "OARouteProvider.h"
#import "OAStateChangedListener.h"
#import "OAReverseGeocoder.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OARoutePreferencesParameters.h"

@implementation OATargetPointsHelper
{
    NSMutableArray<OARTargetPoint *> *_intermediatePoints;
    OARTargetPoint *_pointToNavigate;
    OARTargetPoint *_pointToStart;
    OARTargetPoint *_pointToNavigateBackup;
    OARTargetPoint *_pointToStartBackup;
    OARTargetPoint *_myLocationToStart;
    OARTargetPoint *_homePoint;
    OARTargetPoint *_workPoint;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    
    NSMutableArray<id<OAStateChangedListener>> *_listeners;
    
    BOOL _isSearchingHome;
    BOOL _isSearchingWork;
    BOOL _isSearchingStart;
    BOOL _isSearchingMyLocation;
    
    OARTargetPoint *_destinationLookupPoint;
}

+ (OATargetPointsHelper *) sharedInstance
{
    static OATargetPointsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OATargetPointsHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _intermediatePoints = [NSMutableArray array];
        _settings = [OAAppSettings sharedManager];
        _listeners = [NSMutableArray array];
        _routingHelper = [OARoutingHelper sharedInstance];
        
        [self readFromSettings];
    }
    return self;
}

- (void) readFromSettings
{
    _pointToNavigate = _app.data.pointToNavigate;
    _pointToStart = _app.data.pointToStart;
    _intermediatePoints = [NSMutableArray arrayWithArray:_app.data.intermediatePoints];
    _pointToNavigateBackup = _app.data.pointToNavigateBackup;
    _pointToStartBackup = _app.data.pointToStartBackup;
    _myLocationToStart = _app.data.myLocationToStart;

    if (_pointToStart)
    {
        _pointToNavigate.start = YES;
        _pointToNavigate.intermediate = NO;
    }
    if (_pointToNavigate)
    {
        _pointToNavigate.start = NO;
        _pointToNavigate.intermediate = NO;
    }
    if (_intermediatePoints && _intermediatePoints.count > 0)
    {
        int i = 0;
        for (OARTargetPoint *p in _intermediatePoints)
        {
            p.start = NO;
            p.intermediate = YES;
            p.index = i++;
        }
    }
    
    [self lookupAllAddresses];
}

- (void)readMyLocationPointFromSettings
{
    _myLocationToStart = _app.data.myLocationToStart;
    [self lookupAddressForMyLocationPoint];
}

- (OARTargetPoint *) getPointToNavigate
{
    return _pointToNavigate;
}

- (OARTargetPoint *) getPointToStart
{
    return _pointToStart;
}

- (OARTargetPoint *)getPointToNavigateBackup
{
    return _pointToNavigateBackup;
}

- (OARTargetPoint *)getPointToStartBackup
{
    return _pointToStartBackup;
}

- (OARTargetPoint *)getMyLocationToStart
{
    return _myLocationToStart;
}

- (BOOL)isBackupPointsAvailable
{
    OARTargetPoint *startPoint = [self getPointToStartBackup];
    OARTargetPoint *endPoint = [self getPointToNavigateBackup];
    if (!startPoint)
        startPoint = [self getMyLocationToStart];
    return startPoint && endPoint;
}

- (OAPointDescription *) getStartPointDescription
{
    return _app.data.pointToStart ? _app.data.pointToStart.pointDescription : nil;
}

- (NSArray<OARTargetPoint *> *) getIntermediatePoints
{
    return _intermediatePoints;
}

- (NSArray<OARTargetPoint *> *) getIntermediatePointsNavigation
{
    NSMutableArray<OARTargetPoint *> *intermediatePoints = [NSMutableArray array];
    if (_settings.useIntermediatePointsNavigation.get)
    {
        for (OARTargetPoint *t in _intermediatePoints)
            [intermediatePoints addObject:t];
    }
    return intermediatePoints;
}

- (NSArray<CLLocation *> *) getIntermediatePointsLatLon
{
    NSMutableArray<CLLocation *> *intermediatePointsLatLon = [NSMutableArray array];
    for (OARTargetPoint *t in _intermediatePoints)
        [intermediatePointsLatLon addObject:t.point];
    
    return intermediatePointsLatLon;
}

- (NSArray<CLLocation *> *) getIntermediatePointsLatLonNavigation
{
    NSMutableArray<CLLocation *> *intermediatePointsLatLon = [NSMutableArray array];
    if (_settings.useIntermediatePointsNavigation.get)
    {
        for (OARTargetPoint *t in _intermediatePoints)
            [intermediatePointsLatLon addObject:t.point];
    }
    return intermediatePointsLatLon;
}

- (NSArray<OARTargetPoint *> *) getAllPoints
{
    NSMutableArray<OARTargetPoint *> *res = [NSMutableArray array];
    if (_pointToStart)
        [res addObject:_pointToStart];
    
    [res addObjectsFromArray:_intermediatePoints];
    if (_pointToNavigate)
        [res addObject:_pointToNavigate];
    
    return res;
}

- (NSArray<OARTargetPoint *> *) getIntermediatePointsWithTarget
{
    NSMutableArray<OARTargetPoint *> *res = [NSMutableArray array];
    [res addObjectsFromArray:_intermediatePoints];
    if (_pointToNavigate)
        [res addObject:_pointToNavigate];
    
    return res;
}

- (OARTargetPoint *)getFirstIntermediatePoint
{
    return [self getIntermediatePoint:0];
}

- (OARTargetPoint *)getIntermediatePoint:(int)intermediatePointIndex
{
    return intermediatePointIndex < _intermediatePoints.count ? _intermediatePoints[intermediatePointIndex] : nil;
}

- (void) restoreTargetPoints:(BOOL)updateRoute
{
    [_app.data restoreTargetPoints];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
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
    [self updateListeners:YES];
}

- (void) updateListeners:(BOOL) refreshMap
{
    for (id<OAStateChangedListener> l in _listeners)
        [l stateChanged:@(refreshMap)];
}

- (void) updateRouteAndRefresh:(BOOL)updateRoute
{
    if(updateRoute && ([_routingHelper isPublicTransportMode] || [_routingHelper isRouteBeingCalculated] ||
            [_routingHelper isRouteCalculated] || [_routingHelper isFollowingMode] || [_routingHelper isRoutePlanningMode]))
    {
        [self updateRoutingHelper];
    }
    [self updateListeners];
}

- (void)updateMyLocationToStart
{
    if (!_pointToStart)
    {
        CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
//        OARoutingHelperUtils.checkAndUpdateStartLocation(ctx, latLon, false);
        [self setMyLocationPoint:lastKnownLocation updateRoute:false name:nil];
    }
}

- (void) updateRoutingHelper
{
    OARTargetPoint *start = _app.data.pointToStart;
    CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
    NSArray<CLLocation *> *is = [self getIntermediatePointsLatLonNavigation];
    if (([_routingHelper isFollowingMode] && lastKnownLocation) || !start)
    {
        [_routingHelper setFinalAndCurrentLocation:_app.data.pointToNavigate.point intermediatePoints:is currentLocation:lastKnownLocation];
    }
    else
    {
        CLLocation *loc = start.point;
        [_routingHelper setFinalAndCurrentLocation:_app.data.pointToNavigate.point intermediatePoints:is currentLocation:loc];
    }
}


- (void) clearPointToNavigate:(BOOL)updateRoute
{
    [_app.data clearPointToNavigate];
    [_app.data clearIntermediatePoints];
    [_intermediatePoints removeAllObjects];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) clearStartPoint:(BOOL)updateRoute
{
    [_app.data clearPointToStart];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) clearAllIntermediatePoints:(BOOL)updateRoute
{
    [_app.data clearIntermediatePoints];
    [_intermediatePoints removeAllObjects];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) clearAllPoints:(BOOL)updateRoute
{
    [_app.data clearPointToStart];
    [_app.data clearIntermediatePoints];
    [_app.data clearPointToNavigate];
    [_intermediatePoints removeAllObjects];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void)clearBackupPoints
{
    [_app.data clearPointToStartBackup];
    [_app.data clearIntermediatePointsBackup];
    [_app.data clearPointToNavigateBackup];
    [self readFromSettings];
}

- (void) reorderAllTargetPoints:(NSArray<OARTargetPoint *> *)point updateRoute:(BOOL)updateRoute
{
    [_app.data clearPointToNavigate];
    if (point.count > 0)
    {
        _app.data.intermediatePoints = [point subarrayWithRange:NSMakeRange(0, point.count - 1)];
        [_app.data backupTargetPoints];
        OARTargetPoint *p = point[point.count - 1];
        [_app.data setPointToNavigate:[OARTargetPoint create:p.point name:p.pointDescription]];
    }
    else
    {
        [_app.data clearIntermediatePoints];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

/**
 * Move an intermediate waypoint to the destination.
 */
- (void) makeWayPointDestination:(BOOL)updateRoute index:(int)index
{
    OARTargetPoint *targetPoint = _intermediatePoints[index];
    [_intermediatePoints removeObjectAtIndex:index];

    _pointToNavigate = targetPoint;
    [_app.data setPointToNavigate:[[OARTargetPoint alloc] initWithPoint:_pointToNavigate.point name:_pointToNavigate.pointDescription]];
    _pointToNavigate.intermediate = false;
    [_app.data deleteIntermediatePoint:index];
    
    [self lookupAddressForDestinationPoint];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) removeWayPoint:(BOOL)updateRoute index:(int)index
{
    if (index < 0)
    {
        [_app.data clearPointToNavigate];
        _pointToNavigate = nil;
        auto sz = _intermediatePoints.count;
        if (sz > 0)
        {
            [_app.data deleteIntermediatePoint:(int)(sz - 1)];
            _pointToNavigate = _intermediatePoints[sz - 1];
            [_intermediatePoints removeObjectAtIndex:sz - 1];
            _pointToNavigate.intermediate = NO;
            [_app.data setPointToNavigate:[[OARTargetPoint alloc] initWithPoint:_pointToNavigate.point name:_pointToNavigate.pointDescription]];
            [self lookupAddressForDestinationPoint];
        }
    }
    else
    {
        [_app.data deleteIntermediatePoint:index];
        [_intermediatePoints removeObjectAtIndex:index];
        int ind = 0;
        for (OARTargetPoint *tp in _intermediatePoints)
        {
            tp.index = ind++;
        }
    }
    [self updateRouteAndRefresh:updateRoute];
}

- (void) navigateToPoint:(CLLocation *)point updateRoute:(BOOL)updateRoute intermediate:(int)intermediate
{
    [self navigateToPoint:point updateRoute:updateRoute intermediate:intermediate historyName:nil];
}

- (void) lookupAllAddresses
{
    [self lookupAddressForDestinationPoint];
    [self lookupAddressForStartPoint];
    for (OARTargetPoint *targetPoint : _intermediatePoints)
    {
        [self lookupAddressForIntermediatePoint:targetPoint];
    }
    [self lookupAddressForHomePoint];
    [self lookupAddressForWorkPoint];
    [self lookupAddressForMyLocationPoint];
}

- (void) navigateToPoint:(CLLocation *)point updateRoute:(BOOL)updateRoute intermediate:(int)intermediate historyName:(OAPointDescription *)historyName
{
    if (point)
    {
        OAPointDescription *pointDescription;
        if (!historyName)
            pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        else
            pointDescription = historyName;
        
        if ([pointDescription isLocation] && pointDescription.name.length == 0)
            [pointDescription setName:[OAPointDescription getSearchAddressStr]];
        
        if (intermediate < 0 || intermediate > (int)_intermediatePoints.count)
            {
                if (intermediate > (int)_intermediatePoints.count)
                {
                    OARTargetPoint *pn = [self getPointToNavigate];
                    if (pn)
                        [_app.data addIntermediatePoint:pn];

                }
                [_app.data setPointToNavigate:[OARTargetPoint create:point name:pointDescription]];
            }
            else
            {
                [_app.data insertIntermediatePoint:[OARTargetPoint create:point name:pointDescription] index:intermediate];
            }
        }
        else
        {
            [_app.data clearPointToNavigate];
            [_app.data clearIntermediatePoints];
        }
        [self readFromSettings];
        [self updateRouteAndRefresh:updateRoute];
}

- (void) setStartPoint:(CLLocation *)startPoint updateRoute:(BOOL)updateRoute name:(OAPointDescription *)name
{
    if (startPoint)
    {
        OAPointDescription *pointDescription;
        if (!name)
            pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        else
            pointDescription = name;
        
        if ([pointDescription isLocation] && pointDescription.name.length == 0)
            [pointDescription setName:[OAPointDescription getSearchAddressStr]];
        
        [_app.data setPointToStart:[OARTargetPoint createStartPoint:startPoint name:pointDescription]];
    }
    else
    {
        [_app.data clearPointToStart];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void)setMyLocationPoint:(CLLocation *)startPoint updateRoute:(BOOL)updateRoute name:(OAPointDescription *)name
{
    if (startPoint)
    {
        OAPointDescription *pointDescription;
        if (!name)
            pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        else
            pointDescription = name;
        
        if ([pointDescription isLocation] && pointDescription.name.length == 0)
            [pointDescription setName:[OAPointDescription getSearchAddressStr]];
        
        [_app.data setMyLocationToStart:[OARTargetPoint createStartPoint:startPoint name:pointDescription]];
    }
    else
    {
        [_app.data clearMyLocationToStart];
    }
    [self readMyLocationPointFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (OARTargetPoint *) getHomePoint
{
    OAFavoriteItem *homeFavorite = [OAFavoritesHelper getSpecialPoint:[OASpecialPointType HOME]];
    if (homeFavorite)
    {
        OAPointDescription *pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:[homeFavorite getAddress]];
        return [OARTargetPoint create:[[CLLocation alloc] initWithLatitude:[homeFavorite getLatitude] longitude:[homeFavorite getLongitude]] name:pointDescription];
    }
    return nil;
}

- (void) setHomePoint:(CLLocation *) latLon description:(OAPointDescription *)name
{
    OAPointDescription *pointDescription;
    if (!name)
    {
        pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
    }
    else
    {
        pointDescription = name;
    }
    if ([pointDescription isLocation] && pointDescription.name.length == 0)
    {
        [pointDescription setName:[OAPointDescription getSearchAddressStr]];
    }
    [OAFavoritesHelper setSpecialPoint:[OASpecialPointType HOME] lat:latLon.coordinate.latitude lon:latLon.coordinate.longitude address:pointDescription.name];
    [self lookupAddressForHomePoint];
}

- (OARTargetPoint *) getWorkPoint
{
    OAFavoriteItem *workFavorite = [OAFavoritesHelper getSpecialPoint:[OASpecialPointType WORK]];
    if (workFavorite)
    {
        OAPointDescription *pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:[workFavorite getAddress]];
        return [OARTargetPoint create:[[CLLocation alloc] initWithLatitude:[workFavorite getLatitude] longitude:[workFavorite getLongitude]] name:pointDescription];
    }
    return nil;
}

- (void) setWorkPoint:(CLLocation *) latLon description:(OAPointDescription *)name
{
    OAPointDescription *pointDescription;
    if (!name)
    {
        pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
    } else
    {
        pointDescription = name;
    }
    if ([pointDescription isLocation] && pointDescription.name.length == 0)
    {
        [pointDescription setName:[OAPointDescription getSearchAddressStr]];
    }
    [OAFavoritesHelper setSpecialPoint:[OASpecialPointType WORK] lat:latLon.coordinate.latitude lon:latLon.coordinate.longitude address:pointDescription.name];
    [self lookupAddressForWorkPoint];
}

- (void)lookupAddressForHomePoint
{
    OARTargetPoint *homePoint = [self getHomePoint];
    if (homePoint == nil || ![homePoint isSearchingAddress] || _isSearchingHome)
        return;
    
    _isSearchingHome = YES;
    
    __weak __typeof(self) weakSelf = self;
    [self getLocationName:homePoint.point completion:^(NSString *pointName) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf)
            return;
        
        [homePoint.pointDescription setName:pointName];
        [OAFavoritesHelper setSpecialPoint:[OASpecialPointType HOME]
                                       lat:homePoint.getLatitude
                                       lon:homePoint.getLongitude
                                   address:pointName];
        [strongSelf updateListeners:NO];
        strongSelf->_isSearchingHome = NO;
    }];
}

- (void)lookupAddressForWorkPoint
{
    OARTargetPoint *workPoint = [self getWorkPoint];
    if (workPoint == nil || ![workPoint isSearchingAddress] || _isSearchingWork)
        return;
    
    _isSearchingWork = YES;
    
    __weak __typeof(self) weakSelf = self;
    [self getLocationName:workPoint.point completion:^(NSString *pointName) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf)
            return;
        
        [workPoint.pointDescription setName:pointName];
        [OAFavoritesHelper setSpecialPoint:[OASpecialPointType WORK]
                                       lat:workPoint.getLatitude
                                       lon:workPoint.getLongitude
                                   address:pointName];
        [strongSelf updateListeners:NO];
        strongSelf->_isSearchingWork = NO;
    }];
}

- (void)lookupAddressForStartPoint
{
    if (_pointToStart == nil || ![_pointToStart isSearchingAddress] || _isSearchingStart)
        return;
    
    _isSearchingStart = YES;
    OARTargetPoint *startPoint = _pointToStart;
    
    __weak __typeof(self) weakSelf = self;
    [self getLocationName:startPoint.point completion:^(NSString *pointName) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf)
            return;
        
        if (strongSelf->_pointToStart != startPoint)
        {
            strongSelf->_isSearchingStart = NO;
            return;
        }
        [startPoint.pointDescription setName:pointName];
        [strongSelf->_app.data setPointToStart:startPoint];
        [strongSelf updateRouteAndRefresh:NO];
        strongSelf->_isSearchingStart = NO;
    }];
}

- (void)lookupAddressForMyLocationPoint
{
    if (_myLocationToStart == nil || ![_myLocationToStart isSearchingAddress] || _isSearchingMyLocation)
        return;
    
    _isSearchingMyLocation = YES;
    OARTargetPoint *localMyStart = _myLocationToStart;
    CLLocation *localPoint = localMyStart.point;
    
    __weak __typeof(self) weakSelf = self;
    [self getLocationName:localPoint completion:^(NSString *pointName) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf)
            return;
        
        if (strongSelf->_myLocationToStart == localMyStart)
        {
            [localMyStart.pointDescription setName:pointName ?: @""];
            [strongSelf->_app.data setMyLocationToStart:localMyStart];
            [strongSelf updateRouteAndRefresh:NO];
        }
        strongSelf->_isSearchingMyLocation = NO;
    }];
}

- (void)lookupAddressForDestinationPoint
{
    OARTargetPoint *destination = _pointToNavigate;
    
    if (!destination)
    {
        _destinationLookupPoint = nil;
        return;
    }
    
    if (![destination isSearchingAddress] && !NSStringIsEmpty(destination.pointDescription.address))
        return;
    
    if (_destinationLookupPoint == destination)
        return;
    
    _destinationLookupPoint = destination;
    CLLocation *location = destination.point;
    BOOL isNameNotValid = [destination isSearchingAddress];
    
    __weak __typeof(self) weakSelf = self;
    [self getLocationName:location completion:^(NSString *pointName) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf)
            return;
        
        if (strongSelf->_destinationLookupPoint != destination)
            return;
        
        strongSelf->_destinationLookupPoint = nil;
        
        if (strongSelf->_pointToNavigate != destination)
            return;
        
        if (isNameNotValid)
        {
            [destination.pointDescription setName:pointName];
            destination.pointDescription.address = pointName;
            [strongSelf->_app.data setPointToNavigate:destination];
        }
        else
        {
            destination.pointDescription.address = pointName;
            [strongSelf->_app.data backupTargetPoints];
        }
        [strongSelf updateRouteAndRefresh:NO];
    }];
}

- (void)lookupAddressForIntermediatePoint:(OARTargetPoint *)point
{
    BOOL isNameNotValid = point != nil && [point isSearchingAddress];
    BOOL isAddressEmpty = point != nil && NSStringIsEmpty(point.pointDescription.address) && _intermediatePoints.firstObject == point;
    
    if (!isNameNotValid && !isAddressEmpty)
        return;
    
    OARTargetPoint *targetPoint = point;
    CLLocation *location = targetPoint.point;
    
    __weak __typeof(self) weakSelf = self;
    [self getLocationName:location completion:^(NSString *pointName) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf)
            return;
        
        if ([strongSelf->_intermediatePoints indexOfObjectIdenticalTo:targetPoint] == NSNotFound)
            return;
        
        if (isNameNotValid)
            [targetPoint.pointDescription setName:pointName];
        
        targetPoint.pointDescription.address = pointName;
        [strongSelf->_app.data backupTargetPoints];
        [strongSelf updateRouteAndRefresh:NO];
    }];
}

- (void)getLocationName:(CLLocation *)location completion:(void (^)(NSString *name))completion
{
    if (!completion)
        return;
    
    if (!location || !CLLocationCoordinate2DIsValid(location.coordinate))
    {
        completion(OALocalizedString(@"map_no_address"));
        return;
    }
    
    [[OAReverseGeocoder instance] lookupAddressAtLat:location.coordinate.latitude
                                                 lon:location.coordinate.longitude
                                            objectId:0
                                          completion:^(NSString *address) {
        if (address.length > 0)
            completion(address);
        else
            completion(OALocalizedString(@"map_no_address"));
    }];
}

- (BOOL) hasTooLongDistanceToNavigate
{
    OAApplicationMode *mode = _settings.applicationMode.get;
    if ([_settings.routerService get:mode] != EOARouteService::OSMAND)
        return false;
    bool hhRouting = ![_settings.useOldRouting get];
    if (hhRouting &&
        ([[OAApplicationMode DEFAULT] isDerivedRoutingFrom:[_routingHelper getAppMode]]
         || [[OAApplicationMode CAR] isDerivedRoutingFrom:[_routingHelper getAppMode]]
         || [[OAApplicationMode BICYCLE] isDerivedRoutingFrom:[_routingHelper getAppMode]]))
    {
        return false;
    }

    CLLocation *current = [_routingHelper getLastProjection];
    double dist = 400000;
    if ([[OAApplicationMode BICYCLE] isDerivedRoutingFrom:[_routingHelper getAppMode]] && [[_settings getCustomRoutingBooleanProperty:kRouteParamHeightObstacles defaultValue:false] get:[_routingHelper getAppMode]])
    {
        dist = 50000;
    }
    NSArray<OARTargetPoint *> *list = [self getIntermediatePointsWithTarget];
    if (list.count > 0)
    {
        if (current && [list[0].point distanceFromLocation:current] > dist)
            return true;

        for (int i = 1; i < list.count; i++)
        {
            if ([list[i - 1].point distanceFromLocation:list[i].point] > dist)
                return true;
        }
    }
    return false;
}

/**
 * Clear the local and persistent waypoints list and destination.
 */
- (void) removeAllWayPoints:(BOOL)updateRoute clearBackup:(BOOL)clearBackup
{
    [_app.data clearIntermediatePoints];
    [_app.data clearPointToNavigate];
    [_app.data clearPointToStart];
    if (clearBackup)
        [_app.data backupTargetPoints];
    [self updateMyLocationToStart];
    _pointToNavigate = nil;
    _pointToStart = nil;
    [_intermediatePoints removeAllObjects];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (BOOL) checkPointToNavigateShort
{
    if (!_pointToNavigate)
    {
        // TODO toast
        //ctx.showShortToastMessage(R.string.mark_final_location_first);
        return NO;
    }
    return YES;
}

@end
