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

#define APPROXIMATE_PREFERENCE_SIZE_BYTES 60

FOUNDATION_EXTERN NSString *const kSettingsItemErrorDomain;
FOUNDATION_EXTERN NSInteger const kSettingsItemErrorCodeAlreadyRead;

@class OAGPXDocument;

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

- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error;
- (instancetype) initWithBaseItem:(OASettingsItem *)baseItem;
- (void) initialization;

- (BOOL) shouldReadOnCollecting;
- (BOOL) exists;
- (void) apply;
- (void) remove;
- (void) applyAdditionalParams:(NSString *)filePath;
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
- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value;
- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs;
- (void) applyRoutingPreferences:(NSDictionary<NSString *,NSString *> *)prefs;
- (OASettingsItemReader *) getJsonReader;
- (OASettingsItemWriter *) getJsonWriter;
- (OASettingsItemWriter *) getGpxWriter:(OAGPXDocument *)gpxFile;

@end

@interface OASettingsItemJsonReader : OASettingsItemReader<OASettingsItem *>

@end

@interface OASettingsItemJsonWriter : OASettingsItemWriter<OASettingsItem *>

@end

@interface OASettingsItemGpxWriter : OASettingsItemWriter<OASettingsItem *>

- (instancetype) initWithItem:(OASettingsItem *)item gpxDocument:(OAGPXDocument *)gpxFile;

@end

NS_ASSUME_NONNULL_END
