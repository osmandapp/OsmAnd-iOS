//
//  OACarPlayDashboardInterfaceController.m
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayDashboardInterfaceController.h"
#import "OADirectionsGridController.h"
#import "OARoutingHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAObservable.h"
#import "OAMapViewController.h"
#import "Localization.h"
#import "OALocationServices.h"
#import "OsmAndApp.h"
#import "OARouteCalculationResult.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OsmAndAppImpl.h"
#import "OAAutoObserverProxy.h"
#import "OARouteDirectionInfo.h"
#import "OAMapActions.h"
#import "OALocationSimulation.h"
#import "OACommonTypes.h"
#import "OAOsmAndFormatter.h"
#import "OALanesDrawable.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAPlugin.h"
#import "OASRTMPlugin.h"
#import "OATurnDrawable.h"
#import "OATurnDrawable+cpp.h"
#import "OAMapButtonsHelper.h"
#import "OACurrentStreetName.h"
#import "OAVoiceRouter.h"
#import "OAAnnounceTimeDistances.h"
#import "OsmAnd_Maps-Swift.h"

#define unitsKm OALocalizedString(@"km")
#define unitsM OALocalizedString(@"m")
#define unitsMi OALocalizedString(@"mile")
#define unitsYd OALocalizedString(@"yard")
#define unitsFt OALocalizedString(@"foot")
#define unitsNm OALocalizedString(@"nm")

typedef NS_ENUM(NSInteger, EOACarPlayButtonType) {
    EOACarPlayButtonTypeDismiss = 0,
    EOACarPlayButtonTypePanMap,
    EOACarPlayButtonTypeSearch,
    EOACarPlayButtonTypeZoomIn,
    EOACarPlayButtonTypeZoomOut,
    EOACarPlayButtonTypeCenterMap,
    EOACarPlayButtonTypeDirections,
    EOACarPlayButtonTypeRouteCalculation,
    EOACarPlayButtonTypeCancelRoute,
    EOACarPlayButtonType3D
};

@interface OACarPlayDashboardInterfaceController() <CPMapTemplateDelegate, OARouteInformationListener, OARouteCalculationProgressCallback>

@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) CPNavigationSession *navigationSession;
@property (nonatomic) OARoutingHelper *routingHelper;
@property (nonatomic) OALanesDrawable *lanesDrawable;
@property (nonatomic) CPManeuverDisplayStyle secondaryStyle;
@property (nonatomic) OAAnnounceTimeDistances *timeDistances;

@end

@implementation OACarPlayDashboardInterfaceController
{
    CPMapTemplate *_mapTemplate;
    CPTrip *_currentTrip;
    
    BOOL _isInRouteCalculation;
    BOOL _isInRoutePreview;
    
    int _calculationProgress;

    CPMapButton *_3DModeMapButton;
    BOOL _wasIn3DBeforePreview;

    OAAutoObserverProxy *_locationUpdateObserver;
    OAAutoObserverProxy *_map3DModeObserver;
    OANextDirectionInfo *_currentDirectionInfo;
    
    UIColor *_lightGuidanceBackgroundColor;
    UIColor *_darkGuidanceBackgroundColor;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _routingHelper = OARoutingHelper.sharedInstance;
    [_routingHelper addListener:self];
    [_routingHelper addCalculationProgressCallback:self];
    _lanesDrawable = [[OALanesDrawable alloc] initWithScaleCoefficient:10.];
    _secondaryStyle = CPManeuverDisplayStyleDefault;
    _lightGuidanceBackgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.984 alpha:1.0];
    _darkGuidanceBackgroundColor = [UIColor colorWithRed:0.231 green:0.231 blue:0.231 alpha:1.0];
}

- (void) stopNavigation
{
    [OARootViewController.instance.mapPanel.mapActions stopNavigationWithoutConfirm];
    OsmAndAppInstance app = OsmAndApp.instance;
    if (_settings.simulateNavigation && [app.locationServices.locationSimulation isRouteAnimating])
        [app.locationServices.locationSimulation startStopRouteAnimation];
}

- (void) present
{
    // Dismiss any previous navigation
    
    [[OARootViewController instance].mapPanel closeRouteInfo];
    
    _mapTemplate = [[CPMapTemplate alloc] init];
    _mapTemplate.mapDelegate = self;
    [self onUpdateMapTemplateStyle];
    [self enterBrowsingState];
    
    [self.interfaceController setRootTemplate:_mapTemplate animated:YES completion:nil];
}

- (void) onTripStartTriggered
{
    if (_isInRoutePreview)
    {
        CPRouteChoice *routeChoice = [[CPRouteChoice alloc] initWithSummaryVariants:@[] additionalInformationVariants:@[] selectionSummaryVariants:@[]];
        [self mapTemplate:_mapTemplate startedTrip:_currentTrip usingRouteChoice:routeChoice];
    }
}

