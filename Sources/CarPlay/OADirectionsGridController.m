//
//  OADirectionsGridController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADirectionsGridController.h"
#import "OACarPlayFavoritesListController.h"
#import "OASearchCategoriesListController.h"
#import "OACarPlayAddressSearchController.h"
#import "OACarPlayMarkersListController.h"
#import "OACarPlayTracksListController.h"
#import "Localization.h"

#import <CarPlay/CarPlay.h>


@interface OADirectionsGridController()

@end

@implementation OADirectionsGridController
{
	CPGridTemplate *_gridTemplate;
	
	OACarPlayAddressSearchController *_searchController;
	OACarPlayFavoritesListController *_favoritesListController;
	OASearchCategoriesListController *_categoriesListController;
	OACarPlayMarkersListController *_markersListController;
	OACarPlayTracksListController *_tracksListController;
	
}

- (void) present
{
	_gridTemplate = [[CPGridTemplate alloc] initWithTitle:OALocalizedString(@"select_route_finish_on_map") gridButtons:[self generateGridButtons]];
	[self.interfaceController pushTemplate:_gridTemplate animated:YES];
}

- (NSArray<CPGridButton *> *) generateGridButtons
{
	CPGridButton *btnFav = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"favorites")] image:[UIImage imageNamed:@"ic_carplay_favorites"] handler:^(CPGridButton * _Nonnull barButton) {
		_favoritesListController = [[OACarPlayFavoritesListController alloc] initWithInterfaceController:self.interfaceController];
		[_favoritesListController present];
	}];
	
	CPGridButton *btnCategories = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"poi_categories")] image:[UIImage imageNamed:@"ic_carplay_poi"] handler:^(CPGridButton * _Nonnull barButton) {
		_categoriesListController = [[OASearchCategoriesListController alloc] initWithInterfaceController:self.interfaceController];
		[_categoriesListController present];
	}];
	
	CPGridButton *btnSearch = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"address_search")] image:[UIImage imageNamed:@"ic_carplay_search"] handler:^(CPGridButton * _Nonnull barButton) {
		_searchController = [[OACarPlayAddressSearchController alloc] initWithInterfaceController:self.interfaceController];
		[_searchController present];
	}];
	
	CPGridButton *btnMarkers = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"map_markers")] image:[UIImage imageNamed:@"ic_carplay_map_markers"] handler:^(CPGridButton * _Nonnull barButton) {
		_markersListController = [[OACarPlayMarkersListController alloc] initWithInterfaceController:self.interfaceController];
		[_markersListController present];
	}];
	
	CPGridButton *btnTracks = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"tracks")] image:[UIImage imageNamed:@"ic_carplay_tracks"] handler:^(CPGridButton * _Nonnull barButton) {
		_tracksListController = [[OACarPlayTracksListController alloc] initWithInterfaceController:self.interfaceController];
		[_tracksListController present];
	}];
	
	return @[btnSearch, btnCategories, btnFav, btnMarkers, btnTracks];
}

@end
