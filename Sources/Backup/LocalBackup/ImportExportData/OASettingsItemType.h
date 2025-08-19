//
//  OASettingsItemType.h
//  OsmAnd
//
//  Created by Anna Bibyk on 23.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOASettingsItemType) {
    EOASettingsItemTypeUnknown = -1,
    EOASettingsItemTypeGlobal = 0,
    EOASettingsItemTypeProfile,
    EOASettingsItemTypePlugin,
    EOASettingsItemTypeData,
    EOASettingsItemTypeFile,
    EOASettingsItemTypeResources,
    EOASettingsItemTypeGpx,
    EOASettingsItemTypeQuickActions,
    EOASettingsItemTypePoiUIFilters,
    EOASettingsItemTypeMapSources,
    EOASettingsItemTypeAvoidRoads,
    EOASettingsItemTypeSuggestedDownloads,
    EOASettingsItemTypeDownloads,
    EOASettingsItemTypeOsmNotes,
    EOASettingsItemTypeOsmEdits,
    EOASettingsItemTypeFavorites,
    EOASettingsItemTypeActiveMarkers,
    EOASettingsItemTypeHistoryMarkers,
    EOASettingsItemTypeSearchHistory,
    EOASettingsItemTypeNavigationHistory,
    EOASettingsItemTypeColorPalette     //don't exist in android
    //ONLINE_ROUTING_ENGINES
    //ITINERARY_GROUPS
};

@interface OASettingsItemType : NSObject

+ (NSString * _Nullable) typeName:(EOASettingsItemType)type;
+ (EOASettingsItemType) parseType:(NSString *)typeName;

@end

NS_ASSUME_NONNULL_END
