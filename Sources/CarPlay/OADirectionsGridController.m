//
//  OADirectionsGridController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADirectionsGridController.h"
#import "OANavigationPointsListController.h"
#import "Localization.h"

#import <CarPlay/CarPlay.h>


@interface OADirectionsGridController()

@end

@implementation OADirectionsGridController
{
	CPGridTemplate *_gridTemplate;
}

- (void) present
{
	_gridTemplate = [[CPGridTemplate alloc] initWithTitle:OALocalizedString(@"select_route_finish_on_map") gridButtons:@[[self generateGridButton]]];
	[self.interfaceController pushTemplate:_gridTemplate animated:YES];
}

- (CPGridButton *) generateGridButton
{
	CPGridButton *btn = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"favorites")] image:[UIImage imageNamed:@"ic_custom_favorites"] handler:^(CPGridButton * _Nonnull barButton) {
		OANavigationPointsListController *favoritesListController = [[OANavigationPointsListController alloc] initWithInterfaceController:self.interfaceController];
		[favoritesListController present];
	}];
	return btn;
}

@end
