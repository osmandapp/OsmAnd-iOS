//
//  OANavigationPointsListController.m
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OANavigationPointsListController.h"
#import "Localization.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OsmAndApp.h"
#import "OATargetPointsHelper.h"
#import "OARoutingHelper.h"
#import "OAMapActions.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"

#import <CarPlay/CarPlay.h>

#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

@interface OANavigationPointsListController() <CPListTemplateDelegate>

@end

@implementation OANavigationPointsListController
{
	CPListTemplate *_listTemplate;
	
	NSArray<OAFavoriteGroup *> *_favoriteGroups;
	
	OATargetPointsHelper *_pointsHelper;
	OARoutingHelper *_routingHelper;
}

- (void) commonInit
{
	_pointsHelper = OATargetPointsHelper.sharedInstance;
	_routingHelper = OARoutingHelper.sharedInstance;
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
	
	for (OAFavoriteGroup *group in _favoriteGroups)
	{
		NSMutableArray<CPListItem *> *items = [NSMutableArray new];
		for (OAFavoriteItem *item in group.points)
		{
			item.distance = [self calculateDistanceToItem:item];
			CPListItem *listItem;
			if (@available(iOS 13.0, *)) {
				UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
				listItem = [[CPListItem alloc] initWithText:item.favorite->getTitle().toNSString() detailText:item.distance image:[[UIImage imageNamed:@"ic_custom_favorites"] imageWithTintColor:color] showsDisclosureIndicator:YES];
				
			} else {
				listItem = [[CPListItem alloc] initWithText:item.favorite->getTitle().toNSString() detailText:item.distance image:[UIImage imageNamed:@"ic_custom_favorites"] showsDisclosureIndicator:YES];
			}
			
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
	NSIndexPath *indexPath = nil;
	NSArray<CPListSection *> *sections = listTemplate.sections;
	for (NSInteger section = 0; section < sections.count; section++)
	{
		NSArray<id<CPListTemplateItem>> *items = sections[section].items;
		for (NSInteger row = 0; row < items.count; row++)
		{
			if (items[row] == item)
			{
				indexPath = [NSIndexPath indexPathForRow:row inSection:section];
				break;
			}
		}
	}
	if (!indexPath)
		return;
	OAFavoriteItem *favoritePoint = _favoriteGroups[indexPath.section].points[indexPath.row];
	if (favoritePoint)
	{
		[_routingHelper setAppMode:OAApplicationMode.CAR];
		[_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:favoritePoint.getLatitude longitude:favoritePoint.getLongitude] updateRoute:YES intermediate:-1];
		[OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:NO showDialog:NO];
	}
	[self.interfaceController popToRootTemplateAnimated:YES];
	
	completionHandler();
}

@end