- (void) enterBrowsingState
{
    _isInRouteCalculation = NO;
    _isInRoutePreview = NO;
    
    CPBarButton *panningButton = [self createBarButton:EOACarPlayButtonTypePanMap];
    _mapTemplate.trailingNavigationBarButtons = @[panningButton];
    _mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeDirections]];

    _3DModeMapButton = [self createMapButton:EOACarPlayButtonType3D];
    _mapTemplate.mapButtons = @[_3DModeMapButton, [self createMapButton:EOACarPlayButtonTypeCenterMap], [self createMapButton:EOACarPlayButtonTypeZoomIn], [self createMapButton:EOACarPlayButtonTypeZoomOut]];
    [self onMap3dModeUpdated];
}

- (void) enterRoutePreviewMode
{
    if ([[OAMapViewTrackingUtilities instance] is3DMode])
        _wasIn3DBeforePreview = YES;

    [OAOsmAndFormatter getFormattedTimeHM:_routingHelper.getLeftTime];
    CPRouteChoice *routeChoice = [[CPRouteChoice alloc] initWithSummaryVariants:@[] additionalInformationVariants:@[] selectionSummaryVariants:@[]];
    
    OATargetPointsHelper *targetHelper = OATargetPointsHelper.sharedInstance;
    
    OARTargetPoint* start = targetHelper.getPointToStart;
    OARTargetPoint* finish = targetHelper.getPointToNavigate;
    CLLocation *lastKnownLocation = OsmAndApp.instance.locationServices.lastKnownLocation;
    
    CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(start != nil ? start.getLatitude : lastKnownLocation.coordinate.latitude, start != nil ? start.getLongitude : lastKnownLocation.coordinate.longitude);
    
    CLLocationCoordinate2D finishCoord = CLLocationCoordinate2DMake(finish.getLatitude, finish.getLongitude);
    
    MKMapItem *startItem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:startCoord]];
    MKMapItem *finishItem = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:finishCoord]];
    
    startItem.name = OALocalizedString(@"shared_string_my_location");
    finishItem.name = finish.pointDescription.name;
    
    _currentTrip = [[CPTrip alloc] initWithOrigin:startItem destination:finishItem routeChoices:@[routeChoice]];
    
    CPTripPreviewTextConfiguration *config = [[CPTripPreviewTextConfiguration alloc] initWithStartButtonTitle:OALocalizedString(@"shared_string_control_start") additionalRoutesButtonTitle:nil overviewButtonTitle:nil];
    
    [_mapTemplate showTripPreviews:@[_currentTrip] textConfiguration:config];
    _mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeCancelRoute]];
    
    _isInRoutePreview = YES;
    
    if (![_routingHelper isFollowingMode])
    	[self centerMapOnRoute];
    if (_delegate)
        [_delegate enterNavigationMode];
}

- (void)exitNavigationMode
{
    _currentDirectionInfo = nil;
    _currentTrip = nil;
    [_navigationSession finishTrip];
    _navigationSession = nil;
    [_mapTemplate hideTripPreviews];
    if (_delegate)
        [_delegate exitNavigationMode];
    [self enterBrowsingState];
}

- (void) centerMapOnRoute
{
    if ([_routingHelper isRouteCalculated])
    {
        OABBox routeBBox = [_routingHelper getBBox];
        CLLocationCoordinate2D topLeft = CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left);
        CLLocationCoordinate2D bottomRight = CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right);
        if (_delegate)
            [_delegate centerMapOnRoute:topLeft bottomRight:bottomRight];
    }
}

- (void)returnTo3dMode
{
    if (_wasIn3DBeforePreview && ![[OAMapViewTrackingUtilities instance] is3DMode])
    {
        _wasIn3DBeforePreview = NO;
        [[OAMapViewTrackingUtilities instance] switchMap3dMode];
    }
}

- (void)openSearch
{
    OADirectionsGridController *directionsGrid = [[OADirectionsGridController alloc] initWithInterfaceController:self.interfaceController];
    [directionsGrid present];
    [directionsGrid openSearch];
}

- (void)openNavigation {
    OADirectionsGridController *directionsGrid = [[OADirectionsGridController alloc] initWithInterfaceController:self.interfaceController];
    [directionsGrid present];
}

- (void)onMap3dModeUpdated
{
    if (_3DModeMapButton)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            OAMapViewTrackingUtilities *mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
            Map3DModeVisibility map3DMode = [[[OAMapButtonsHelper sharedInstance] getMap3DButtonState] getVisibility];
            BOOL hideButton = map3DMode == Map3DModeVisibilityHidden
                || (map3DMode == Map3DModeVisibilityVisibleIn3DMode && ![mapViewTrackingUtilities is3DMode]);
            _3DModeMapButton.hidden = hideButton ? YES : NO;
            if ([mapViewTrackingUtilities is3DMode])
            {
                _3DModeMapButton.image = [UIImage imageNamed:@"btn_map_2d_mode"];
                _3DModeMapButton.accessibilityLabel = OALocalizedString(@"map_3d_mode_action");
            }
            else
            {
                _3DModeMapButton.image = [UIImage imageNamed:@"btn_map_3d_mode"];
                _3DModeMapButton.accessibilityLabel = OALocalizedString(@"map_2d_mode_action");
            }
            _3DModeMapButton.accessibilityValue = [Map3DModeVisibilityWrapper getTitleForType:map3DMode];
        });
    }
}

