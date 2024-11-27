//
//  OASearchHistorySettingsItem.m
//  OsmAnd Maps
//
//  Created by Paul on 06.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASearchHistorySettingsItem.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"

@implementation OASearchHistorySettingsItem
{
    OAHistoryHelper *_searchHistoryHelper;
}

- (void)initialization
{
    [super initialization];
    _searchHistoryHelper = OAHistoryHelper.sharedInstance;
    self.existingItems = [NSMutableArray arrayWithArray:[_searchHistoryHelper getPointsHavingTypes:_searchHistoryHelper.searchTypes limit:0]];
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeSearchHistory;
}

- (NSString *)name
{
    return @"search_history";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"shared_string_search_history");
}

@end
