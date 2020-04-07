//
//  OASettingsHelper.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndApp.h"
#import "OsmAndAppProtocol.h"
#import "OsmAndAppCppProtocol.h"
#import "OASettingsImport.h"
#import "OASettingsExport.h"
#import "OASettingsCollect.h"
#import "OACheckDuplicates.h"
#import "OAQuickAction.h"
#import "OAQuickActionRegistry.h"
#import "OAPOIUIFilter.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesBaseViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAAvoidSpecificRoads.h"
#import "OAAppSettings.h"
#import "OADebugSettings.h"

#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

@class OAImportAsyncTask;
@class OAExportAsyncTask;

typedef enum : NSUInteger {
    EOAGlobal = 0,
    EOAProfile,
    EOAPlugin,
    EOAData,
    EOAFile,
    EOAQuickAction,
    EOAPoiUIFilters,
    EOAMapSources,
    EOAAvoidRoads
} EOASettingsItemType;

typedef enum : NSUInteger {
    EOACollect = 0,
    EOACheckDuplicates,
    EOAImport
} EOAImportType;

@interface OASettingsHelper : NSObject

@property(nonatomic, retain) OAImportAsyncTask* importTask;
@property(nonatomic, retain) NSMutableDictionary<NSString*, OAExportAsyncTask*>* exportTask;

+ (OASettingsHelper*)sharedInstance;

- (void) finishImport:(OASettingsImport *)listener success:(BOOL)success items:(NSMutableArray*)items;
- (void) collectSettings:(NSString*)settingsFile latestChanges:(NSString*)latestChanges version:(NSInteger)version listener:(OASettingsCollect*)listener;
- (void) checkDuplicates:(NSString *)settingsFile items:(NSMutableArray <OASettingsItem*> *)items selectedItems:(NSMutableArray <OASettingsItem*> *)selectedItems listener:(OACheckDuplicates*)listener;
- (void) importSettings:(NSString *)settingsFile items:(NSMutableArray <OASettingsItem*> *)items latestChanges:(NSString*)latestChanges version:(NSInteger)version listener:(OASettingsImport*)listener;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName listener:(OASettingsExport*)listener items:(NSMutableArray <OASettingsItem*> *)items;
- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName listener:(OASettingsExport*)listener;

@end

#pragma mark - OASettingsItem

@interface OASettingsItem : NSObject

@property (nonatomic, assign) EOASettingsItemType type;
@property (nonatomic, assign) BOOL shouldReplace;

- (instancetype) initWithType:(EOASettingsItemType)type;
- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary*)json;
- (NSString *) getFileName;
- (BOOL) shouldReadOnCollecting;
- (NSString *) getName;
- (BOOL) exists;
- (void) apply;
- (EOASettingsItemType) parseItemType:(NSDictionary*)json;
- (void) readFromJSON:(NSDictionary*)json;
- (void) writeToJSON:(NSDictionary*)json;
- (NSString *)toJSON;

@end

#pragma mark - OASettingsItemReader

@interface OASettingsItemReader<ObjectType : OASettingsItem *> : NSObject

- (instancetype) initWithItem:(ObjectType)item;
- (void) readFromStream:(NSInputStream*)inputStream;

@end

#pragma mark - OASettingsItemWriter

@interface OASettingsItemWriter<ObjectType : OASettingsItem *> : NSObject

- (instancetype) initWithItem:(ObjectType)item;
- (BOOL) writeToStream:(NSOutputStream*)outputStream;

@end

#pragma mark - OAStreamSettingsItemReader

@interface OAStreamSettingsItemReader : OASettingsItemReader<OASettingsItem *>

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAStreamSettingsItemWriter

@interface OAStreamSettingsItemWriter : OASettingsItemWriter<OASettingsItem *>

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAStreamSettingsItem

@interface OAStreamSettingsItem : OASettingsItem

@property (nonatomic, retain, readonly) NSString* name;

- (instancetype) initWithType:(EOASettingsItemType)type name:(NSString*)name;
- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary*)json;
- (instancetype) initWithType:(EOASettingsItemType)type inputStream:(NSInputStream*)inputStream name:(NSString*)name;
- (NSString *) getPublicName;
- (void) readFromJSON:(NSDictionary *)json;
- (OASettingsItemWriter*) getWriter;


@end

#pragma mark - OADataSettingsItemReader

@interface OADataSettingsItemReader: OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OADataSettingsItem

@interface OADataSettingsItem : OAStreamSettingsItem

@property (nonatomic, retain) NSData *data;

