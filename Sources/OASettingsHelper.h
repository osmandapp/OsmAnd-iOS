//
//  OASettingsHelper.h
//  OsmAnd
//
//  Created by Anna Bibyk on 23.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/SettingHelper.java
//  git revision 1b3247780ad2cd0119f09c89537a8f8138806481
//
//  Fully ported: OASettingsItemReader, OASettingsItemWriter, OAProfileSettingsItem, OAGlobalSettingsItem
//  To implement: EOASettingsItemTypePlugin, EOASettingsItemTypeData, EOASettingsItemTypeFile, EOASettingsItemTypeResources,
//                EOASettingsItemTypeQuickActions, EOASettingsItemTypePoiUIFilters, EOASettingsItemTypeMapSources, EOASettingsItemTypeAvoidRoads

#import <Foundation/Foundation.h>

@class OAImportAsyncTask, OAExportAsyncTask;
@class OASettingsItem;

@protocol OASettingsImportExportDelegate <NSObject>

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items;
- (void) onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items;
- (void) onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed;
- (void) onDuplicatesChecked:(NSArray<OASettingsItem *>*)duplicates items:(NSArray<OASettingsItem *>*)items;

@end

FOUNDATION_EXTERN NSString *const kSettingsHelperErrorDomain;

FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeNoTypeField;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeIllegalType;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeUnknownFileSubtype;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeUnknownFilePath;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeEmptyJson;

#pragma mark - OASettingsHelper

typedef NS_ENUM(NSInteger, EOAImportType) {
    EOAImportTypeCollect = 0,
    EOAImportTypeCheckDuplicates,
    EOAImportTypeImport
};

@class OAExportSettingsCategory, OASettingsCategoryItems, OAExportSettingsType, OASettingsItem;

@interface OASettingsHelper : NSObject

@property (nonatomic) OAImportAsyncTask* importTask;
@property (nonatomic) NSMutableDictionary<NSString*, OAExportAsyncTask*>* exportTasks;

+ (OASettingsHelper *) sharedInstance;

+ (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *) getSettingsToOperateByCategory:(NSArray<OASettingsItem *> *)items importComplete:(BOOL)importComplete;
+ (NSDictionary<OAExportSettingsType *, NSArray *> *) getSettingsToOperate:(NSArray<OASettingsItem *> *)settingsItems importComplete:(BOOL)importComplete;

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName settingsItem:(OASettingsItem *)item exportItemFiles:(BOOL)exportItemFiles;

@end
