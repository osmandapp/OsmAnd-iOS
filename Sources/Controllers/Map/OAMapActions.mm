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
#import "PXAlertView.h"
#import "Localization.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAApplicationMode.h"
#import "OAMapSource.h"
#import "OARouteProvider.h"
#import "OAMapViewTrackingUtilities.h"
#import "OARootViewController.h"
#import "OAGPXDocument.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OATargetPoint.h"
#import "OAWaypointHelper.h"
#import "OAAddWaypointBottomSheetViewController.h"

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

- (void) enterRoutePlanningModeGivenGpx:(OAGPX *)gpxFile from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog
{
    [self enterRoutePlanningModeGivenGpx:[self getGpxDocumentByGpx:gpxFile] path:gpxFile.gpxFilePath from:from fromName:fromName useIntermediatePointsByDefault:useIntermediatePointsByDefault showDialog:showDialog];
}

- (void) enterRoutePlanningModeGivenGpx:(OAGPXDocument *)gpxFile path:(NSString *)path from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog
{
    _settings.useIntermediatePointsNavigation = useIntermediatePointsByDefault;
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    
    OAApplicationMode *mode = [self getRouteMode];
    [_routingHelper setAppMode:mode];
    [_app initVoiceCommandPlayer:mode warningNoneProvider:YES showDialog:NO force:NO];
    // save application mode controls
    _settings.followTheRoute = NO;
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
    {
        [_app showToastMessage:OALocalizedString(@"route_is_too_long_v2")];
    }
}

- (void) setGPXRouteParamsWithDocument:(OAGPXDocument *)doc path:(NSString *)path
{
    if (!doc)
    {
        [_routingHelper setGpxParams:nil];
        _settings.followTheGpxRoute = nil;
    }
    else
    {
        OAGPXRouteParamsBuilder *params = [[OAGPXRouteParamsBuilder alloc] initWithDoc:doc];
        if ([doc hasRtePt] && ![doc hasTrkPt])
            _settings.gpxCalculateRtept = true;
        else
            _settings.gpxCalculateRtept = false;
        
        [params setCalculateOsmAndRouteParts:_settings.gpxRouteCalcOsmandParts];
        [params setUseIntermediatePointsRTE:_settings.gpxCalculateRtept];
        [params setCalculateOsmAndRoute:_settings.gpxRouteCalc];
        [params setSelectedSegment:_settings.gpxRouteSegment];
        NSArray<CLLocation *> *ps = [params getPoints];
        [_routingHelper setGpxParams:params];
        _settings.followTheGpxRoute = path;
        if (ps.count > 0)
        {
            OATargetPointsHelper *tg = [OATargetPointsHelper sharedInstance];
            [tg clearStartPoint:NO];
            CLLocation *loc = ps.lastObject;
            [tg navigateToPoint:loc updateRoute:false intermediate:-1];
        }
    }
}

- (OAGPXDocument *) getGpxDocumentByGpx:(OAGPX *)gpx
{
    OAGPXDocument* doc = nil;
    const auto& gpxMap = [OASelectedGPXHelper instance].activeGpx;
    NSString * path;
    path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
    QString qPath = QString::fromNSString(path);
    if (gpxMap.contains(qPath))
    {
        auto geoDoc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(gpxMap[qPath]);
        doc = [[OAGPXDocument alloc] initWithGpxDocument:std::dynamic_pointer_cast<OsmAnd::GpxDocument>(geoDoc)];
        doc.path = path;
    }
    else
    {
        doc = [[OAGPXDocument alloc] initWithGpxFile:path];
    }
    return doc;
}

- (void) setGPXRouteParams:(OAGPX *)result
{
    OAGPXDocument* doc = [self getGpxDocumentByGpx:result];
    [self setGPXRouteParamsWithDocument:doc path:doc.path];
}


- (OAApplicationMode *) getRouteMode
{
    OAApplicationMode *selected = _settings.applicationMode;
    OAApplicationMode *mode = _settings.defaultApplicationMode.get;
    if (selected != [OAApplicationMode DEFAULT])
    {
        mode = selected;
    }
    else if (mode == [OAApplicationMode DEFAULT])
    {
        mode = [OAApplicationMode CAR];
        if (_settings.lastRoutingApplicationMode && _settings.lastRoutingApplicationMode != [OAApplicationMode DEFAULT])
        {
            mode = _settings.lastRoutingApplicationMode;
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
    [[OARootViewController instance].mapPanel refreshMap];

    //mapActivity.updateApplicationModeSettings();
    //mapActivity.getDashboard().clearDeletedPoints();
    /* TODO private routing
    List<ApplicationMode> modes = ApplicationMode.values(settings);
    for (ApplicationMode mode : modes) {
        if (settings.FORCE_PRIVATE_ACCESS_ROUTING_ASKED.getModeValue(mode)) {
            settings.FORCE_PRIVATE_ACCESS_ROUTING_ASKED.setModeValue(mode, false);
            settings.getCustomRoutingBooleanProperty(GeneralRouter.ALLOW_PRIVATE, false).setModeValue(mode, false);
        }
    }
     */
}

- (void) stopNavigationActionConfirm
{
    [PXAlertView showAlertWithTitle:OALocalizedString(@"cancel_route")
                            message:OALocalizedString(@"stop_routing_confirm")
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                          otherDesc:nil
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 [self stopNavigationWithoutConfirm];
                             }
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
