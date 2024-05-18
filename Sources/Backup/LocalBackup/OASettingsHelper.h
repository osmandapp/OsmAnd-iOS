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

static const NSInteger kVersion = 2;

@class OAImportAsyncTask, OAExportAsyncTask;
@class OASettingsItem;

@protocol OASettingsImportExportDelegate <NSObject>

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items;
- (void) onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items;
- (void) onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed;
- (void) onDuplicatesChecked:(NSArray<OASettingsItem *>*)duplicates items:(NSArray<OASettingsItem *>*)items;

@end

@protocol OACollectListener <NSObject>

- (void) onCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items;

@end

@protocol OAImportListener <NSObject>

- (void) onImportProgressUpdate:(NSInteger)value uploadedKb:(NSInteger)uploadedKb;
- (void) onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work;
- (void) onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value;
- (void) onImportItemFinished:(NSString *)type fileName:(NSString *)fileName;
- (void) onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items;

@end

@protocol OACheckDuplicatesListener <NSObject>

- (void) onDuplicatesChecked:(NSArray *)duplicates items:(NSArray<OASettingsItem *> *)items;

@end

@protocol OAExportProgressListener <NSObject>

- (void) updateProgress:(int)value;

@end

FOUNDATION_EXTERN NSString *const kSettingsHelperErrorDomain;

FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeNoTypeField;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeIllegalType;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeUnknownFileSubtype;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeUnknownFilePath;
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeEmptyJson;

#pragma mark - OASettingsHelper

typedef NS_ENUM(NSInteger, EOAImportType) {
    EOAImportTypeUndefined = -1,
    EOAImportTypeCollect = 0,
    EOAImportTypeCollectAndRead,
    EOAImportTypeImportForceRead,
    EOAImportTypeCheckDuplicates,
    EOAImportTypeImport
};

@class OAExportSettingsCategory, OASettingsCategoryItems, OAExportSettingsType, OASettingsItem;

@interface OASettingsHelper : NSObject

+ (OASettingsHelper *) sharedInstance;

- (OAImportAsyncTask *)getImportTask;
- (void)setImportTask:(OAImportAsyncTask *)importTask;
- (void)removeExportTaskForFilepath:(NSString *)filePath;

+ (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *)getSettingsToOperateByCategory:(NSArray<OASettingsItem *> *)items
                                                                                         importComplete:(BOOL)importComplete
                                                                                          addEmptyItems:(BOOL)addEmptyItems;

+ (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *)getSettingsToOperateByCategory:(NSDictionary<OAExportSettingsType *, NSArray *> *)settingsToOperate
                                                                                          addEmptyItems:(BOOL)addEmptyItems;

+ (NSDictionary<OAExportSettingsType *, NSArray *> *)getSettingsToOperate:(NSArray<OASettingsItem *> *)settingsItems
                                                           importComplete:(BOOL)importComplete
                                                            addEmptyItems:(BOOL)addEmptyItems;

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version silent:(BOOL)silent;
- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version onComplete:(void(^)(BOOL succeed, NSArray<OASettingsItem *> *items))onComplete;
- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate onComplete:(void(^)(BOOL succeed, NSArray<OASettingsItem *> *items))onComplete silent:(BOOL)silent;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName settingsItem:(OASettingsItem *)item exportItemFiles:(BOOL)exportItemFiles delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles extensionsFilter:(NSString *)extensionsFilter delegate:(id<OASettingsImportExportDelegate>)delegate;

- (NSArray <OASettingsItem *>*) prepareSettingsItems:(NSArray *)data settingsItems:(NSArray<OASettingsItem *> *)settingsItems doExport:(BOOL)doExport;

- (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *) getSettingsByCategory:(BOOL)addProfiles;

- (NSArray<OASettingsItem *> *) getFilteredSettingsItems:(NSArray<OAExportSettingsType *> *)settingsTypes addProfiles:(BOOL)addProfiles doExport:(BOOL)doExport;

- (NSInteger)getCurrentBackupVersion;
- (void)setCurrentBackupVersion:(NSInteger)version;

@end
