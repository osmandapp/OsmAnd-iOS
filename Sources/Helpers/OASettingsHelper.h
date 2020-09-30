//
//  OASettingsHelper.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/settings/backend/SettingHelper.java
//  git revision 55f848becdd8c050f759571ea46966ee45fb613a

#import <Foundation/Foundation.h>
#import "OAWorldRegion.h"

NS_ASSUME_NONNULL_BEGIN

@class OAImportAsyncTask, OAExportAsyncTask, OACheckDuplicates, OALocalResourceItem;
@class OASettingsItem;
@class OAQuickAction, OAPOIUIFilter, OAAvoidRoadInfo, OAApplicationMode, OAApplicationModeBean;

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
FOUNDATION_EXTERN NSInteger const kSettingsHelperErrorCodeEmptyJson;

typedef enum : NSInteger {
    EOASettingsItemTypeUnknown = -1,
    EOASettingsItemTypeGlobal = 0,
    EOASettingsItemTypeProfile,
    EOASettingsItemTypePlugin,
    EOASettingsItemTypeData,
    EOASettingsItemTypeFile,
    EOASettingsItemTypeResources,
    EOASettingsItemTypeQuickActions,
    EOASettingsItemTypePoiUIFilters,
    EOASettingsItemTypeMapSources,
    EOASettingsItemTypeAvoidRoads,
    EOASettingsItemTypeSuggestedDownloads,
    EOASettingsItemTypeDownloads
} EOASettingsItemType;

typedef enum : NSUInteger {
    EOAImportTypeCollect = 0,
    EOAImportTypeCheckDuplicates,
    EOAImportTypeImport
} EOAImportType;

@interface OASettingsItemType : NSObject

+ (NSString * _Nullable) typeName:(EOASettingsItemType)type;
+ (EOASettingsItemType) parseType:(NSString *)typeName;

@end

@interface OASettingsHelper : NSObject

@property (nonatomic) OAImportAsyncTask* importTask;
@property (nonatomic) NSMutableDictionary<NSString*, OAExportAsyncTask*>* exportTasks;

+ (OASettingsHelper *) sharedInstance;

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName settingsItem:(OASettingsItem *)item exportItemFiles:(BOOL)exportItemFiles;

@end

#pragma mark - OASettingsItem

@class OASettingsItemReader, OASettingsItemWriter;

@interface OASettingsItem : NSObject

@property (nonatomic, readonly) EOASettingsItemType type;
@property (nonatomic, readonly) NSString *pluginId;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *publicName;
@property (nonatomic) NSString *fileName;
@property (nonatomic, readonly) NSString *defaultFileName;
@property (nonatomic, readonly) NSString *defaultFileExtension;

@property (nonatomic, readwrite) NSMutableArray<NSString *> *warnings;
@property (nonatomic, assign) BOOL shouldReplace;

- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error;

- (BOOL) shouldReadOnCollecting;
- (BOOL) exists;
- (void) apply;
- (BOOL) applyFileName:(NSString *)fileName;
+ (EOASettingsItemType) parseItemType:(id)json error:(NSError * _Nullable *)error;
- (NSDictionary *) getSettingsJson;

- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

- (void) writeToJson:(id)json;
- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value;
- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs;
- (void) applyRoutingPreferences:(NSDictionary<NSString *,NSString *> *)prefs;

@end

#pragma mark - OASettingsItemReader

@interface OASettingsItemReader<__covariant ObjectType : OASettingsItem *> : NSObject

@property (nonatomic, readonly) ObjectType item;

- (instancetype) initWithItem:(ObjectType)item;
- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error;

@end

#pragma mark - OASettingsItemWriter

@interface OASettingsItemWriter<__covariant ObjectType : OASettingsItem *> : NSObject

@property (nonatomic, readonly) ObjectType item;

- (instancetype) initWithItem:(ObjectType)item;
- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error;

@end

#pragma mark - OASettingsItemJsonReader

@interface OASettingsItemJsonReader : OASettingsItemReader<OASettingsItem *>

@end

#pragma mark - OASettingsItemJsonWriter

@interface OASettingsItemJsonWriter : OASettingsItemWriter<OASettingsItem *>

@end

#pragma mark - OAGlobalSettingsItem

@interface OAGlobalSettingsItem : OASettingsItem

@end

#pragma mark - OAProfileSettingsItem

@interface OAProfileSettingsItem : OASettingsItem

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) OAApplicationModeBean *modeBean;

+ (NSString *) getRendererByName:(NSString *)rendererName;
+ (NSString *) getRendererStringValue:(NSString *)renderer;
- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;
- (instancetype _Nullable) initWithJsonWithoutBackup:(id)json error:(NSError * _Nullable *)error;

@end

#pragma mark - OAPluginSettingsItem

@interface OAPluginSettingsItem : OASettingsItem

@end

#pragma mark - OADataSettingsItem

@interface OADataSettingsItem : OASettingsItem

