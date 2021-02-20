//
//  OACarPlayFavoritesListController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayFavoritesListController.h"
#import "Localization.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OsmAndApp.h"

#import <CarPlay/CarPlay.h>

#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

@implementation OACarPlayFavoritesListController

- (NSString *)screenTitle
{
	return OALocalizedString(@"favorites");
}

- (NSArray<CPListSection *> *) generateSections
{
	NSMutableArray<CPListSection *> *sections = [NSMutableArray new];
	
	NSArray<OAFavoriteGroup *> *favoriteGroups = [OAFavoritesHelper getGroupedFavorites:OsmAndApp.instance.favoritesCollection->getFavoriteLocations()];
	
	if (favoriteGroups.count > 0)
	{
		[favoriteGroups enumerateObjectsUsingBlock:^(OAFavoriteGroup * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
			NSMutableArray<CPListItem *> *items = [NSMutableArray new];
			[group.points enumerateObjectsUsingBlock:^(OAFavoriteItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
				item.distance = [self calculateDistanceToItem:item];
				CPListItem *listItem;
				listItem = [[CPListItem alloc] initWithText:item.favorite->getTitle().toNSString() detailText:item.distance image:[UIImage imageNamed:@"ic_custom_favorites"] showsDisclosureIndicator:YES];
				listItem.userInfo = item;
				[items addObject:listItem];
			}];
			NSString *groupName = group.name.length == 0 ? OALocalizedString(@"favorites") : group.name;
			CPListSection *section = [[CPListSection alloc] initWithItems:items header:groupName sectionIndexTitle:[groupName substringToIndex:1]];
			[sections addObject:section];
		}];
	}
	else
	{
		return [self generateSingleItemSectionWithTitle:OALocalizedString(@"favorites_empty")];
	}
	return sections;
}

- (NSString *) calculateDistanceToItem:(OAFavoriteItem *)item
{
	OsmAndAppInstance app = OsmAndApp.instance;
	CLLocation* newLocation = app.locationServices.lastKnownLocation;
	if (!newLocation)
		return nil;
	
	const auto& favoritePosition31 = item.favorite->getPosition31();
	const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
	const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
		
	const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
														newLocation.coordinate.latitude,
														favoriteLon, favoriteLat);
	

	
	return [app getFormattedDistance:distance];
}

// MARK: - CPListTemplateDelegate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
	OAFavoriteItem* favoritePoint = item.userInfo;
	if (!favoritePoint)
	{
		completionHandler();
		return;
	}
	[self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:favoritePoint.getLatitude longitude:favoritePoint.getLongitude]];
	[self.interfaceController popToRootTemplateAnimated:YES];
	
	completionHandler();
}

@end
