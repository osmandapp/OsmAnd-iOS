//
//  OAMapActions.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapActions.h"
#import "OAPointDescription.h"
#import "OsmAndApp.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAAlertBottomSheetViewController.h"
#import "Localization.h"
#import "OAObservable.h"
#import "OALocationServices.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAApplicationMode.h"
#import "OAMapSource.h"
#import "OARouteProvider.h"
#import "OAMapViewTrackingUtilities.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OATargetPoint.h"
#import "OAWaypointHelper.h"
#import "OAAppData.h"
#import "OAAddWaypointBottomSheetViewController.h"
#import "OAUninstallSpeedCamerasViewController.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#define START_TRACK_POINT_MY_LOCATION_RADIUS_METERS 50 * 1000

@implementation OAMapActions
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    OAMapViewTrackingUtilities *_trackingUtils;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _routingHelper = [OARoutingHelper sharedInstance];
        _trackingUtils = [OAMapViewTrackingUtilities instance];

    }
    return self;
}

- (void) enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName
{
    [self enterRoutePlanningMode:from fromName:fromName checkDisplayedGpx:YES];
}

- (void) enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName checkDisplayedGpx:(BOOL)shouldCheck
{
    BOOL useIntermediatePointsByDefault = true;
    
    [self enterRoutePlanningModeGivenGpx:nil from:from fromName:fromName useIntermediatePointsByDefault:useIntermediatePointsByDefault showDialog:YES];
}

- (void) enterRoutePlanningModeGivenGpx:(OASGpxDataItem *)gpxFile useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog
{
    [self enterRoutePlanningModeGivenGpx:[self getGpxDocumentByGpx:gpxFile] path:gpxFile.gpxFilePath from:nil fromName:nil useIntermediatePointsByDefault:useIntermediatePointsByDefault showDialog:showDialog];
}

- (void) enterRoutePlanningModeGivenGpx:(OASGpxDataItem *)gpxFile from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog
{
    [self enterRoutePlanningModeGivenGpx:[self getGpxDocumentByGpx:gpxFile] path:gpxFile.gpxFilePath from:from fromName:fromName useIntermediatePointsByDefault:useIntermediatePointsByDefault showDialog:showDialog];
}

- (void) enterRoutePlanningModeGivenGpx:(OASGpxFile *)gpxFile path:(NSString *)path from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog
{
    [self enterRoutePlanningModeGivenGpx:gpxFile appMode:nil path:path from:from fromName:fromName useIntermediatePointsByDefault:useIntermediatePointsByDefault showDialog:showDialog];
}

- (OAApplicationMode *)getRouteProfile:(OASGpxFile *)gpxFile
{
    NSArray<OASWptPt *> *points = [gpxFile getRoutePoints];
    if (points && points.count > 0)
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:[points[0] getProfileType] def:nil];
        if (mode)
            return mode;
    }
    return nil;
}

