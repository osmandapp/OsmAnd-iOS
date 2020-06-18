//
//  OASettingsExporter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem, OASettingsExport;

@interface OASettingsExporter : NSObject

- (instancetype) init;
- (void) addSettingsItem:(OASettingsItem *)item;
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value;
- (void) exportSettings:(NSString *)file error:(NSError * _Nullable *)error;

@end

#pragma mark - OAExportAsyncTask

@interface OAExportAsyncTask : NSObject

- (instancetype) initWithFile:(NSString *)settingsFile listener:(OASettingsExport * _Nullable)listener items:(NSArray<OASettingsItem *> *)items;
- (void) execute;

@end

NS_ASSUME_NONNULL_END