- (void)onProfileSettingSet:(NSNotification *)notification
{
    if (notification.object == [[OAMapButtonsHelper sharedInstance] getMap3DButtonState].visibilityPref)
        [self onMap3dModeUpdated];
}

- (CPMapButton *) createMapButton:(EOACarPlayButtonType)type
{
    CPMapButton *mapButton = [[CPMapButton alloc] initWithHandler:^(CPMapButton * _Nonnull mapButton) {
        switch (type) {
            case EOACarPlayButtonTypeZoomIn: {
                if (_delegate)
                    [_delegate onZoomInPressed];
                break;
            }
            case EOACarPlayButtonTypeZoomOut: {
                if (_delegate)
                    [_delegate onZoomOutPressed];
                break;
            }
            case EOACarPlayButtonTypeCenterMap: {
                if (_delegate)
                    [_delegate onCenterMapPressed];
                break;
            }
            case EOACarPlayButtonType3D: {
                if (_delegate)
                    [_delegate on3DMapPressed];
                break;
            }
            default:
                break;
        }
    }];
    
    if (type == EOACarPlayButtonTypeZoomIn)
        mapButton.image = [UIImage imageNamed:@"btn_map_zoom_in"];
    else if (type == EOACarPlayButtonTypeZoomOut)
        mapButton.image = [UIImage imageNamed:@"btn_map_zoom_out"];
    else if (type == EOACarPlayButtonTypeCenterMap)
        mapButton.image = [UIImage imageNamed:@"btn_map_current_location"];
    else if (type == EOACarPlayButtonType3D)
        mapButton.image = [UIImage imageNamed:[OAMapViewTrackingUtilities.instance is3DMode] ? @"btn_map_2d_mode" : @"btn_map_3d_mode"];
    
    return mapButton;
}

- (CPBarButton *) createBarButton:(EOACarPlayButtonType)type
{
    CPBarButtonHandler handler = ^(CPBarButton * _Nonnull button) {
        switch(type)
        {
            case EOACarPlayButtonTypeDismiss:
            {
                // Dismiss the map panning interface
                [_mapTemplate dismissPanningInterfaceAnimated:YES];
                break;
            }
            case EOACarPlayButtonTypePanMap:
            {
                // Enable the map panning interface and set the dismiss button
                [_mapTemplate showPanningInterfaceAnimated:YES];
                break;
            }
            case EOACarPlayButtonTypeDirections:
            {
                [self openNavigation];
                break;
            }
            case EOACarPlayButtonTypeCancelRoute:
            {
                [self stopNavigation];
                if (_delegate)
                    [_delegate exitNavigationMode];
                [_mapTemplate hideTripPreviews];
                [self enterBrowsingState];
                [self returnTo3dMode];
                break;
            }
            default:
            {
                break;
            }
        }
    };

    NSString *title = @"";
    UIImage *icon;

    if (type == EOACarPlayButtonTypePanMap)
        icon = [UIImage imageNamed:@"ic_custom_change_object_position"];
    else if (type == EOACarPlayButtonTypeDismiss)
        title = OALocalizedString(@"shared_string_done");
    else if (type == EOACarPlayButtonTypeDirections)
        title = OALocalizedString(@"shared_string_navigation");
    else if (type == EOACarPlayButtonTypeRouteCalculation)
        title = [NSString stringWithFormat:OALocalizedString(@"route_calc_progress"), 0];
    else if (type == EOACarPlayButtonTypeCancelRoute)
        title = OALocalizedString(@"shared_string_cancel");

    return icon ? [[CPBarButton alloc] initWithImage:icon handler:handler] : [[CPBarButton alloc] initWithTitle:title handler:handler];
}

- (CPBarButtonType) getButtonType:(EOACarPlayButtonType)type
{
    switch (type) {
        case EOACarPlayButtonTypeSearch:
        case EOACarPlayButtonTypePanMap:
            return CPBarButtonTypeImage;
        case EOACarPlayButtonTypeDismiss:
        case EOACarPlayButtonTypeDirections:
        case EOACarPlayButtonTypeCancelRoute:
        case EOACarPlayButtonTypeRouteCalculation:
            return CPBarButtonTypeText;
            
        default:
            return CPBarButtonTypeImage;
    }
}

- (void) enterRouteCalculationMode
{
    _mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeRouteCalculation], [self createBarButton:EOACarPlayButtonTypeCancelRoute]];
    _isInRouteCalculation = YES;
}

// MARK: - CPMapTemplate delegate method

