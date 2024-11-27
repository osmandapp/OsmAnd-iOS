//
//  OANavigationHistorySettingsItem.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 25/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OANavigationHistorySettingsItem.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"

@implementation OANavigationHistorySettingsItem
{
    OAHistoryHelper *_searchHistoryHelper;
}

- (void)initialization
{
    [super initialization];
    _searchHistoryHelper = OAHistoryHelper.sharedInstance;
    self.existingItems = [NSMutableArray arrayWithArray:[_searchHistoryHelper getPointsFromNavigation:0]];
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeNavigationHistory;
}

- (NSString *)name
{
    return @"navigation_history";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"navigation_history");
}

@end
