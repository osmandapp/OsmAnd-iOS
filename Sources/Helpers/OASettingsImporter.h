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

- (instancetype) initWithFile:(NSString *)filePath latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) execute;
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

@property (nonatomic, weak) id<OASettingsImportExportDelegate> delegate;

- (instancetype) initWithFile:(NSString *)file items:(NSArray<OASettingsItem *> *)items;
- (void) execute;

@end
