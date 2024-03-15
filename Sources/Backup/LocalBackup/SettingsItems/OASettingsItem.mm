//
//  OASettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"
#import "OAGPXDocument.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

NSString *const kSettingsItemErrorDomain = @"SettingsItem";
NSInteger const kSettingsItemErrorCodeAlreadyRead = 1;

@interface OASettingsItem()

@property (nonatomic) NSString *pluginId;
@property (nonatomic) NSString *defaultName;
@property (nonatomic) NSString *defaultFileExtension;
@property (nonatomic) NSMutableArray<NSString *> *warnings;

@end

@implementation OASettingsItem
{
    BOOL _fromJSON;
}

@synthesize lastModifiedTime = _lastModifiedTime;

- (instancetype) init
{
    self = [super init];
    if (self)
        [self initialization];
    
    return self;
}

- (instancetype) initWithBaseItem:(OASettingsItem *)baseItem
{
    self = [self init];
    if (self)
    {
        if (baseItem)
        {
            _pluginId = baseItem.pluginId;
            _fileName = baseItem.fileName;
        }
    }
    return self;
}
 
- (instancetype _Nullable) initWithJson:(id)json error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self initialization];
        _fromJSON = YES;
        NSError *readError;
        [self readFromJson:json error:&readError];
        if (readError)
        {
            if (error)
                *error = readError;
            return nil;
        }
    }
    return self;
}

- (void) initialization
{
    self.warnings = [NSMutableArray array];
}

- (BOOL) shouldReadOnCollecting
{
    return NO;
}

- (NSString *) defaultFileName
{
    return [self.name stringByAppendingString:self.defaultFileExtension];
}

- (NSString *) defaultFileExtension
{
    return @".json";
}

- (long)localModifiedTime
{
    return 0;
}

- (long)lastModifiedTime
{
    if (_fromJSON)
        return _lastModifiedTime;
    else if (_lastModifiedTime == 0)
        _lastModifiedTime = self.localModifiedTime;
    return _lastModifiedTime;
}

- (void)setLastModifiedTime:(long)lastModifiedTime
{
    _lastModifiedTime = lastModifiedTime;
}

- (BOOL) applyFileName:(NSString *)fileName
{
    return self.fileName && ([self.fileName hasSuffix:fileName] || [fileName hasPrefix:[self.fileName stringByAppendingString:@"/"]]);
}

- (BOOL) exists
{
    return NO;
}

- (void) apply
{
    // not implemented
}

- (void) remove
{
    // not implemented
}

- (void) applyAdditionalParams:(NSString *)filePath
{
    // not implemented
}

+ (EOASettingsItemType) parseItemType:(id)json error:(NSError * _Nullable *)error
{
    NSString *typeStr = json[@"type"];
    if (!typeStr)
    {
        *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeNoTypeField userInfo:nil];
        return EOASettingsItemTypeUnknown;
    }
    if ([typeStr isEqualToString:@"QUICK_ACTION"])
        typeStr = @"QUICK_ACTIONS";
    
    EOASettingsItemType type = [OASettingsItemType parseType:typeStr];
    if (type == EOASettingsItemTypeUnknown)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeIllegalType userInfo:nil];
    }
    return type;
}

- (void) readFromJson:(id)json error:(NSError * _Nullable *)error
{
    self.pluginId = json[@"pluginId"];
    if (json[@"name"])
        self.fileName = [NSString stringWithFormat:@"%@%@", json[@"name"], self.defaultFileExtension];
    if (json[@"file"])
        self.fileName = json[@"file"];

    NSError* readError;
    [self readItemsFromJson:json error:&readError];
    if (error && readError)
        *error = readError;
}

- (void) writeToJson:(id)json
{
    json[@"type"] = [OASettingsItemType typeName:self.type];
    if (self.pluginId.length > 0)
        json[@"pluginId"] = self.pluginId;
    
    if ([self getWriter])
    {
        if (!self.fileName || self.fileName.length == 0)
            self.fileName = self.defaultFileName;
        
        json[@"file"] = self.fileName;
    }
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    // override
}