- (void)mapTemplateDidShowPanningInterface:(CPMapTemplate *)mapTemplate
{
    _mapTemplate.trailingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeDismiss]];
    _mapTemplate.mapButtons = @[[self createMapButton:EOACarPlayButtonTypeZoomIn], [self createMapButton:EOACarPlayButtonTypeZoomOut]];
    _mapTemplate.leadingNavigationBarButtons = @[];
}

- (void)mapTemplateDidDismissPanningInterface:(CPMapTemplate *)mapTemplate
{
    if (_isInRouteCalculation)
        [self enterRouteCalculationMode];
    else if (_navigationSession || _isInRoutePreview)
        _mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeCancelRoute]];
    else
        [self enterBrowsingState];
    
    _mapTemplate.trailingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypePanMap]];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate panWithDirection:(CPPanDirection)direction
{
    if (_delegate)
        [_delegate onMapControlPressed:direction];
}

- (void)updateTripEstimates:(CPTrip * _Nonnull)trip
{
    CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:[self getFormattedDistance:_routingHelper.getLeftDistance] timeRemaining:(NSTimeInterval)_routingHelper.getLeftTime];
    [_mapTemplate updateTravelEstimates:estimates forTrip:trip];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate selectedPreviewForTrip:(CPTrip *)trip usingRouteChoice:(CPRouteChoice *)routeChoice
{
    [self updateTripEstimates:trip];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate startedTrip:(CPTrip *)trip usingRouteChoice:(CPRouteChoice *)routeChoice
{
    [mapTemplate hideTripPreviews];
    _isInRoutePreview = NO;
    
    _navigationSession = [_mapTemplate startNavigationSessionForTrip:trip];
    [self returnTo3dMode];
    [[OARootViewController instance].mapPanel startNavigation];
}

- (void)mapTemplateDidBeginPanGesture:(CPMapTemplate *)mapTemplate
{
    [self postMapGestureAction];
    [[OARootViewController instance].mapPanel.mapViewController carPlayMoveGestureDetected:UIGestureRecognizerStateBegan numberOfTouches:1 translation:CGPointZero velocity:CGPointZero];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate didUpdatePanGestureWithTranslation:(CGPoint)translation velocity:(CGPoint)velocity
{
    [[OARootViewController instance].mapPanel.mapViewController carPlayMoveGestureDetected:UIGestureRecognizerStateChanged numberOfTouches:1 translation:translation velocity:velocity];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate didEndPanGestureWithVelocity:(CGPoint)velocity
{
    [[OARootViewController instance].mapPanel.mapViewController carPlayMoveGestureDetected:UIGestureRecognizerStateEnded numberOfTouches:1 translation:CGPointZero velocity:velocity];
}

- (void) postMapGestureAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationMapGestureAction
                                                        object:[OARootViewController instance].mapPanel.mapViewController
                                                      userInfo:nil];
}

- (CPManeuverDisplayStyle)mapTemplate:(CPMapTemplate *)mapTemplate displayStyleForManeuver:(CPManeuver *)maneuver
{
    return _secondaryStyle;
}

// MARK: - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    if (newRoute)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _isInRouteCalculation = NO;
            [self enterRoutePreviewMode];
        });
    }
}

- (void) routeWasUpdated
{
    
}

- (void) routeWasCancelled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self exitNavigationMode];
    });
}

- (void) routeWasFinished
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self exitNavigationMode];
    });
}

// MARK: - OARouteCalculationProgressCallback

- (void) startProgress
{
    [self enterRouteCalculationMode];
}

- (void) updateProgress:(int)progress
{
    if (!_isInRouteCalculation)
    {
        [self enterRouteCalculationMode];
        _calculationProgress = 0;
    }
    
    // Make progress more consistent
    if (_calculationProgress < 49 && progress > 0)
        _calculationProgress = (progress + 1) / 2;
    else
        _calculationProgress = 50 + progress / 2;
    
    CPBarButton *navButton = _mapTemplate.leadingNavigationBarButtons.firstObject;
    navButton.title = [NSString stringWithFormat:OALocalizedString(@"route_calc_progress"), _calculationProgress];
}

- (void) requestPrivateAccessRouting
{
}

- (void) finish
{
}

// MARK: distance formatting methods

- (NSMeasurement<NSUnitLength *> *) getFormattedDistance:(int)meters
{
    NSString *distString = [OAOsmAndFormatter getFormattedDistance:meters withParams:[OsmAndFormatterParams useLowerBounds]];
    NSArray<NSString *> *components = [distString componentsSeparatedByString:@" "];
    if (components.count == 2)
        return [[NSMeasurement alloc] initWithDoubleValue:components.firstObject.doubleValue unit:[self getUnitByString:components.lastObject]];
    return nil;
}

