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

- (void) present
{
	_mapTemplate = [[CPMapTemplate alloc] init];
	_mapTemplate.mapDelegate = self;
	[self enterBrowsingState];
	
	[self.interfaceController setRootTemplate:_mapTemplate animated:YES];
}

- (void) enterBrowsingState
{
	_isInRouteCalculation = NO;
	
	CPBarButton *panningButton = [self createBarButton:EOACarPlayButtonTypePanMap];
	_mapTemplate.trailingNavigationBarButtons = @[panningButton];
	
	_mapTemplate.leadingNavigationBarButtons = @[[self createBarButton:EOACarPlayButtonTypeDirections]];
	
	_mapTemplate.mapButtons = @[[self createMapButton:EOACarPlayButtonTypeCenterMap], [self createMapButton:EOACarPlayButtonTypeZoomIn], [self createMapButton:EOACarPlayButtonTypeZoomOut]];
	
	// Always show the NavigationBar
	_mapTemplate.automaticallyHidesNavigationBar = NO;
}

- (void) enterRoutePreviewMode
{
	[OsmAndApp.instance getFormattedTimeHM:_routingHelper.getLeftTime];
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
			}
			case EOACarPlayButtonTypeCancelRoute: {
				[[OARootViewController instance].mapPanel stopNavigation];
				[_mapTemplate hideTripPreviews];
				[self enterBrowsingState];
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
		barButton.title = OALocalizedString(@"directions");
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
	else
		[self enterBrowsingState];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate panWithDirection:(CPPanDirection)direction
{
	if (_delegate)
		[_delegate onMapControlPressed:direction];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate selectedPreviewForTrip:(CPTrip *)trip usingRouteChoice:(CPRouteChoice *)routeChoice
{
	CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:[self getFormattedDistance:_routingHelper.getLeftDistance] timeRemaining:(NSTimeInterval)_routingHelper.getLeftTime];
	[_mapTemplate updateTravelEstimates:estimates forTrip:trip];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate startedTrip:(CPTrip *)trip usingRouteChoice:(CPRouteChoice *)routeChoice
{
	[mapTemplate hideTripPreviews];
	
	_navigationSession = [_mapTemplate startNavigationSessionForTrip:trip];
	[[OARootViewController instance].mapPanel startNavigation];
}

// MARK: - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
//	if (!newRoute)
//	{
//		dispatch_async(dispatch_get_main_queue(), ^{
//			BOOL animated = _calculatingRoute;
//			_calculatingRoute = NO;
//			[self reloadDataAnimated:animated];
//		});
//	}
}

- (void) routeWasUpdated
{
	
}

- (void) routeWasCancelled
{
	[_navigationSession finishTrip];
	[self enterBrowsingState];
}

- (void) routeWasFinished
{
	[_navigationSession finishTrip];
	[self enterBrowsingState];
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
	_isInRouteCalculation = NO;
	[self enterRoutePreviewMode];
}

// MARK: distance formatting methods

- (NSMeasurement<NSUnitLength *> *) getFormattedDistance:(int)meters
{
	OAAppSettings *settings = [OAAppSettings sharedManager];
	EOAMetricsConstant mc = [settings.metricSystem get];
	
	NSUnitLength *mainUnit;
	float mainUnitInMeters;
	if (mc == KILOMETERS_AND_METERS)
	{
		mainUnit = NSUnitLength.kilometers;
		mainUnitInMeters = METERS_IN_KILOMETER;
	}
	else if (mc == NAUTICAL_MILES)
	{
		mainUnit = NSUnitLength.nauticalMiles;
		mainUnitInMeters = METERS_IN_ONE_NAUTICALMILE;
	}
	else
	{
		mainUnit = NSUnitLength.miles;
		mainUnitInMeters = METERS_IN_ONE_MILE;
	}
	
	if (meters >= 100 * mainUnitInMeters)
	{
		return [[NSMeasurement alloc] initWithDoubleValue:(int)(meters / mainUnitInMeters + 0.5) unit:mainUnit];
	}
	else if (meters > 9.99f * mainUnitInMeters)
	{
		float num = meters / mainUnitInMeters;
		return [[NSMeasurement alloc] initWithDoubleValue:num unit:mainUnit];
	}
	else if (meters > 0.999f * mainUnitInMeters && mc != NAUTICAL_MILES)
	{
		return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnit];
	}
	else if (mc == MILES_AND_FEET && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:FOOTS_IN_ONE_METER])
	{
		return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnit];
	}
	else if (mc == MILES_AND_METERS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:METERS_IN_ONE_METER])
	{
		return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnit];
	}
	else if (mc == MILES_AND_YARDS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:YARDS_IN_ONE_METER])
	{
		return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnit];
	}
	else if (mc == NAUTICAL_MILES && meters > 0.99f * mainUnitInMeters && ![self isCleanValue:meters inUnits:METERS_IN_ONE_METER])
	{
		return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnit];
	}
	else
	{
		if (mc == KILOMETERS_AND_METERS || mc == MILES_AND_METERS || mc == NAUTICAL_MILES)
		{
			return [[NSMeasurement alloc] initWithDoubleValue:(int)(meters + 0.5) unit:NSUnitLength.meters];
		}
		else if (mc == MILES_AND_FEET)
		{
			int feet = (int) (meters * FOOTS_IN_ONE_METER + 0.5);
			return [[NSMeasurement alloc] initWithDoubleValue:feet unit:NSUnitLength.feet];
		}
		else if (mc == MILES_AND_YARDS)
		{
			int yards = (int) (meters * YARDS_IN_ONE_METER + 0.5);
			return [[NSMeasurement alloc] initWithDoubleValue:yards unit:NSUnitLength.yards];
		}
		return [[NSMeasurement alloc] initWithDoubleValue:((int) (meters + 0.5)) unit:NSUnitLength.meters];
	}
}