- (instancetype) initWithName:(NSString *)name;
- (instancetype) initWithJson:(NSDictionary *)json;
- (instancetype) initWithData:(NSData *)data name:(NSString *)name;
- (NSString *) getFileName;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OAFileSettingsItemReader

@interface OAFileSettingsItemReader: OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end


#pragma mark - OAFileSettingsItem

@interface OAFileSettingsItem : OAStreamSettingsItem

@property (nonatomic, retain) NSString *filePath;

- (instancetype) initWithFile:(NSString *)filePath;
- (instancetype) initWithJSON:(NSDictionary*)json;
- (NSString *) getFileName;
- (BOOL) exists;
- (NSString *) renameFile:(NSString*)file;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OACollectionSettingsItem

@interface OACollectionSettingsItem<ObjectType> : OASettingsItem

@property(nonatomic, retain, readonly) NSMutableArray<ObjectType> *items;
@property(nonatomic, retain, readonly) NSMutableArray<ObjectType> *duplicateItems;
@property(nonatomic, retain) NSArray<ObjectType> *existingItems;

- (instancetype) initWithType:(EOASettingsItemType)type items:(NSMutableArray<id>*) items;
- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary *)json;
- (NSMutableArray<id> *) excludeDuplicateItems;

@end

#pragma mark - OAQuickActionSettingsItem

@interface OAQuickActionSettingsItem : OACollectionSettingsItem<OAQuickAction *>

- (instancetype) initWithItems:(NSMutableArray<id> *)items;
- (instancetype) initWithJSON:(NSDictionary *)json;
- (BOOL) isDuplicate:(OAQuickAction *)item;
- (OAQuickAction *) renameItem:(OAQuickAction *)item;
- (void) apply;
- (BOOL) shouldReadOnCollecting;
- (NSString *) getName;
- (NSString *) getPublicName;
- (NSString *) getFileName;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OAMapSourcesSettingsItemReader

@interface OAQuickActionSettingsItemReader : OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAMapSourcesSettingsItemWriter

@interface OAQuickActionSettingsItemWriter : OAStreamSettingsItemWriter

- (instancetype)initWithItem:(OASettingsItem *)item;

@end


#pragma mark - OAPoiUiFilterSettingsItem

@interface OAPoiUiFilterSettingsItem : OACollectionSettingsItem<OAPOIUIFilter *>

- (instancetype) initWithItem:(NSMutableArray<id>*)items;
- (instancetype) initWithJSON:(NSDictionary*)json;
- (void) apply;
- (BOOL) isDuplicate:(OAPOIUIFilter*)item;
- (OAPOIUIFilter *) renameItem:(OAPOIUIFilter *)item;
- (NSString *)getName;
- (NSString *)getPublicName;
- (BOOL) shouldReadOnCollecting;
- (NSString *) getFileName;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OAPoiUiFilterSettingsItemReader

@interface OAPoiUiFilterSettingsItemReader : OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAPoiUiFilterSettingsItemWriter

@interface OAPoiUiFilterSettingsItemWriter : OAStreamSettingsItemWriter

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAMapSourcesSettingsItem

@interface OAMapSourcesSettingsItem : OACollectionSettingsItem<LocalResourceItem *>

- (instancetype) initWithItems:(NSMutableArray<id>*)items;
- (instancetype) initWithJSON:(NSDictionary *)json;
- (void) apply;
- (NSString *)getName;
- (NSString *)getPublicName;
- (BOOL) shouldReadOnCollecting;
- (NSString *)getFileName;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OAMapSourcesSettingsItemReader

@interface OAMapSourcesSettingsItemReader : OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAMapSourcesSettingsItemWriter

@interface OAMapSourcesSettingsItemWriter : OAStreamSettingsItemWriter

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAAvoidRoadsSettingsItem

@interface OAAvoidRoadsSettingsItem : OACollectionSettingsItem<OAAvoidSpecificRoads *>

- (instancetype) initWithItems:(NSMutableArray<id>*)items;
- (instancetype) initWithJSON:(NSDictionary*)json;
- (NSString *) getName;
- (NSString *) getPublicName;
- (NSString *) getFileName;
- (void) apply;
- (BOOL) isDuplicate:()item;
- (BOOL) shouldReadOnCollecting;
//- () renameItem:()item;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OAAvoidRoadsSettingsItemReader

@interface OAAvoidRoadsSettingsItemReader : OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAAvoidRoadsSettingsItemWriter

@interface OAAvoidRoadsSettingsItemWriter : OAStreamSettingsItemWriter

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

