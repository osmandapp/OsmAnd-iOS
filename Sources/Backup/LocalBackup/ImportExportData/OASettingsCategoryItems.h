//
//  OASettingsCategoryItems.h
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAExportSettingsType;

@interface OASettingsCategoryItems : NSObject

- (instancetype) initWithItemsMap:(NSDictionary<OAExportSettingsType *, NSArray *> *)itemsMap;

- (NSArray<OAExportSettingsType *> *) getTypes;
- (NSArray *) getItemsForType:(OAExportSettingsType *)type;

@end

NS_ASSUME_NONNULL_END
