//
//  OABaseCarPlayInterfaceController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapActions.h"
#import <CarPlay/CarPlay.h>

@implementation OABaseCarPlayInterfaceController

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController
{
	self = [super init];
	if (self) {
		_interfaceController = interfaceController;
		[self commonInit];
	}
	return self;
}

- (void) commonInit
{
	// override
}

- (void) present
{
	// override
}

- (void) startNavigationGivenLocation:(CLLocation *)loc
{
	if (loc)
	{
		// TODO: implement CarPlay app profile and use it instead
		[OARoutingHelper.sharedInstance setAppMode:OAApplicationMode.CAR];
		[OATargetPointsHelper.sharedInstance navigateToPoint:loc updateRoute:YES intermediate:-1];
		[OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:NO showDialog:NO];
	}
}

- (NSArray<CPListSection *> *) generateSingleItemSectionWithTitle:(NSString *)title
{
	CPListItem *item = [[CPListItem alloc] initWithText:title detailText:nil];
	CPListSection *section = [[CPListSection alloc] initWithItems:@[item]];
	return @[section];
}

@end
