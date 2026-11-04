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
#import "OACarPlayHistoryListController.h"
#import "Localization.h"

#import <CarPlay/CarPlay.h>
#import "GeneratedAssetSymbols.h"


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
    OACarPlayHistoryListController *_historyListController;
}

- (void) present
{
    _gridTemplate = [[CPGridTemplate alloc] initWithTitle:OALocalizedString(@"select_route_finish_on_map") gridButtons:[self generateGridButtons]];
    [self safePushTemplate:_gridTemplate animated:YES];
}

- (void)openSearch {
    _searchController = [[OACarPlayAddressSearchController alloc] initWithInterfaceController:self.interfaceController];
    [_searchController present];
}

- (NSArray<CPGridButton *> *) generateGridButtons
{
    CPGridButton *btnFav = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"favorites_item")]
                                                                 image:[UIImage imageNamed:ACImageNameIcCarplayFavorites]
                                                               handler:^(CPGridButton * _Nonnull barButton) {
        _favoritesListController = [[OACarPlayFavoritesListController alloc] initWithInterfaceController:self.interfaceController];
        [_favoritesListController present];
    }];

    CPGridButton *btnCategories = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"poi_categories")]
                                                                        image:[UIImage imageNamed:ACImageNameIcCarplayPoi]
                                                                      handler:^(CPGridButton * _Nonnull barButton) {
        _categoriesListController = [[OASearchCategoriesListController alloc] initWithInterfaceController:self.interfaceController];
        [_categoriesListController present];
    }];

    CPGridButton *btnSearch = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"address_search_desc")]
                                                                    image:[UIImage imageNamed:ACImageNameIcCarplaySearch]
                                                                  handler:^(CPGridButton * _Nonnull barButton) {
        [self openSearch];
    }];

    CPGridButton *btnMarkers = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"map_markers")]
                                                                     image:[UIImage imageNamed:ACImageNameIcCarplayMapMarkers]
                                                                   handler:^(CPGridButton * _Nonnull barButton) {
        _markersListController = [[OACarPlayMarkersListController alloc] initWithInterfaceController:self.interfaceController];
        [_markersListController present];
    }];

    CPGridButton *btnTracks = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"shared_string_gpx_tracks")]
                                                                    image:[UIImage imageNamed:ACImageNameIcCarplayTracks]
                                                                  handler:^(CPGridButton * _Nonnull barButton) {
        _tracksListController = [[OACarPlayTracksListController alloc] initWithInterfaceController:self.interfaceController];
        [_tracksListController present];
    }];

    CPGridButton *btnHistory = [[CPGridButton alloc] initWithTitleVariants:@[OALocalizedString(@"shared_string_history")]
                                                                     image:[UIImage imageNamed:ACImageNameIcCarplayHistory]
                                                                   handler:^(CPGridButton * _Nonnull barButton) {
        _historyListController = [[OACarPlayHistoryListController alloc] initWithInterfaceController:self.interfaceController];
        [_historyListController present];
    }];

    return @[btnHistory, btnSearch, btnCategories, btnFav, btnMarkers, btnTracks];
}

@end