- (void) enterRoutePlanningModeGivenGpx:(OASGpxFile *)gpxFile appMode:(OAApplicationMode *)appMode path:(NSString *)path from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog
{
    [_settings.useIntermediatePointsNavigation set:useIntermediatePointsByDefault];
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    
    OAApplicationMode *mode = appMode ? appMode : [self getRouteProfile:gpxFile];
    if (!mode)
        mode = appMode ? appMode : [self getRouteMode];
    
    [_routingHelper setAppMode:mode];
    [_app initVoiceCommandPlayer:mode warningNoneProvider:YES showDialog:NO force:NO];
    // save application mode controls
    [_settings.followTheRoute set:NO];
    [[[OsmAndApp instance] followTheRouteObservable] notifyEvent];
    [_routingHelper setFollowingMode:false];
    [_routingHelper setRoutePlanningMode:true];
    // reset start point
    [targets setStartPoint:from updateRoute:NO name:fromName];
    // then set gpx
    [self setGPXRouteParamsWithDocument:gpxFile path:path];
    // then update start and destination point
    [targets updateRouteAndRefresh:true];
    
    [_trackingUtils switchToRoutePlanningMode];
    [[OARootViewController instance].mapPanel refreshMap];
    if (showDialog)
        [[OARootViewController instance].mapPanel showRouteInfo];

    if ([targets hasTooLongDistanceToNavigate])
        [_app showToastMessage:OALocalizedString(@"route_is_too_long_v2")];

    if (![_settings.speedCamerasAlertShown get])
    {
        OAUninstallSpeedCamerasViewController *speedCamerasViewController = [[OAUninstallSpeedCamerasViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:speedCamerasViewController];
        [[OARootViewController instance] presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void) setGPXRouteParamsWithDocument:(OASGpxFile *)doc path:(NSString *)path
{
//    if (!doc)
//    {
//        [_routingHelper setGpxParams:nil];
//        [_settings.followTheGpxRoute set:nil];
//    }
//    else
//    {
//        OAGPXRouteParamsBuilder *params = [[OAGPXRouteParamsBuilder alloc] initWithDoc:doc];
//        if ([doc hasRtePt] && ![doc hasTrkPt])
//            [_settings.gpxCalculateRtept set:YES];
//        else
//            [_settings.gpxCalculateRtept set:NO];
//        
//        [params setCalculateOsmAndRouteParts:_settings.gpxRouteCalcOsmandParts.get];
//        [params setUseIntermediatePointsRTE:_settings.gpxCalculateRtept.get];
//        [params setCalculateOsmAndRoute:_settings.gpxRouteCalc.get];
//        [params setSelectedSegment:_settings.gpxRouteSegment.get];
//        NSArray<CLLocation *> *ps = [params getPoints];
//        [_routingHelper setGpxParams:params];
//        [_settings.followTheGpxRoute set:path];
//        if (ps.count > 0)
//        {
//            OATargetPointsHelper *pointsHelper = [OATargetPointsHelper sharedInstance];
//            CLLocation *startLoc = ps.firstObject;
//            CLLocation *finishLoc = ps.lastObject;
//            CLLocation *location = _app.locationServices.lastKnownLocation;
//            [pointsHelper clearAllIntermediatePoints:NO];
//            if (!location || [location distanceFromLocation:startLoc] <= START_TRACK_POINT_MY_LOCATION_RADIUS_METERS)
//            {
//                [pointsHelper clearStartPoint:NO];
//            }
//            else
//            {
//                [pointsHelper setStartPoint:startLoc.copy updateRoute:NO name:nil];
//                [params setPassWholeRoute:YES];
//            }
//            
//            [pointsHelper navigateToPoint:finishLoc.copy updateRoute:NO intermediate:-1];
//        }
//    }
}

- (OASGpxFile *)getGpxDocumentByGpx:(OASGpxDataItem *)gpx
{
    OASGpxFile *document = nil;
    NSDictionary<NSString *, OASGpxFile *> *gpxMap = [[OASelectedGPXHelper instance].activeGpx copy];
    NSString *path = gpx.file.absolutePath;
    if ([gpxMap objectForKey:path])
    {
        document = gpxMap[path];
        document.path = path;
    }
    else
    {
        OASKFile *file = [[OASKFile alloc] initWithFilePath:path];
        OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
        
        document = gpxFile;
    }
    return document;
}

- (void) setGPXRouteParams:(OASGpxDataItem *)result
{
    OASGpxFile *doc = [self getGpxDocumentByGpx:result];
    [self setGPXRouteParamsWithDocument:doc path:doc.path];
}

- (OAApplicationMode *) getRouteMode
{
    OAApplicationMode *selected = _settings.applicationMode.get;
    OAApplicationMode *mode = _settings.defaultApplicationMode.get;
    if (selected != [OAApplicationMode DEFAULT])
    {
        mode = selected;
    }
    else if (mode == [OAApplicationMode DEFAULT])
    {
        mode = [OAApplicationMode CAR];
        if (_settings.lastRoutingApplicationMode && _settings.lastRoutingApplicationMode != [OAApplicationMode DEFAULT] && [OAApplicationMode.values containsObject:_settings.lastRoutingApplicationMode])
        {
            mode = _settings.lastRoutingApplicationMode;
        }
        else
        {
            mode = OAApplicationMode.getFirstAvailableNavigationMode;
        }
    }
    return mode;
}

- (void) setFirstMapMarkerAsTarget
{
    OADestinationsHelper *helper = [OADestinationsHelper instance];
    if (helper.sortedDestinations.count > 0)
    {
        OADestination *destination = helper.sortedDestinations[0];
        OAPointDescription *pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:destination.desc];
        OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
        [targets navigateToPoint:[[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude] updateRoute:YES intermediate:(int)[targets getIntermediatePoints].count + 1 historyName:pointDescription];
    }
}

- (void) stopNavigationWithoutConfirm
{
    [_app stopNavigation];
    [[OAWaypointHelper sharedInstance].deletedPoints removeAllObjects];
    [[OARootViewController instance].mapPanel recreateControls];
    [[OARootViewController instance].mapPanel refreshMap];
    
    NSArray<OAApplicationMode *> * modes = OAApplicationMode.allPossibleValues;
    for (OAApplicationMode *mode in modes)
    {
        if ([_settings.forcePrivateAccessRoutingAsked get:mode])
        {
            [_settings.forcePrivateAccessRoutingAsked set:NO mode:mode];
            OACommonBoolean *allowPrivate = [_settings getCustomRoutingBooleanProperty:@"allow_private" defaultValue:NO];
            [allowPrivate set:NO mode:mode];
        }
    }
}

- (void) stopNavigationActionConfirm
{
    [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"cancel_route")
                                               titleIcon:@"ic_custom_alert"
                                                 message:OALocalizedString(@"stop_routing_confirm")
                                             cancelTitle:OALocalizedString(@"shared_string_no")
                                               doneTitle:OALocalizedString(@"shared_string_yes")
                                        doneColpletition:^{
                                            [self stopNavigationWithoutConfirm];
                                        }];
}

- (void) navigate:(OATargetPoint *)targetPoint
{
    if ([OsmAndApp instance].locationServices.denied)
    {
        [OALocationServices showDeniedAlert];
        return;
    }
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    if (([routingHelper isFollowingMode] || [routingHelper isRoutePlanningMode]) && [targets getPointToNavigate])
        [[[OAAddWaypointBottomSheetViewController alloc] initWithTargetPoint:targetPoint] show];
    else
        [self startRoutePlanningWithDestination:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] pointDescription:targetPoint.pointDescription];
    
    [[OARootViewController instance].mapPanel targetHide];
}

- (void) startRoutePlanningWithDestination:(CLLocation *)latLon pointDescription:(OAPointDescription *)pointDescription
{
    BOOL hasPointToStart = [_app.data restorePointToStart];
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    [targets navigateToPoint:latLon updateRoute:YES intermediate:-1 historyName:pointDescription];
    if (!hasPointToStart)
    {
        [self enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
    }
    else
    {
        OARTargetPoint *start = [targets getPointToStart];
        if (start)
            [self enterRoutePlanningModeGivenGpx:nil from:start.point fromName:start.pointDescription useIntermediatePointsByDefault:YES showDialog:YES];
        else
            [self enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
    }
}

@end
