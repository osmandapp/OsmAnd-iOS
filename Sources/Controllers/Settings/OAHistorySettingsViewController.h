//
//  OAHistorySettingsViewController.h
//  OsmAnd Maps
//
//  Created by Dmytro Svetlichnyi on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

typedef enum
{
    EOAHistorySettingsTypeSearch,
    EOAHistorySettingsTypeNavigation,
    EOAHistorySettingsTypeMapMarkers
} EOAHistorySettingsType;

@class OASearchResult, OAHistoryItem;

@protocol OAHistorySettingsDelegate

- (NSArray<OASearchResult *> *)getNavigationHistoryResults;
- (NSMutableArray<OASearchResult *> *)getSearchHistoryResults;
- (OAHistoryItem *)getHistoryEntry:(OASearchResult *) searchResult;

@end

@interface OAHistorySettingsViewController : OABaseButtonsViewController

- (instancetype)initWithSettingsType:(EOAHistorySettingsType)historyType;

@property (nonatomic, readonly) EOAHistorySettingsType historyType;
@property (nonatomic, weak) id<OAHistorySettingsDelegate> delegate;

@end
