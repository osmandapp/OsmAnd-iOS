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

typedef NS_ENUM(NSInteger, EOACarPlayButtonType) {
	EOACarPlayButtonTypeDismiss = 0,
	EOACarPlayButtonTypePanMap,
	EOACarPlayButtonTypeSearch,
	EOACarPlayButtonTypeZoomIn,
	EOACarPlayButtonTypeZoomOut,
	EOACarPlayButtonTypeCenterMap,
	EOACarPlayButtonTypeDirections,
	EOACarPlayButtonTypeRouteCalculation,
	EOACarPlayButtonTypeCancelRoute
};

@interface OACarPlayDashboardInterfaceController() <CPMapTemplateDelegate, OARouteInformationListener, OARouteCalculationProgressCallback>

@end

@implementation OACarPlayDashboardInterfaceController
{
	CPMapTemplate *_mapTemplate;
	
	OARoutingHelper *_routingHelper;
	
	BOOL _isInRouteCalculation;
	
	int _calculationProgress;
}

- (void) commonInit
{
	_routingHelper = OARoutingHelper.sharedInstance;
	[_routingHelper addListener:self];
	[_routingHelper addProgressBar:self];
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

- (void) enterRouteNavigationMode
{
//	_mapTemplate.automaticallyHidesNavigationBar = YES;
	
	CPRouteChoice *routeChoice = [[CPRouteChoice alloc] initWithSummaryVariants:@[] additionalInformationVariants:@[] selectionSummaryVariants:@[[OsmAndApp.instance getFormattedTimeHM:_routingHelper.getLeftTime]]];
	
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
	NSMeasurement<NSUnitLength *> *length = [[NSMeasurement alloc] initWithDoubleValue:_routingHelper.getLeftDistance unit:[[NSUnitLength alloc] initWithSymbol:@"km"]];
	
	
	CPTravelEstimates *estimates = [[CPTravelEstimates alloc] initWithDistanceRemaining:length timeRemaining:_routingHelper.getLeftTime];
	
	[_mapTemplate updateTravelEstimates:estimates forTrip:trip];
}

// MARK: - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
	
}

- (void) routeWasUpdated
{
	
}

- (void) routeWasCancelled
{
	
}

- (void) routeWasFinished
{
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
	[self enterRouteNavigationMode];
}


@end
