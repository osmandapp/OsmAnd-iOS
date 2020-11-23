//
//  OASettingsHelper.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/SettingHelper.java
//  git revision 1b3247780ad2cd0119f09c89537a8f8138806481
//
//  Fully ported: OASettingsItemReader, OASettingsItemWriter, OAProfileSettingsItem, OAGlobalSettingsItem
//  To implement: EOASettingsItemTypePlugin, EOASettingsItemTypeData, EOASettingsItemTypeFile, EOASettingsItemTypeResources,
//                EOASettingsItemTypeQuickActions, EOASettingsItemTypePoiUIFilters, EOASettingsItemTypeMapSources, EOASettingsItemTypeAvoidRoads

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAImportAsyncTask, OAExportAsyncTask, OACheckDuplicates, OALocalResourceItem;
@class OASettingsItem;
@class OAQuickAction, OAPOIUIFilter, OAAvoidRoadInfo, OAApplicationMode, OAApplicationModeBean, OAOsmNotesPoint;

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

typedef NS_ENUM(NSInteger, EOASettingsItemType) {
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
    EOASettingsItemTypeOsmNotes
};

typedef NS_ENUM(NSInteger, EOAImportType) {
    EOAImportTypeCollect = 0,
    EOAImportTypeCheckDuplicates,
    EOAImportTypeImport
};

@interface OASettingsItemType : NSObject

+ (NSString * _Nullable) typeName:(EOASettingsItemType)type;
+ (EOASettingsItemType) parseType:(NSString *)typeName;

@end

typedef NS_ENUM(NSInteger, EOAExportSettingsType) {
    EOAExportSettingsTypeUnknown = -1,
    EOAExportSettingsTypeProfile = 0,
    EOAExportSettingsTypeQuickActions,
    EOAExportSettingsTypePoiTypes,
    EOAExportSettingsTypeMapSources,
    EOAExportSettingsTypeCustomRendererStyles,
    EOAExportSettingsTypeCustomRouting,
    EOAExportSettingsTypeGPX,
    EOAExportSettingsTypeMapFiles,
    EOAExportSettingsTypeAvoidRoads,
    EOAExportSettingsTypeOsmNotes,
};

@interface OAExportSettingsType : NSObject

+ (NSString * _Nullable) typeName:(EOAExportSettingsType)type;
+ (EOAExportSettingsType) parseType:(NSString *)typeName;

@end

@interface OASettingsHelper : NSObject

@property (nonatomic) OAImportAsyncTask* importTask;
@property (nonatomic) NSMutableDictionary<NSString*, OAExportAsyncTask*>* exportTasks;

+ (OASettingsHelper *) sharedInstance;

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version;
- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName settingsItem:(OASettingsItem *)item exportItemFiles:(BOOL)exportItemFiles;

@end

#pragma mark - OASettingsItem

@class OASettingsItemReader, OASettingsItemWriter;

@interface OASettingsItem : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) EOASettingsItemType type;
@property (nonatomic, readonly) NSString *pluginId;
@property (nonatomic, readonly) NSString *publicName;
@property (nonatomic) NSString *fileName;
@property (nonatomic, readonly) NSString *defaultFileName;
@property (nonatomic, readonly) NSString *defaultFileExtension;

@property (nonatomic, readonly) NSMutableArray<NSString *> *warnings;
@property (nonatomic, assign) BOOL shouldReplace;

- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error;
- (instancetype) initWithBaseItem:(OASettingsItem *)baseItem;

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

@end

#pragma mark - OAPluginSettingsItem

@interface OAPluginSettingsItem : OASettingsItem

- (NSMutableArray<OASettingsItem *> *) getPluginDependentItems;

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

typedef NS_ENUM(NSInteger, EOASettingsItemFileSubtype) {
    EOASettingsItemFileSubtypeUnknown = -1,
    EOASettingsItemFileSubtypeOther = 0,
    EOASettingsItemFileSubtypeRoutingConfig,
    EOASettingsItemFileSubtypeRenderingStyle,
    EOASettingsItemFileSubtypeWikiMap,
    EOASettingsItemFileSubtypeSrtmMap,
    EOASettingsItemFileSubtypeObfMap,
    EOASettingsItemFileSubtypeTilesMap,
    EOASettingsItemFileSubtypeRoadMap,
    EOASettingsItemFileSubtypeGpx,
    EOASettingsItemFileSubtypeVoice,
    EOASettingsItemFileSubtypeTravel,
    EOASettingsItemFileSubtypesCount
};

@interface OAFileSettingsItemFileSubtype : NSObject

+ (NSString *) getSubtypeName:(EOASettingsItemFileSubtype)subtype;
+ (NSString *) getSubtypeFolder:(EOASettingsItemFileSubtype)subtype;
+ (EOASettingsItemFileSubtype) getSubtypeByName:(NSString *)name;
+ (EOASettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName;
+ (BOOL) isMap:(EOASettingsItemFileSubtype)type;

@end
    
#pragma mark - OAFileSettingsItem

@interface OAFileSettingsItem : OASettingsItem

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, readonly) EOASettingsItemFileSubtype subtype;

- (instancetype _Nullable) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error;
- (BOOL) exists;
- (NSString *) renameFile:(NSString *)file;
- (NSString *) getPluginPath;
- (void) installItem:(NSString *)destFilePath;
- (NSString *) getIconName;

@end

#pragma mark - ResourcesSettingsItem

@interface OAResourcesSettingsItem : OAFileSettingsItem

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

- (instancetype) initWithItems:(NSArray<ObjectType> *)items;
- (instancetype) initWithItems:(NSArray<ObjectType> *)items baseItem:(OACollectionSettingsItem<ObjectType> *)baseItem;
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

@interface OAMapSourcesSettingsItem : OACollectionSettingsItem<NSDictionary *>

@end

#pragma mark - OAAvoidRoadsSettingsItem

@interface OAAvoidRoadsSettingsItem : OACollectionSettingsItem<OAAvoidRoadInfo *>

@end

#pragma mark - OAOsmNotesSettingsItem

@interface OAOsmNotesSettingsItem : OACollectionSettingsItem<OAOsmNotesPoint *>

@end

NS_ASSUME_NONNULL_END