- (NSUnitLength *) getUnitByString:(NSString *)unitStr
{
    if ([unitStr isEqualToString:unitsM])
        return NSUnitLength.meters;
    else if ([unitStr isEqualToString:unitsKm])
        return NSUnitLength.kilometers;
    else if ([unitStr isEqualToString:unitsMi])
        return NSUnitLength.miles;
    else if ([unitStr isEqualToString:unitsYd])
        return NSUnitLength.yards;
    else if ([unitStr isEqualToString:unitsFt])
        return NSUnitLength.feet;
    else if ([unitStr isEqualToString:unitsNm])
        return NSUnitLength.nauticalMiles;
    
    return NSUnitLength.meters;
}

- (NSString *)defineStreetName
{
    OANextDirectionInfo *directionInfo = [_routingHelper getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] toSpeak:YES];
    return [self defineStreetName:directionInfo];
}

- (NSString *)defineStreetName:(OANextDirectionInfo *)nextDirInfo
{
    if (nextDirInfo)
    {
        OACurrentStreetName *currentStreetName = [[OACurrentStreetName alloc] initWithStreetName:nextDirInfo];
        NSString *streetName = currentStreetName.text;
        if (streetName.length > 0)
        {
            NSString *exitRef = currentStreetName.exitRef;
            return exitRef.length == 0
                ? streetName
                : [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_comma"), exitRef, streetName];
        }
    }
    return @"";
}

// MARK: Location updates

- (void)onLocationUpdate
{
    OACarPlayDashboardInterfaceController * __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.navigationSession)
        {
            NSMutableArray<CPManeuver *> *upcomingManeuvers = [NSMutableArray array];
            CPManeuver *maneuver = [[CPManeuver alloc] init];
            std::shared_ptr<TurnType> turnType;
            std::shared_ptr<TurnType> nextTurnType;
            BOOL leftSide = [OADrivingRegion isLeftHandDriving:[weakSelf.settings.drivingRegion get]];
            BOOL deviatedFromRoute = [OARoutingHelper isDeviatedFromRoute];
            int turnImminent = 0;
            int nextTurnDistance = 0;
            OANextDirectionInfo *nextDirInfo;
            OANextDirectionInfo *nextNextDirInfo;
            OANextDirectionInfo *calc = [[OANextDirectionInfo alloc] init];
            if (deviatedFromRoute)
            {
                turnType = TurnType::ptrValueOf(TurnType::OFFR, leftSide);
                nextTurnDistance = [weakSelf.routingHelper getRouteDeviation];
            }
            else
            {
                nextDirInfo = [weakSelf.routingHelper getNextRouteDirectionInfo:calc toSpeak:YES];
                if (nextDirInfo && nextDirInfo.distanceTo >= 0 && nextDirInfo.directionInfo)
                {
                    turnType = nextDirInfo.directionInfo.turnType;
                    nextTurnDistance = nextDirInfo.distanceTo;
                    turnImminent = nextDirInfo.imminent;
                }
            }

            if (turnType)
            {
                UIUserInterfaceStyle style = weakSelf.interfaceController.carTraitCollection.userInterfaceStyle;
                EOATurnDrawableThemeColor themeColor = style == UIUserInterfaceStyleDark
                    ? EOATurnDrawableThemeColorDark
                    : EOATurnDrawableThemeColorLight;
                OATurnDrawable *drawable = [[OATurnDrawable alloc] initWithMini:NO themeColor:themeColor];
                [drawable setTurnType:turnType];
                [drawable setTurnImminent:turnImminent deviatedFromRoute:deviatedFromRoute];
                drawable.textFont = [UIFont scaledSystemFontOfSize:16 weight:UIFontWeightSemibold];
                CGFloat size = MAX(drawable.pathForTurn.bounds.origin.x + drawable.pathForTurn.bounds.size.width,
                                   drawable.pathForTurn.bounds.origin.y + drawable.pathForTurn.bounds.size.height);
                drawable.frame = CGRectMake(0, 0, size, size);
                [drawable setNeedsDisplay];
                UIImage *turnImage = [drawable toUIImage];
                maneuver.symbolImage = turnImage;
            }

            OAAnnounceTimeDistances *atd = weakSelf.routingHelper.getVoiceRouter.getAnnounceTimeDistances;
            if (nextDirInfo && atd)
            {
                float speed = [atd getSpeed:[weakSelf.routingHelper getLastFixedLocation]];
                int dist = nextDirInfo.distanceTo;
                nextNextDirInfo = [weakSelf.routingHelper getNextRouteDirectionInfoAfter:nextDirInfo to:[[OANextDirectionInfo alloc] init] toSpeak:YES];
                nextTurnType = [weakSelf getNextTurnType:atd info:nextNextDirInfo speed:speed distance:dist];
            }

            maneuver.instructionVariants = @[
                [weakSelf getNextTurnDescription:nextDirInfo turnType:turnType nextTurnType:nextTurnType]
            ];

            CPManeuver *secondaryManeuver;
            nextDirInfo = [weakSelf.routingHelper getNextRouteDirectionInfo:calc toSpeak:NO];
            if (nextDirInfo && nextDirInfo.directionInfo && nextDirInfo.directionInfo.turnType)
            {
                auto lanes = nextDirInfo.directionInfo.turnType->getLanes();
                int locimminent = nextDirInfo.imminent;
                if (!weakSelf.timeDistances || weakSelf.timeDistances.appMode != [weakSelf.routingHelper getAppMode])
                    weakSelf.timeDistances = [[OAAnnounceTimeDistances alloc] initWithAppMode:[weakSelf.routingHelper getAppMode]];
                            
                // Do not show too far
                // (nextTurnDistance != nextDirInfo.distanceTo && nextDirInfo.distanceTo > 150))
                if (nextDirInfo.directionInfo.turnType == nullptr || [weakSelf.timeDistances tooFarToDisplayLanes:nextDirInfo.directionInfo.turnType->isSkipToSpeak() distanceTo:nextDirInfo.distanceTo])
                    lanes.clear();

                if (!lanes.empty())
                {
                    [weakSelf.lanesDrawable setLanes:lanes];
                    weakSelf.lanesDrawable.imminent = locimminent == 0;
                    [weakSelf.lanesDrawable updateBounds];
                    weakSelf.lanesDrawable.frame = CGRectMake(0, 0, weakSelf.lanesDrawable.width, weakSelf.lanesDrawable.height);
                    [weakSelf.lanesDrawable setNeedsDisplay];
                    UIImage *lanesImg = [weakSelf.lanesDrawable toUIImage];
                    secondaryManeuver = [[CPManeuver alloc] init];
                    secondaryManeuver.symbolImage = lanesImg;
                    secondaryManeuver.instructionVariants = @[];
                    weakSelf.secondaryStyle = CPManeuverDisplayStyleSymbolOnly;

                    NSMutableArray<NSNumber *> *userInfo = [NSMutableArray array];
                    for (int i = 0; i < lanes.size(); i++)
                    {
                        [userInfo addObject:@(lanes[i])];
                    }
                    secondaryManeuver.userInfo = @{ @"lanes": userInfo };
                }
            }

            if (!deviatedFromRoute)
            {
                NSString *streetName = [weakSelf defineStreetName];
                if (streetName.length > 0)
                    weakSelf.navigationSession.currentRoadNameVariants = @[streetName];
                else
                    weakSelf.navigationSession.currentRoadNameVariants = @[];
            }

            NSMeasurement<NSUnitLength *> *dist = [weakSelf getFormattedDistance:nextTurnDistance];
            long leftTurnTimeSec = [weakSelf.routingHelper getLeftTimeNextTurn];
            CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:dist timeRemaining:leftTurnTimeSec];
            maneuver.initialTravelEstimates = estimates;
            maneuver.userInfo = @{
                @"streetName": maneuver.instructionVariants.firstObject ?: @"",
                @"turnType": turnType ? [NSString stringWithUTF8String:turnType->toString().c_str()] : @"",
                @"turnImminent": turnType ? @(turnImminent) : @(-1),
                @"deviatedFromRoute": turnType ? @(deviatedFromRoute) : @(NO),
            };
            [upcomingManeuvers addObject:maneuver];

            UIImage *nextTurnImage;
            if (nextNextDirInfo && nextNextDirInfo.distanceTo > 0 && nextNextDirInfo.imminent >= 0 && nextNextDirInfo.directionInfo)
            {
                nextTurnType = nextNextDirInfo.directionInfo.turnType;
                if (!secondaryManeuver && nextTurnType)
                {
                    UIUserInterfaceStyle style = weakSelf.interfaceController.carTraitCollection.userInterfaceStyle;
                    EOATurnDrawableThemeColor themeColor = style == UIUserInterfaceStyleDark
                        ? EOATurnDrawableThemeColorDark
                        : EOATurnDrawableThemeColorLight;
                    OATurnDrawable *drawable = [[OATurnDrawable alloc] initWithMini:NO
                                                                         themeColor:themeColor];
                    const auto& turnType = nextNextDirInfo.directionInfo.turnType;
                    [drawable setTurnType:nextTurnType];
                    [drawable setTurnImminent:nextNextDirInfo.imminent
                            deviatedFromRoute:deviatedFromRoute];
                    drawable.textFont = [UIFont scaledSystemFontOfSize:16 weight:UIFontWeightSemibold];
                    CGFloat size = MAX(drawable.pathForTurn.bounds.origin.x + drawable.pathForTurn.bounds.size.width,
                                       drawable.pathForTurn.bounds.origin.y + drawable.pathForTurn.bounds.size.height);
                    drawable.frame = CGRectMake(0, 0, size, size);
                    [drawable setNeedsDisplay];
                    nextTurnImage = [drawable toUIImage];
                    secondaryManeuver = [[CPManeuver alloc] init];
                    weakSelf.secondaryStyle = CPManeuverDisplayStyleDefault;

                    std::shared_ptr<TurnType> nextNextTurnType;
                    OAAnnounceTimeDistances *atd = weakSelf.routingHelper.getVoiceRouter.getAnnounceTimeDistances;
                    if (atd)
                    {
                        float speed = [atd getSpeed:[weakSelf.routingHelper getLastFixedLocation]];
                        OANextDirectionInfo *info = [weakSelf.routingHelper getNextRouteDirectionInfoAfter:nextNextDirInfo to:[[OANextDirectionInfo alloc] init] toSpeak:YES];
                        nextNextTurnType = [weakSelf getNextTurnType:atd info:info speed:speed distance:nextNextDirInfo.distanceTo];
                    }
                    NSString *nextStreetName = [weakSelf getSecondNextTurnDescription:nextNextDirInfo turnType:nextTurnType nextTurnType:nextNextTurnType];
                    secondaryManeuver.userInfo = @{
                        @"streetName": nextStreetName,
                    };

                    NSString *distanceString = [OAOsmAndFormatter getFormattedDistance:nextNextDirInfo.distanceTo
                                                                            withParams:[OsmAndFormatterParams useLowerBounds]];
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
                    if (nextTurnImage)
                    {
                        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                        attachment.image = [OAUtilities resizeImage:nextTurnImage
                                                            newSize:CGSizeMake(16, 16)];
                        [attributedString appendAttributedString:
                            [NSAttributedString attributedStringWithAttachment:attachment]];
                    }
                    if (nextStreetName.length > 0)
                        [attributedString appendAttributedString:
                         [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",
                                                                     nextStreetName]]];
                    else
                        [attributedString appendAttributedString:
                         [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",
                                                                     distanceString]]];

                    secondaryManeuver.attributedInstructionVariants = @[attributedString];
                }
            }

            if (secondaryManeuver)
                [upcomingManeuvers addObject:secondaryManeuver];

            BOOL needToUpdate = weakSelf.navigationSession.upcomingManeuvers.count != upcomingManeuvers.count;
            if (!needToUpdate)
            {
                CPManeuver *firstMan = weakSelf.navigationSession.upcomingManeuvers.firstObject;
                CPManeuver *lastMan = weakSelf.navigationSession.upcomingManeuvers.lastObject;
                needToUpdate = ![((NSDictionary *) firstMan.userInfo) isEqualToDictionary:maneuver.userInfo];
                if (!needToUpdate && secondaryManeuver)
                    needToUpdate = ![((NSDictionary *) lastMan.userInfo) isEqualToDictionary:secondaryManeuver.userInfo];
            }
            if (needToUpdate)
            {
                weakSelf.navigationSession.upcomingManeuvers = upcomingManeuvers;
                [weakSelf.navigationSession updateTravelEstimates:estimates forManeuver:maneuver];
            }
            else if (weakSelf.navigationSession.upcomingManeuvers.count > 0)
            {
                [weakSelf.navigationSession updateTravelEstimates:estimates forManeuver:weakSelf.navigationSession.upcomingManeuvers.firstObject];
            }
            [weakSelf updateTripEstimates:weakSelf.navigationSession.trip];
        }
    });
    [self.delegate onLocationChanged];
}

