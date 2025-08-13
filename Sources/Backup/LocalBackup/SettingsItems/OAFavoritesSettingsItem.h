//
//  OAFavoritesSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"

@class OAFavoriteGroup;

@interface OAFavoritesSettingsItem : OACollectionSettingsItem<OAFavoriteGroup *>

@end

@interface OAFavoritesSettingsItemReader : OASettingsItemReader<OAFavoritesSettingsItem *>

@end