@property (nonatomic) NSData *data;

- (instancetype) initWithName:(NSString *)name;
- (instancetype) initWithData:(NSData *)data name:(NSString *)name;

@end

#pragma mark - OADataSettingsItemReader

@interface OADataSettingsItemReader : OASettingsItemReader<OADataSettingsItem *>

@end

#pragma mark - OADataSettingsItemWriter

@interface OADataSettingsItemWriter : OASettingsItemWriter<OADataSettingsItem *>

@end

#pragma mark - OAFileSettingsItemFileSubtype

typedef enum : NSInteger {
    EOASettingsItemFileSubtypeUnknown = -1,
    EOASettingsItemFileSubtypeOther = 0,
    EOASettingsItemFileSubtypeRoutingConfig,
    EOASettingsItemFileSubtypeRenderingStyle,
    EOASettingsItemFileSubtypeObfMap,
    EOASettingsItemFileSubtypeTilesMap,
    EOASettingsItemFileSubtypeGpx,
    EOASettingsItemFileSubtypeVoice,
    EOASettingsItemFileSubtypeTravel,
    EOASettingsItemFileSubtypesCount
} EOASettingsItemFileSubtype;

@interface OAFileSettingsItemFileSubtype : NSObject

+ (NSString *) getSubtypeName:(EOASettingsItemFileSubtype)subtype;
+ (NSString *) getSubtypeFolder:(EOASettingsItemFileSubtype)subtype;
+ (EOASettingsItemFileSubtype) getSubtypeByName:(NSString *)name;
+ (EOASettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName;

@end
    
#pragma mark - OAFileSettingsItem

@interface OAFileSettingsItem : OASettingsItem

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, readonly) EOASettingsItemFileSubtype subtype;

- (instancetype _Nullable) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error;
- (BOOL) exists;
- (NSString *) renameFile:(NSString *)file;
- (NSString *) getPluginPath;

@end

#pragma mark - ResourcesSettingsItem

@interface OAResourcesSettingsItem : OAFileSettingsItem

@end

#pragma mark - SuggestedDownloadsItem

@interface OASuggestedDownloadsItem : OASettingsItem

- (instancetype) initWithScopeId:(NSString *)scopeId searchType:(NSString *)searchType names:(NSMutableArray<NSString *> *)names limit:(int)limit;
- (void) initialization;
- (NSString *) getScopeId;
- (NSString *) getSearchType;
- (NSMutableArray<NSString *> *) getNames;
- (int) getLimit;
- (EOASettingsItemType) type;
- (NSString *) name;
- (NSString *) publicName;
- (NSMutableArray<OASuggestedDownloadsItem *> *) getItems;
- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error;
- (void) writeItemsToJson:(id)json;

@end

#pragma mark - DownloadsItem

@interface OADownloadsItem : OASettingsItem

- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error;
- (void) initialization;
- (EOASettingsItemType) type;
- (NSString *) name;
- (NSString *) publicName;
- (NSMutableArray<OAWorldRegion *> *) getItems;
//- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error;
//- (void) writeItemsToJson:(id)json;

@end

#pragma mark - OAFileSettingsItemReader

@interface OAFileSettingsItemReader : OASettingsItemReader<OAFileSettingsItem *>

@end

#pragma mark - OAFileSettingsItemWriter

@interface OAFileSettingsItemWriter : OASettingsItemWriter<OAFileSettingsItem *>

@end

#pragma mark - OACollectionSettingsItem

@interface OACollectionSettingsItem<ObjectType> : OASettingsItem

@property (nonatomic, readonly) NSArray<ObjectType> *items;
@property (nonatomic, readonly) NSArray<ObjectType> *appliedItems;
@property (nonatomic, readonly) NSArray<ObjectType> *duplicateItems;
@property (nonatomic, readonly) NSArray<ObjectType> *existingItems;

- (instancetype) initWithItems:(NSArray<id> *)items settingsItem:(OASettingsItem  * _Nullable )baseItem;
- (NSArray<ObjectType> *) processDuplicateItems;
- (NSArray<ObjectType> *) getNewItems;
- (BOOL) isDuplicate:(ObjectType)item;
- (ObjectType) renameItem:(ObjectType)item;

@end

#pragma mark - OAQuickActionsSettingsItem

@interface OAQuickActionsSettingsItem : OACollectionSettingsItem<OAQuickAction *>

@end

#pragma mark - OAPoiUiFilterSettingsItem

@interface OAPoiUiFilterSettingsItem : OACollectionSettingsItem<OAPOIUIFilter *>

@end

#pragma mark - OAMapSourcesSettingsItem

@interface OAMapSourcesSettingsItem : OACollectionSettingsItem<OALocalResourceItem *>

@end

#pragma mark - OAAvoidRoadsSettingsItem

@interface OAAvoidRoadsSettingsItem : OACollectionSettingsItem<OAAvoidRoadInfo *>

@end

NS_ASSUME_NONNULL_END
