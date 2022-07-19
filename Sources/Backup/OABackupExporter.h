//
//  OABackupExporter.h
//  OsmAnd Maps
//
//  Created by Paul on 16.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAItemExporter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OANetworkExportProgressListener <NSObject>

- (void) itemExportStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work;

- (void) updateItemProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress;

- (void) itemExportDone:(NSString *)type fileName:(NSString *)fileName;

- (void) updateGeneralProgress:(NSInteger)uploadedItems uploadedKb:(NSInteger)uploadedKb;

- (void) networkExportDone:(NSDictionary<NSString *, NSString *> *)errors;

@end

@interface OABackupExporter : OAItemExporter

- (instancetype) initWithListener:(id<OANetworkExportProgressListener>)listener;

- (void) addItemToDelete:(OASettingsItem *)item;
- (void) addOldItemToDelete:(OASettingsItem *)item;

- (NSArray<OASettingsItem *> *)getItemsToDelete;
- (NSArray<OASettingsItem *> *)getOldItemsToDelete;

- (void) export;

@end

NS_ASSUME_NONNULL_END
