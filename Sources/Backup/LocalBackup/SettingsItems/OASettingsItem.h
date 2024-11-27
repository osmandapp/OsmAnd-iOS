//
//  OASettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"
#import "OASettingsItemType.h"

NS_ASSUME_NONNULL_BEGIN

static const NSInteger APPROXIMATE_PREFERENCE_SIZE_BYTES = 60;

FOUNDATION_EXTERN NSString *const kSettingsItemErrorDomain;
FOUNDATION_EXTERN NSInteger const kSettingsItemErrorCodeAlreadyRead;

@class OASGpxFile, OACommonPreference;

@interface OASettingsItem : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *fileName;
@property (nonatomic, readonly) EOASettingsItemType type;
@property (nonatomic, readonly) NSString *pluginId;
@property (nonatomic, readonly) NSString *defaultFileName;
@property (nonatomic, readonly) NSString *defaultFileExtension;

@property (nonatomic, assign) long localModifiedTime;
@property (nonatomic, assign) long lastModifiedTime;

@property (nonatomic, readonly) NSMutableArray<NSString *> *warnings;
@property (nonatomic, assign) BOOL shouldReplace;
@property (nonatomic, assign) BOOL read;

- (nullable instancetype) initWithJson:(id)json error:(NSError * _Nullable *)error;
- (instancetype) initWithBaseItem:(OASettingsItem *)baseItem;
- (void) initialization;

- (BOOL) shouldReadOnCollecting;
- (BOOL) exists;
- (void) apply;
- (void) remove;
- (void) applyAdditionalParams:(NSString *)filePath reader:(OASettingsItemReader *)reader;
- (BOOL) applyFileName:(NSString *)fileName;
+ (EOASettingsItemType) parseItemType:(id)json error:(NSError * _Nullable *)error;
- (long) getEstimatedSize;
- (NSString *)getPublicName;

- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

- (void) readFromJson:(id)json error:(NSError * _Nullable *)error;
- (void) writeToJson:(id)json;
- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error;
- (void) writeItemsToJson:(id)json;

//TODO: delete?
//- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value;

//- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs;
//- (void) applyRoutingPreferences:(NSDictionary<NSString *,NSString *> *)prefs;

//TODO: new
- (void) readPreferenceFromJson:(OACommonPreference *)preference json:(NSDictionary<NSString *, NSString *> *)json;
- (void) readPreferencesFromJson:(NSDictionary<NSString *, NSString *> *)json;


- (OASettingsItemReader *) getJsonReader;
- (OASettingsItemWriter *) getJsonWriter;
- (OASettingsItemWriter *) getGpxWriter:(OASGpxFile *)gpxFile;

@end

@interface OAOsmandSettingsJsonReader : OASettingsItemReader<OASettingsItem *>

@end

//TODO: delete?

//@interface OASettingsItemJsonReader : OAOsmandSettingsJsonReader
//
//@end

@interface OASettingsItemJsonWriter : OASettingsItemWriter<OASettingsItem *>

@end

@interface OASettingsItemGpxWriter : OASettingsItemWriter<OASettingsItem *>

- (instancetype) initWithItem:(OASettingsItem *)item gpxDocument:(OASGpxFile *)gpxFile;

@end

NS_ASSUME_NONNULL_END
