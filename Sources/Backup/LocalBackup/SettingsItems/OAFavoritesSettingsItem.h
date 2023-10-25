//
//  OAFavoritesSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"
#import "OAFavoritesHelper.h"

@class OAFavoriteItem, OAWptPt;

@interface OAFavoritesSettingsItem : OACollectionSettingsItem<OAFavoriteGroup *>

+ (NSArray<OAFavoriteItem *> *)wptAsFavourites:(NSArray<OAWptPt *> *)points
                               defaultCategory:(NSString *)defaultCategory;

@end

@interface OAFavoritesSettingsItemReader : OASettingsItemReader<OAFavoritesSettingsItem *>

@end
