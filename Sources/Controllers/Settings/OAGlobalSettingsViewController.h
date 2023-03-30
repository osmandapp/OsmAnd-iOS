//
//  OAGlobalSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

typedef enum
{
    EOAGlobalSettingsMain = 0,
    EOADefaultProfile,
    EOACarplayProfile,
    EOADialogsAndNotifications,
    EOAHistory
} EOAGlobalSettingsScreen;

@class OASearchResult, OAHistoryItem;

@interface OAGlobalSettingsViewController : OABaseNavbarViewController

- (instancetype) initWithSettingsType:(EOAGlobalSettingsScreen)settingsType;

+ (NSArray<OASearchResult *> *)getNavigationHistoryResults;
+ (NSMutableArray<OASearchResult *> *)getSearchHistoryResults;
+ (OAHistoryItem *)getHistoryEntry:(OASearchResult *)searchResult;

@end