- (std::shared_ptr<TurnType>) getNextTurnType:(OAAnnounceTimeDistances *)atd info:(OANextDirectionInfo *)info speed:(float)speed distance:(int)distance
{
    if ([atd isTurnStateActive:speed dist:distance turnType:kStateTurnIn])
    {
        if (info && info.directionInfo &&
            ([atd isTurnStateActive:speed dist:info.distanceTo turnType:kStateTurnNow]
             || ![atd isTurnStateNotPassed:speed dist:info.distanceTo turnType:kStateTurnIn]))
            return info.directionInfo.turnType;
    }
    return nullptr;
}

- (BOOL) shouldKeepLeft:(const std::shared_ptr<TurnType>&)type
{
    return type && TurnType::isLeftTurn(type->getValue());
}

- (BOOL) shouldKeepRight:(const std::shared_ptr<TurnType>&)type
{
    return type && TurnType::isRightTurn(type->getValue());
}

- (NSString *) nextTurnsToString:(const std::shared_ptr<TurnType>&)type nextTurnType:(const std::shared_ptr<TurnType>&)nextTurnType
{
    if (type->isRoundAbout())
    {
        if ([self shouldKeepLeft:nextTurnType])
            return [NSString stringWithFormat:OALocalizedString(@"auto_25_chars_route_roundabout_kl"), type->getExitOut()];
        else if ([self shouldKeepRight:nextTurnType])
            return [NSString stringWithFormat:OALocalizedString(@"auto_25_chars_route_roundabout_kr"), type->getExitOut()];
        else
            return [NSString stringWithFormat:OALocalizedString(@"route_roundabout_exit"), type->getExitOut()];
    }
    else if (type->getValue() == TurnType::TU || type->getValue() == TurnType::TRU)
    {
        if ([self shouldKeepLeft:nextTurnType])
            return OALocalizedString(@"auto_25_chars_route_tu_kl");
        else if ([self shouldKeepRight:nextTurnType])
            return OALocalizedString(@"auto_25_chars_route_tu_kr");
        else
            return OALocalizedString(@"auto_25_chars_route_tu");
    }
    else if (type->getValue() == TurnType::C)
    {
        return OALocalizedString(@"route_head");
    }
    else if (type->getValue() == TurnType::TSLL)
    {
        return OALocalizedString(@"auto_25_chars_route_tsll");
    }
    else if (type->getValue() == TurnType::TL)
    {
        if ([self shouldKeepLeft:nextTurnType])
            return OALocalizedString(@"auto_25_chars_route_tl_kl");
        else if ([self shouldKeepRight:nextTurnType])
            return OALocalizedString(@"auto_25_chars_route_tl_kr");
        else
            return OALocalizedString(@"auto_25_chars_route_tl");
    }
    else if (type->getValue() == TurnType::TSHL)
    {
        return OALocalizedString(@"auto_25_chars_route_tshl");
    }
    else if (type->getValue() == TurnType::TSLR)
    {
        return OALocalizedString(@"auto_25_chars_route_tslr");
    }
    else if (type->getValue() == TurnType::TR)
    {
        if ([self shouldKeepLeft:nextTurnType])
            return OALocalizedString(@"auto_25_chars_route_tr_kl");
        else if ([self shouldKeepRight:nextTurnType])
            return OALocalizedString(@"auto_25_chars_route_tr_kr");
        else
            return OALocalizedString(@"auto_25_chars_route_tr");
    }
    else if (type->getValue() == TurnType::TSHR)
    {
        return OALocalizedString(@"auto_25_chars_route_tshr");
    }
    else if (type->getValue() == TurnType::KL)
    {
        return OALocalizedString(@"auto_25_chars_route_kl");
    }
    else if (type->getValue() == TurnType::KR)
    {
        return OALocalizedString(@"auto_25_chars_route_kr");
    }
    return @"";
}

