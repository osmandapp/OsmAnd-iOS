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

#define unitsKm OALocalizedString(@"units_km")
#define unitsM OALocalizedString(@"units_m")
#define unitsMi OALocalizedString(@"units_mi")
#define unitsYd OALocalizedString(@"units_yd")
#define unitsFt OALocalizedString(@"units_ft")
#define unitsNm OALocalizedString(@"units_nm")

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
};

@interface OACarPlayDashboardInterfaceController() <CPMapTemplateDelegate, OARouteInformationListener, OARouteCalculationProgressCallback>

@end

@implementation OACarPlayDashboardInterfaceController
{
    CPMapTemplate *_mapTemplate;
    CPNavigationSession *_navigationSession;
    
    OARoutingHelper *_routingHelper;
    
    BOOL _isInRouteCalculation;
    BOOL _isInRoutePreview;
    
    int _calculationProgress;
    
    OAAutoObserverProxy *_locationServicesUpdateObserver;
    OANextDirectionInfo *_currentDirectionInfo;
}

- (void) commonInit
{
    _routingHelper = OARoutingHelper.sharedInstance;
    [_routingHelper addListener:self];
    [_routingHelper addProgressBar:self];
    
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:[OsmAndApp instance].locationServices.updateObserver];
}

- (void)dealloc
{
    [_locationServicesUpdateObserver detach];
}

- (void) stopNavigation
{
    [OARootViewController.instance.mapPanel.mapActions stopNavigationWithoutConfirm];
    OsmAndAppInstance app = OsmAndApp.instance;
    if (OAAppSettings.sharedManager.simulateRouting && [app.locationServices.locationSimulation isRouteAnimating])
        [app.locationServices.locationSimulation startStopRouteAnimation];
}

- (void) present
{
    // Dismiss any previous navigation
    
    [[OARootViewController instance].mapPanel closeRouteInfo];
    
    _mapTemplate = [[CPMapTemplate alloc] init];
    _mapTemplate.mapDelegate = self;
    [self enterBrowsingState];
    
    [self.interfaceController setRootTemplate:_mapTemplate animated:YES];
    
    OARouteCalculationResult *route = [_routingHelper getRoute];
    CLLocation * start = _routingHelper.getLastFixedLocation;
    if (route && start && _routingHelper.isRouteCalculated)
    {
        [_routingHelper setNewRoute:nil res:route start:start];
    }
}

- (void) enterBrowsingState
{
    _isInRouteCalculation = NO;
    _isInRoutePreview = NO;
    
    CPBarButton *panningButton = [self createBarButton:EOACarPlayButtonTypePanMap];
    _mapTemplate.trailingNavigationBarButtons = @[panningButton];
    
    _mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeDirections]];
    
    _mapTemplate.mapButtons = @[[self createMapButton:EOACarPlayButtonTypeCenterMap], [self createMapButton:EOACarPlayButtonTypeZoomIn], [self createMapButton:EOACarPlayButtonTypeZoomOut]];
}

- (void) enterRoutePreviewMode
{
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
    
    CPTrip *trip = [[CPTrip alloc] initWithOrigin:startItem destination:finishItem routeChoices:@[routeChoice]];
    
    CPTripPreviewTextConfiguration *config = [[CPTripPreviewTextConfiguration alloc] initWithStartButtonTitle:OALocalizedString(@"gpx_start") additionalRoutesButtonTitle:nil overviewButtonTitle:nil];
    
    [_mapTemplate showTripPreviews:@[trip] textConfiguration:config];
    _mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeCancelRoute]];
    
    _isInRoutePreview = YES;
    
    [self centerMapOnRoute];
    if (_delegate)
        [_delegate enterNavigationMode];
}

- (void)exitNavigationMode
{
    if (!_navigationSession)
        return;
    _currentDirectionInfo = nil;
    [_navigationSession finishTrip];
    _navigationSession = nil;
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
            default:
                break;
        }
    }];
    
    if (type == EOACarPlayButtonTypeZoomIn)
        mapButton.image = [UIImage imageNamed:@"btn_map_zoom_in_day.png"];
    else if (type == EOACarPlayButtonTypeZoomOut)
        mapButton.image = [UIImage imageNamed:@"btn_map_zoom_out_day.png"];
    else if (type == EOACarPlayButtonTypeCenterMap)
        mapButton.image = [UIImage imageNamed:@"btn_map_current_location_day"];
    
    return mapButton;
}

