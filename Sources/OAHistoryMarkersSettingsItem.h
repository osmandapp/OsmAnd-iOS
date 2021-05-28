//
// Created by Dmitry on 26.05.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"

@class OAHistoryItem;

@interface OAHistoryMarkersSettingsItem : OACollectionSettingsItem<OAHistoryItem *>

@end

@interface OAHistoryMarkersSettingsItemReader : OASettingsItemReader<OAHistoryMarkersSettingsItem *>

@end
