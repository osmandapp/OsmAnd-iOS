//
//  OAExportSettingsType.h
//  OsmAnd
//
//  Created by Anna Bibyk on 23.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAExportSettingsType) {
    EOAExportSettingsTypeUnknown = -1,
    EOAExportSettingsTypeProfile = 0,
    EOAExportSettingsTypeQuickActions,
    EOAExportSettingsTypePoiTypes,
    EOAExportSettingsTypeMapSources,
    EOAExportSettingsTypeCustomRendererStyles,
    EOAExportSettingsTypeCustomRouting,
    EOAExportSettingsTypeGPX,
    EOAExportSettingsTypeMapFiles,
    EOAExportSettingsTypeAvoidRoads,
    EOAExportSettingsTypeFavorites,
    EOAExportSettingsTypeOsmNotes,
    EOAExportSettingsTypeOsmEdits
};

@interface OAExportSettingsType : NSObject

+ (NSString * _Nullable) typeName:(EOAExportSettingsType)type;
+ (EOAExportSettingsType) parseType:(NSString *)typeName;

@end

NS_ASSUME_NONNULL_END
