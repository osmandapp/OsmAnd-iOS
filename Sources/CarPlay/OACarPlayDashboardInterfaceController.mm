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
#import "Localization.h"
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

@end

@implementation OACarPlayDashboardInterfaceController
{
    OAAppSettings *_settings;

    CPMapTemplate *_mapTemplate;
    CPNavigationSession *_navigationSession;
    CPTrip *_currentTrip;
    
    OARoutingHelper *_routingHelper;
    
    BOOL _isInRouteCalculation;
    BOOL _isInRoutePreview;
    
    int _calculationProgress;

    CPMapButton *_3DModeMapButton;
    BOOL _wasIn3DBeforePreview;

    OAAutoObserverProxy *_locationUpdateObserver;
    OAAutoObserverProxy *_map3DModeObserver;
    OANextDirectionInfo *_currentDirectionInfo;
    
    OALanesDrawable *_lanesDrawable;
    CPManeuverDisplayStyle _secondaryStyle;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _routingHelper = OARoutingHelper.sharedInstance;
    [_routingHelper addListener:self];
    [_routingHelper addCalculationProgressCallback:self];
    _lanesDrawable = [[OALanesDrawable alloc] initWithScaleCoefficient:10.];
    _secondaryStyle = CPManeuverDisplayStyleDefault;
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
            EOAMap3DModeVisibility map3DMode = [[[OAMapButtonsHelper sharedInstance] getMap3DButtonState] getVisibility];
            BOOL hideButton = map3DMode == EOAMap3DModeVisibilityHidden
                || (map3DMode == EOAMap3DModeVisibilityVisibleIn3DMode && ![mapViewTrackingUtilities is3DMode]);
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
            _3DModeMapButton.accessibilityValue = [EOAMap3DModeVisibilityWrapper getTitleForType:map3DMode];
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
    NSString *distString = [OAOsmAndFormatter getFormattedDistance:meters roundUp:![[OAAppSettings sharedManager].preciseDistanceNumbers get]];
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

- (CPManeuver *)createTurnManeuver:(CPTravelEstimates *)estimates directionInfo:(OANextDirectionInfo *)directionInfo
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    BOOL followingMode = [routingHelper isFollowingMode];
    BOOL deviatedFromRoute = false;
    if (routingHelper && [routingHelper isRouteCalculated] && followingMode)
        deviatedFromRoute = [OARoutingHelper isDeviatedFromRoute];

    UIUserInterfaceStyle style = self.interfaceController.carTraitCollection.userInterfaceStyle;
    EOATurnDrawableThemeColor themeColor = style == UIUserInterfaceStyleDark ? EOATurnDrawableThemeColorDark : EOATurnDrawableThemeColorLight;
    OATurnDrawable *turnDrawable = [[OATurnDrawable alloc] initWithMini:NO themeColor:themeColor];
    const auto turnType = directionInfo.directionInfo.turnType;
    [turnDrawable setTurnType:turnType];
    [turnDrawable setTurnImminent:directionInfo.imminent deviatedFromRoute:deviatedFromRoute];
    turnDrawable.textFont = [UIFont scaledSystemFontOfSize:16 weight:UIFontWeightSemibold];
    CGFloat size = MAX(turnDrawable.pathForTurn.bounds.origin.x + turnDrawable.pathForTurn.bounds.size.width,
                       turnDrawable.pathForTurn.bounds.origin.y + turnDrawable.pathForTurn.bounds.size.height);
    turnDrawable.frame = CGRectMake(0, 0, size, size);
    [turnDrawable setNeedsDisplay];

    CPManeuver *maneuver = [[CPManeuver alloc] init];
    maneuver.symbolImage = [turnDrawable toUIImage];
    maneuver.initialTravelEstimates = estimates;
    maneuver.userInfo = @{ @"imminent" : @(directionInfo.imminent) };
    if (directionInfo.directionInfo.streetName)
        maneuver.instructionVariants = @[directionInfo.directionInfo.streetName];
    return maneuver;
}

// MARK: Location updates

- (void) onLocationUpdate
{
    if (_navigationSession)
    {
        int turnImminent = 0;
        int nextTurnDistance = 0;
        int secondaryTurnDistance = 0;
        OANextDirectionInfo *nextTurn = [_routingHelper getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] toSpeak:YES];
        if (nextTurn && nextTurn.distanceTo > 0 && nextTurn.directionInfo)
        {
            OANextDirectionInfo *secondaryInfo = nil;
            nextTurnDistance = nextTurn.distanceTo;
            turnImminent = nextTurn.imminent;
            vector<int> loclanes = nextTurn.directionInfo.turnType->getLanes();
            bool lanesVisible = !loclanes.empty();
            bool secondaryVisible = false;
            __block CPManeuver *secondaryManeuver = nil;
            if (!lanesVisible)
            {
                secondaryInfo = [_routingHelper getNextRouteDirectionInfoAfter:nextTurn to:[[OANextDirectionInfo alloc] init] toSpeak:YES];
                if (secondaryInfo && secondaryInfo.directionInfo)
                {
                    secondaryTurnDistance = secondaryInfo.distanceTo;
                    _secondaryStyle = CPManeuverDisplayStyleDefault;
                    secondaryVisible = true;
                }
            }
            
            __block CPManeuver *maneuver = _navigationSession.upcomingManeuvers.firstObject;
            NSMeasurement<NSUnitLength *> *dist = [self getFormattedDistance:nextTurnDistance];
            CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:dist timeRemaining:-1];
            if (!maneuver || nextTurn.directionInfoInd != _currentDirectionInfo.directionInfoInd || ([maneuver.userInfo[@"imminent"] intValue] != turnImminent))
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    maneuver = [self createTurnManeuver:estimates directionInfo:nextTurn];
                    if (lanesVisible)
                    {
                        secondaryManeuver = [[CPManeuver alloc] init];
                        auto& drawableLanes = [_lanesDrawable getLanes];
                        if (drawableLanes.size() != loclanes.size() || (drawableLanes.size() > 0 && !std::equal(drawableLanes.begin(), drawableLanes.end(), loclanes.begin())) || (turnImminent == 0) != _lanesDrawable.imminent)
                        {
                            _lanesDrawable.imminent = turnImminent == 0;
                            [_lanesDrawable setLanes:loclanes];
                            [_lanesDrawable updateBounds];
                            _lanesDrawable.frame = CGRectMake(0, 0, _lanesDrawable.width, _lanesDrawable.height);
                            [_lanesDrawable setNeedsDisplay];
                        }
                        UIImage *img = _lanesDrawable.toUIImage;
                        secondaryManeuver.symbolImage = img;
                        secondaryManeuver.instructionVariants = @[];
                        _secondaryStyle = CPManeuverDisplayStyleSymbolOnly;
                    }
                    else if (secondaryVisible)
                    {
                        secondaryManeuver = [self createTurnManeuver:nil directionInfo:secondaryInfo];
                    }
                    if (secondaryManeuver)
                        _navigationSession.upcomingManeuvers = @[maneuver, secondaryManeuver];
                    else
                        _navigationSession.upcomingManeuvers = @[maneuver];
                    _currentDirectionInfo = nextTurn;
                });
            }
            else
            {
                [_navigationSession updateTravelEstimates:estimates forManeuver:maneuver];
            }
        }
        [self updateTripEstimates:_navigationSession.trip];
    }
    [self.delegate onLocationChanged];
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

@end
