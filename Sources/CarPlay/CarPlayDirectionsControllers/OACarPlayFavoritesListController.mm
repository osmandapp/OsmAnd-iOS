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

@interface OACarPlayFavoritesListController() <CPListTemplateDelegate>

@end

@implementation OACarPlayFavoritesListController
{
	CPListTemplate *_listTemplate;
	
	NSArray<OAFavoriteGroup *> *_favoriteGroups;
}

- (void) present
{
	_listTemplate = [[CPListTemplate alloc] initWithTitle:OALocalizedString(@"favorites") sections:[self generateSections]];
	_listTemplate.delegate = self;
	[self.interfaceController pushTemplate:_listTemplate animated:YES];
}

- (NSArray<CPListSection *> *) generateSections
{
	NSMutableArray<CPListSection *> *sections = [NSMutableArray new];
	
	_favoriteGroups = [OAFavoritesHelper getGroupedFavorites:OsmAndApp.instance.favoritesCollection->getFavoriteLocations()];
	
	for (NSInteger groupIndex = 0; groupIndex < _favoriteGroups.count; groupIndex++)
	{
		OAFavoriteGroup *group = _favoriteGroups[groupIndex];
		NSMutableArray<CPListItem *> *items = [NSMutableArray new];
		for (NSInteger favIndex = 0; favIndex < group.points.count; favIndex++)
		{
			OAFavoriteItem *item = group.points[favIndex];
			item.distance = [self calculateDistanceToItem:item];
			CPListItem *listItem;
			listItem = [[CPListItem alloc] initWithText:item.favorite->getTitle().toNSString() detailText:item.distance image:[UIImage imageNamed:@"ic_custom_favorites"] showsDisclosureIndicator:YES];
			listItem.userInfo = [NSIndexPath indexPathForRow:favIndex inSection:groupIndex];
			
			if (@available(iOS 14.0, *)) {
				[listItem setHandler:^(id <CPSelectableListItem> item,
									  dispatch_block_t completionBlock) {
					[self listTemplate:_listTemplate didSelectListItem:item completionHandler:completionBlock];
				}];
			}
			
			[items addObject:listItem];
		}
		NSString *groupName = group.name.length == 0 ? OALocalizedString(@"favorites") : group.name;
		CPListSection *section = [[CPListSection alloc] initWithItems:items header:groupName sectionIndexTitle:[groupName substringToIndex:1]];
		[sections addObject:section];
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
	NSIndexPath* indexPath = item.userInfo;
	if (!indexPath)
	{
		completionHandler();
		return;
	}
	OAFavoriteItem *favoritePoint = _favoriteGroups[indexPath.section].points[indexPath.row];
	if (favoritePoint)
	{
		[self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:favoritePoint.getLatitude longitude:favoritePoint.getLongitude]];
	}
	[self.interfaceController popToRootTemplateAnimated:YES];
	
	completionHandler();
}

@end