- (CPBarButton *) createBarButton:(EOACarPlayButtonType)type
{
    CPBarButton *barButton = [[CPBarButton alloc] initWithType:[self getButtonType:type] handler:^(CPBarButton * _Nonnull button) {
        switch(type) {
            case EOACarPlayButtonTypeDismiss: {
                // Dismiss the map panning interface
                [_mapTemplate dismissPanningInterfaceAnimated:YES];
                break;
            }
            case EOACarPlayButtonTypePanMap: {
                // Enable the map panning interface and set the dismiss button
                [_mapTemplate showPanningInterfaceAnimated:YES];
                break;
            }
            case EOACarPlayButtonTypeDirections: {
                OADirectionsGridController *directionsGrid = [[OADirectionsGridController alloc] initWithInterfaceController:self.interfaceController];
                [directionsGrid present];
                break;
            }
            case EOACarPlayButtonTypeCancelRoute: {
                [self stopNavigation];
                if (_delegate)
                    [_delegate exitNavigationMode];
                [_mapTemplate hideTripPreviews];
                [self enterBrowsingState];
                break;
            }
            default: {
                break;
            }
        }
    }];
    
    if (type == EOACarPlayButtonTypePanMap)
        barButton.image = [UIImage imageNamed:@"ic_custom_change_object_position"];
    else if (type == EOACarPlayButtonTypeDismiss)
        barButton.title = OALocalizedString(@"shared_string_done");
    else if (type == EOACarPlayButtonTypeDirections)
        barButton.title = OALocalizedString(@"shared_string_navigation");
    else if (type == EOACarPlayButtonTypeRouteCalculation)
        barButton.title = [NSString stringWithFormat:OALocalizedString(@"route_calc_progress"), 0];
    else if (type == EOACarPlayButtonTypeCancelRoute)
        barButton.title = OALocalizedString(@"shared_string_cancel");
    
    return barButton;
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
    [[OARootViewController instance].mapPanel startNavigation];
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
    NSString *distString = [OAOsmAndFormatter getFormattedDistance:meters];
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

// MARK: Location service updates

- (void) onLocationServicesUpdate
{
    if (_navigationSession)
    {
        std::shared_ptr<TurnType> turnType = nullptr;
        int turnImminent = 0;
        int nextTurnDistance = 0;
        OANextDirectionInfo *nextTurn = [_routingHelper getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] toSpeak:YES];
        if (nextTurn && nextTurn.distanceTo > 0 && nextTurn.directionInfo)
        {
            turnType = nextTurn.directionInfo.turnType;
            nextTurnDistance = nextTurn.distanceTo;
            turnImminent = nextTurn.imminent;
            
            CPManeuver *maneuver = _navigationSession.upcomingManeuvers.firstObject;
            NSMeasurement<NSUnitLength *> * dist = [self getFormattedDistance:nextTurnDistance];
            CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:dist timeRemaining:-1];
            if (!maneuver || nextTurn.directionInfoInd != _currentDirectionInfo.directionInfoInd)
            {
                maneuver = [[CPManeuver alloc] init];
                UIImage *turnImage = [self imageForTurnType:turnType];
                maneuver.symbolSet = [[CPImageSet alloc] initWithLightContentImage:turnImage darkContentImage:turnImage];
                
                maneuver.initialTravelEstimates = estimates;
                if (nextTurn.directionInfo.streetName)
                    maneuver.instructionVariants = @[nextTurn.directionInfo.streetName];
                _navigationSession.upcomingManeuvers = @[maneuver];
                _currentDirectionInfo = nextTurn;
            }
            else
            {
                [_navigationSession updateTravelEstimates:estimates forManeuver:maneuver];
            }
        }
        [self updateTripEstimates:_navigationSession.trip];
    }
}

- (UIImage *) imageForTurnType:(std::shared_ptr<TurnType> &)turnType
{
    if (turnType->getValue() == TurnType::C) {
        return [UIImage imageNamed:@"map_turn_forward"];
    } else if (turnType->getValue() == TurnType::TSLL) {
        return [UIImage imageNamed:@"map_turn_slight_left"];
    } else if (turnType->getValue() == TurnType::TL) {
        return [UIImage imageNamed:@"map_turn_left"];
    } else if (turnType->getValue() == TurnType::TSHL) {
        return [UIImage imageNamed:@"map_turn_sharp_left"];
    } else if (turnType->getValue() == TurnType::TSLR) {
        return [UIImage imageNamed:@"map_turn_slight_right"];
    } else if (turnType->getValue() == TurnType::TR) {
        return [UIImage imageNamed:@"map_turn_right"];
    } else if (turnType->getValue() == TurnType::TSHR) {
        return [UIImage imageNamed:@"map_turn_sharp_right"];
    } else if (turnType->getValue() == TurnType::TU) {
        return [UIImage imageNamed:@"map_turn_uturn"];
    } else if (turnType->getValue() == TurnType::TRU) {
        return [UIImage imageNamed:@"map_turn_uturn_right"];
    } else if (turnType->getValue() == TurnType::KL) {
        return [UIImage imageNamed:@"map_turn_keep_left"];
    } else if (turnType->getValue() == TurnType::KR) {
        return [UIImage imageNamed:@"map_turn_keep_right"];
    } else if (turnType->getValue() == TurnType::RNDB) {
        return [UIImage imageNamed:@"map_turn_roundabout"];
    } else if (turnType->getValue() == TurnType::KR) {
        return [UIImage imageNamed:@"map_turn_roundablot_left"];
    }
    return nil;
}

@end
