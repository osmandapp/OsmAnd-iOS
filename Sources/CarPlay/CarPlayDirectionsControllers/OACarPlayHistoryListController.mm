//
//  OACarPlayHistoryListController.m
//  OsmAnd Maps
//
//  Created by Skalii on 28.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACarPlayHistoryListController.h"
#import "OAHistoryItem.h"
#import "OAOsmAndFormatter.h"
#import "OsmAndApp.h"
#import "OASearchUICore.h"
#import "OASearchResult.h"
#import "OAQuickSearchHelper.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "OAQuickSearchListItem.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import <CoreLocation/CoreLocation.h>
#import <CarPlay/CarPlay.h>

#include <OsmAndCore/Utilities.h>

@implementation OACarPlayHistoryListController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
}

- (NSString *)screenTitle
{
    return OALocalizedString(@"shared_string_history");
}

- (NSArray<CPListSection *> *)generateSections
{
    NSMutableArray<OAHistoryItem *> *historyItems = [NSMutableArray array];
    NSMutableArray<CPListItem *> *listItems = [NSMutableArray array];

    BOOL navigationHistoryEnabled = [_settings.navigationHistory get];
    if ([_settings.searchHistory get])
    {
        NSMutableArray<OASearchResult *> *searchResults = [NSMutableArray array];
        OASearchUICore *searchUICore = [[OAQuickSearchHelper instance] getCore];
        OASearchResultCollection *res = [searchUICore shallowSearch:OASearchHistoryAPI.class text:@"" matcher:nil resortAll:NO removeDuplicates:NO];
        if (res)
            [searchResults addObjectsFromArray:[res getCurrentSearchResults]];

        for (OASearchResult *searchResult in searchResults)
        {
            OAHistoryItem *historyItem;
            if ([searchResult.object isKindOfClass:OAHistoryItem.class])
                historyItem = (OAHistoryItem *) searchResult.object;
            else if ([searchResult.relatedObject isKindOfClass:OAHistoryItem.class])
                historyItem = (OAHistoryItem *) searchResult.relatedObject;

            if (historyItem)
                [historyItems addObject:historyItem];
        }
    }
    else if (navigationHistoryEnabled)
    {
        [historyItems addObjectsFromArray:[[OAHistoryHelper sharedInstance] getPointsFromNavigation:0]];
    }

    if (navigationHistoryEnabled)
    {
        OARTargetPoint *pointToNavigateBackup = _app.data.pointToNavigateBackup;
        if (pointToNavigateBackup)
        {
            OAHistoryItem *prevRouteHistoryitem = [[OAHistoryItem alloc] initWithPointDescription:pointToNavigateBackup.pointDescription];
            prevRouteHistoryitem.name = pointToNavigateBackup.pointDescription.name;
            prevRouteHistoryitem.latitude = pointToNavigateBackup.point.coordinate.latitude;
            prevRouteHistoryitem.longitude = pointToNavigateBackup.point.coordinate.longitude;
            prevRouteHistoryitem.iconName = @"ic_custom_point_to_point";
            prevRouteHistoryitem.date = [NSDate date];
            [historyItems addObject:prevRouteHistoryitem];
        }
    }

    if ([_settings.mapMarkersHistory get])
    {
        OAHistoryHelper *historyHelper = [OAHistoryHelper sharedInstance];
        [historyItems addObjectsFromArray:[historyHelper getPointsHavingTypes:historyHelper.destinationTypes limit:0]];
    }

    if (historyItems.count > 0)
    {
        [historyItems sortUsingComparator:^NSComparisonResult(OAHistoryItem *h1, OAHistoryItem *h2) {
            NSTimeInterval lastTime1 = h1.date.timeIntervalSince1970;
            NSTimeInterval lastTime2 = h2.date.timeIntervalSince1970;
            return (lastTime1 < lastTime2) ? NSOrderedDescending : ((lastTime1 == lastTime2) ? NSOrderedSame : NSOrderedAscending);
        }];
        if (historyItems.count > CPListTemplate.maximumItemCount)
            [historyItems removeObjectsInRange:NSMakeRange(CPListTemplate.maximumItemCount, historyItems.count - CPListTemplate.maximumItemCount)];

        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        for (OAHistoryItem *historyItem in historyItems)
        {
            if (listItems.count >= maximumItemCount)
                break;

            [listItems addObject:[self createListItem:historyItem]];
        }
    }

    CPListSection *listSection = [[CPListSection alloc] initWithItems:listItems header:nil sectionIndexTitle:nil];
    return @[listSection];
}

- (CPListItem *)createListItem:(OAHistoryItem *)historyItem
{
    [self updateDistanceAndDirection:historyItem];
    NSString *title = historyItem.name.length > 0 ? historyItem.name : historyItem.typeName;
    NSString *detailText = historyItem && historyItem.distance ? historyItem.distance : @"";
    UIImage *icon;
    if (historyItem.hType == OAHistoryTypeParking)
        icon = [UIImage imageNamed:@"ic_parking_pin_small"];
    else if (historyItem.hType == OAHistoryTypeDirection)
        icon = [UIImage imageNamed:@"ic_custom_marker"];
    else if (historyItem.iconName && historyItem.iconName.length > 0)
        icon = [historyItem icon];
    if (!icon)
    {
        
        OAPointDescription *pointDescription = [[OAPointDescription alloc] initWithType:[historyItem getPointDescriptionType]
                                                                   typeName:historyItem.typeName
                                                                       name:historyItem.name];
        icon = [UIImage imageNamed:[OAQuickSearchListItem getItemIcon:pointDescription]];
    }

    CPListItem *listItem = [[CPListItem alloc] initWithText:title
                                                 detailText:detailText
                                                      image:icon
                                             accessoryImage:nil
                                              accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
    listItem.userInfo = historyItem;
    listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
        [self onItemSelected:item completionHandler:completionBlock];
    };
    return listItem;
}

- (void)updateDistanceAndDirection:(OAHistoryItem *)historyItem
{
    CLLocation *newLocation = _app.locationServices.lastKnownLocation;
    if (newLocation)
    {
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
                (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                        ? newLocation.course : newHeading;

        OsmAnd::LatLon latLon(historyItem.latitude, historyItem.longitude);
        const auto &position31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        CLLocation *location = [[CLLocation alloc] initWithLatitude:OsmAnd::Utilities::get31LatitudeY(position31.y)
                                                          longitude:OsmAnd::Utilities::get31LongitudeX(position31.x)];

        double distanceMeters = OsmAnd::Utilities::distance(
                newLocation.coordinate.longitude,
                newLocation.coordinate.latitude,
                location.coordinate.longitude,
                location.coordinate.latitude
        );
        NSString *distance = [OAOsmAndFormatter getFormattedDistance:distanceMeters];
        if (!distance)
            distance = [OAOsmAndFormatter getFormattedDistance:0];
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:location];
        CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);

        historyItem.distanceMeters = distanceMeters;
        historyItem.distance = distance;
        historyItem.direction = direction;
    }
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    OAHistoryItem *historyItem = item.userInfo;
    if (!historyItem)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    OAPointDescription *historyName = [[OAPointDescription alloc] initWithType:[historyItem getPointDescriptionType] typeName:historyItem.typeName name:historyItem.name];
    [self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:historyItem.latitude longitude:historyItem.longitude] historyName:historyName];
    [self.interfaceController popToRootTemplateAnimated:YES completion:nil];

    if (completionBlock)
        completionBlock();
}

@end
