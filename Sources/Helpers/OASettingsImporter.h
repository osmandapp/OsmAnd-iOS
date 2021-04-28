//
//  OASettingsImporter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"

#define kTmpProfileFolder @"tmpProfileData"

typedef void(^ OAOnImportComplete)(BOOL succeed, NSArray<OASettingsItem *> *items);
typedef void(^ OAOnSettingsCollected)(BOOL succeed, BOOL empty, NSArray<OASettingsItem *> *items);
typedef void(^ OAOnDuplicatesChecked)(NSArray<OASettingsItem *> *duplicates, NSArray<OASettingsItem *> *items);

#pragma mark - OASettingsImporter

@class OASettingsItem;

@interface OASettingsImporter : NSObject

@end

#pragma mark - OASettingsItemsFactory

@interface OASettingsItemsFactory : NSObject

- (instancetype) initWithJSON:(NSString *)jsonStr;
- (NSArray<OASettingsItem *> *) getItems;

@end

#pragma mark - OAImportAsyncTask

@interface OAImportAsyncTask : NSObject

@property (nonatomic, weak) id<OASettingsImportExportDelegate> delegate;
@property (nonatomic, copy) OAOnImportComplete onImportComplete;
@property (nonatomic, copy) OAOnSettingsCollected onSettingsCollected;
@property (nonatomic, copy) OAOnDuplicatesChecked onDuplicatesChecked;

- (instancetype) initWithFile:(NSString *)filePath latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) execute;
- (void) executeWithCompletionBlock:(void(^)(BOOL succeed, NSArray<OASettingsItem *> *items))onComplete;
- (NSArray<OASettingsItem *> *) getItems;
- (NSString *) getFile;
- (EOAImportType) getImportType;
- (BOOL) isImportDone;
- (NSArray<id> *) getDuplicates;
- (NSArray<OASettingsItem *> *) getSelectedItems;
- (NSArray<id> *) getDuplicatesData:(NSArray<OASettingsItem *> *)items;

@end

#pragma mark - OAImportItemsAsyncTask

@interface OAImportItemsAsyncTask : NSObject

- (instancetype) initWithFile:(NSString *)file items:(NSArray<OASettingsItem *> *)items;
- (void) execute;

@end