- (NSMeasurement<NSUnitLength *> *) getMilesFormattedStringWithMeters:(float)meters mainUnitInMeters:(float)mainUnitInMeters mainUnitStr:(NSUnitLength *)mainUnit
{
	float num = meters / mainUnitInMeters;
	return [[NSMeasurement alloc] initWithDoubleValue:num unit:mainUnit];
}

- (BOOL) isCleanValue:(float)meters inUnits:(float)unitsInOneMeter
{
	if ( int(meters) % int(METERS_IN_ONE_NAUTICALMILE) == 0)
		return NO;

	return (int((meters * unitsInOneMeter) * 100) % 100) < 1;
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
				maneuver.symbolSet = [[CPImageSet alloc] initWithLightContentImage:[UIImage imageNamed:@"ic_custom_navigation_arrow"] darkContentImage:[UIImage imageNamed:@"ic_custom_navigation_arrow"]];
				
				maneuver.initialTravelEstimates = estimates;
				maneuver.instructionVariants = @[nextTurn.directionInfo.getDescriptionRoute];
				_navigationSession.upcomingManeuvers = @[maneuver];
				_currentDirectionInfo = nextTurn;
			}
			else
			{
				[_navigationSession updateTravelEstimates:estimates forManeuver:maneuver];
			}
		}
		
//		if (nextTurn)
//		{
//			OANextDirectionInfo *nextNextTurn = [_routingHelper getNextRouteDirectionInfoAfter:nextTurn to:[[OANextDirectionInfo alloc] init] toSpeak:YES];
//			if (nextNextTurn && nextNextTurn.distanceTo > 0 && nextNextTurn.directionInfo)
//			{
//				turnType = nextNextTurn.directionInfo.turnType;
//				nextTurnDistance = nextNextTurn.distanceTo;
//				turnImminent = nextNextTurn.imminent;
//
//				CPManeuver *maneuver = _navigationSession.upcomingManeuvers.firstObject;
//				NSMeasurement<NSUnitLength *> * dist = [self getFormattedDistance:nextTurnDistance];
//				CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:dist timeRemaining:-1];
//				if (!maneuver)
//				{
//					maneuver = [[CPManeuver alloc] init];
//					maneuver.symbolSet = [[CPImageSet alloc] initWithLightContentImage:[UIImage imageNamed:@"ic_custom_navigation_arrow"] darkContentImage:[UIImage imageNamed:@"ic_custom_navigation_arrow"]];
//
//					maneuver.initialTravelEstimates = estimates;
//					maneuver.instructionVariants = @[nextTurn.directionInfo.getDescriptionRoute];
//				}
//				else
//				{
//					[_navigationSession updateTravelEstimates:estimates forManeuver:maneuver];
//				}
//
//				[maneuvers addObject:maneuver];
//			}
//		}
//
//		_navigationSession.upcomingManeuvers = maneuvers;
	}
}


@end
