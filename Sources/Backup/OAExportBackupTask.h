//
//  OAExportBackupTask.h
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OANetworkSettingsHelper.h"

#define APPROXIMATE_FILE_SIZE_BYTES (100 * 1024)

NS_ASSUME_NONNULL_BEGIN

@class OAItemProgressInfo;

@interface OAExportBackupTask : NSOperation

@property (nonatomic, weak) id<OABackupExportListener> listener;

@property (nonatomic, readonly) NSInteger generalProgress;
@property (nonatomic, readonly) NSInteger maxProgress;

+ (long) getEstimatedItemsSize:(NSArray<OASettingsItem *> *)items itemsToDelete:(NSArray<OASettingsItem *> *)itemsToDelete localItemsToDelete:(NSArray<OASettingsItem *> *)localItemsToDelete oldItemsToDelete:(NSArray<OASettingsItem *> *)oldItemsToDelete;

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
               itemsToDelete:(NSArray<OASettingsItem *> *)itemsToDelete
               localItemsToDelete:(NSArray<OASettingsItem *> *)localItemsToDelete
                    listener:(id<OABackupExportListener>)listener;

- (OAItemProgressInfo *) getItemProgressInfo:(NSString *)type fileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