- (void) writeItemsToJson:(id)json
{
    // override
}

- (void) readPreferenceFromJson:(NSString *)key value:(NSString *)value
{
    // override
}

- (void) applyRendererPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    // override
}

- (void) applyRoutingPreferences:(NSDictionary<NSString *, NSString *> *)prefs
{
    // override
}

- (long) getEstimatedSize
{
    return -1; // override
}

- (NSString *)getPublicName
{
    return nil; // override
}

- (OASettingsItemReader *) getJsonReader
{
    return [[OASettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getJsonWriter
{
    return [[OASettingsItemJsonWriter alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getGpxWriter:(OAGPXDocument *)gpxFile
{
    return [[OASettingsItemGpxWriter alloc] initWithItem:self gpxDocument:gpxFile];
}

- (OASettingsItemReader *) getReader
{
    return nil;
}

- (OASettingsItemWriter *) getWriter
{
    return nil;
}

- (NSUInteger) hash
{
    NSUInteger result = _type;
    result = 31 * result + (_name != nil ? [_name hash] : 0);
    result = 31 * result + (self.fileName != nil ? [self.fileName hash] : 0);
    result = 31 * result + (self.pluginId != nil ? [self.pluginId hash] : 0);
    return result;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OASettingsItem *item = (OASettingsItem *) object;
        return item.type == self.type 
        	&& (item.name == self.name || [item.name isEqualToString:self.name])
        	&& (item.fileName == self.fileName || [item.fileName isEqualToString:self.fileName])
            && (item.pluginId == self.pluginId || [item.pluginId isEqualToString:self.pluginId]);
    }
    return NO;
}

@end

#pragma mark - OASettingsItemJsonReader

@implementation OASettingsItemJsonReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }

    NSError *readError;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        
        return NO;
    }
    if (data.length == 0)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeEmptyJson userInfo:nil];
        
        return NO;
    }
    
    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    if (jsonError)
    {
        if (error)
            *error = jsonError;
        
        return NO;
    }
    NSDictionary<NSString *, NSString *> *settings = [[OAMigrationManager shared] changeJsonMigration:json];
    NSMutableDictionary<NSString *, NSString *> *rendererSettings = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSString *> *routingSettings = [NSMutableDictionary new];
    [settings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key hasPrefix:@"nrenderer_"] || [key isEqualToString:@"displayed_transport_settings"])
            [rendererSettings setObject:obj forKey:key];
        else if ([key hasPrefix:@"prouting_"])
            [routingSettings setObject:obj forKey:key];
        else
            [self.item readPreferenceFromJson:key value:obj];
    }];
    [self.item applyRendererPreferences:rendererSettings];
    [self.item applyRoutingPreferences:routingSettings];

    self.item.read = YES;
    return YES;
}

@end

#pragma mark - OASettingsItemJsonWriter

@implementation OASettingsItemJsonWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    MutableOrderedDictionary *json = [MutableOrderedDictionary dictionary];
    [self.item writeItemsToJson:json];
    if (json.count > 0)
    {
        
        NSError *writeJsonError;
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&writeJsonError];
        if (writeJsonError)
        {
            if (error)
                *error = writeJsonError;
            return NO;
        }
        
        NSError *writeError;
        [data writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
        if (writeError)
        {
            if (error)
                *error = writeError;
            return NO;
        }
        
        return YES;
    }
    if (error)
        *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeEmptyJson userInfo:nil];
    
    return NO;
}

@end

@implementation OASettingsItemGpxWriter
{
    OAGPXDocument *_gpxFile;
}

- (instancetype) initWithItem:(OASettingsItem *)item gpxDocument:(OAGPXDocument *)gpxFile
{
    self = [super initWithItem:item];
    if (self) {
        _gpxFile = gpxFile;
    }
    return self;
}

- (BOOL)writeToFile:(NSString *)filePath error:(NSError * _Nullable __autoreleasing *)error
{
    if (_gpxFile)
    {
        [_gpxFile saveTo:filePath];
        return YES;
    }
    return NO;
}

@end
