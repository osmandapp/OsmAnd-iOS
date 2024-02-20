//
//  OAImportBackupTask.h
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"
#import "OANetworkSettingsHelper.h"
#import "OAPrepareBackupResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAItemProgressInfo : NSObject

- (instancetype) initWithType:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress work:(NSInteger)work finished:(BOOL)finished;

@property (nonatomic, assign) NSInteger work;
@property (nonatomic, assign, readonly) NSInteger value;
@property (nonatomic, assign, readonly) BOOL finished;

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *fileName;

@end

@interface OAImportBackupTask : NSOperation

@property (nonatomic, assign) EOAImportType importType;
@property (nonatomic, weak) id<OAImportListener> importListener;
@property (nonatomic, weak) id<OACheckDuplicatesListener> duplicatesListener;

@property (nonatomic, readonly) NSArray<OASettingsItem *> *items;
@property (nonatomic, readonly) NSArray<OASettingsItem *> *selectedItems;
@property (nonatomic, readonly) NSArray *duplicates;

@property (nonatomic, readonly) NSInteger generalProgress;
@property (nonatomic, readonly) NSInteger maxProgress;

+ (NSInteger) calculateMaxProgress;

- (instancetype) initWithKey:(NSString *)key
             collectListener:(id<OABackupCollectListener>)collectListener
                    readData:(BOOL)readData;

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
                   filesType:(EOARemoteFilesType)filesType
              importListener:(id<OAImportListener>)importListener
               forceReadData:(BOOL)forceReadData
               shouldReplace:(BOOL)shouldReplace
              restoreDeleted:(BOOL)restoreDeleted;

- (instancetype) initWithKey:(NSString *)key
                       items:(NSArray<OASettingsItem *> *)items
               selectedItems:(NSArray<OASettingsItem *> *)selectedItems
          duplicatesListener:(id<OACheckDuplicatesListener>)duplicatesListener;

- (OAItemProgressInfo *) getItemProgressInfo:(NSString *)type fileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