- (NSString *) getNextTurnDescription:(OANextDirectionInfo *)info turnType:(const std::shared_ptr<TurnType>&)turnType nextTurnType:(const std::shared_ptr<TurnType>&)nextTurnType
{
    NSString *description = [self getTurnDescription:info];
    NSString *turnName = turnType ? [self nextTurnsToString:turnType nextTurnType:nextTurnType] : @"";

    if (turnType && turnType->isRoundAbout() && description.length > 0)
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_comma"), turnName, description];
    
    return description.length > 0 ? description : turnName;
}

- (NSString *) getSecondNextTurnDescription:(OANextDirectionInfo *)info turnType:(const std::shared_ptr<TurnType>&)turnType nextTurnType:(const std::shared_ptr<TurnType>&)nextTurnType
{
    NSString *description = [self getTurnDescription:info];
    NSString *distance = [OAOsmAndFormatter getFormattedDistance:info.distanceTo withParams:OsmAndFormatterParams.useLowerBounds];

    if (description.length == 0)
        description = turnType ? [self nextTurnsToString:turnType nextTurnType:nextTurnType] : nil;
    
    return description.length == 0 ? distance : [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_comma"), distance, description];
}

- (NSString *) getTurnDescription:(OANextDirectionInfo *)info
{
    NSString *name = [self defineStreetName:info];
    NSString *ref = info && info.directionInfo ? info.directionInfo.ref : @"";
    return name.length > 0 ? name : ref;
}

// MARK: OACarPlayMapViewDelegate

- (void)onInterfaceControllerAttached
{
    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onLocationUpdate)
                                                         andObserve:[OsmAndApp instance].locationServices.updateLocationObserver];
    _map3DModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                   withHandler:@selector(onMap3dModeUpdated)
                                                    andObserve:[OARootViewController instance].mapPanel.mapViewController.elevationAngleObservable];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onTripStartTriggered) name:kCarPlayTripStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
}

- (void)onInterfaceControllerDetached
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
    if (_map3DModeObserver)
    {
        [_map3DModeObserver detach];
        _map3DModeObserver = nil;
    }
}

- (void)onMapViewAttached
{
    OARouteCalculationResult *route = [_routingHelper getRoute];
    CLLocation * start = _routingHelper.getLastFixedLocation;
    if (route && start && _routingHelper.isRouteCalculated)
    {
        [self enterRoutePreviewMode];
        if ([_routingHelper isFollowingMode])
            [self onTripStartTriggered];
    }
}

- (void)onUpdateMapTemplateStyle
{
    UIUserInterfaceStyle style = self.interfaceController.carTraitCollection.userInterfaceStyle;
    BOOL isDarkStyle = style == UIUserInterfaceStyleDark;
    _mapTemplate.guidanceBackgroundColor = isDarkStyle ? _darkGuidanceBackgroundColor : _lightGuidanceBackgroundColor;
    _mapTemplate.tripEstimateStyle = isDarkStyle ? CPTripEstimateStyleDark : CPTripEstimateStyleLight;
}

@end
