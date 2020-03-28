//
//  OASettingsHelper.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"

@implementation OASettingsHelper

@end

static const NSInteger _buffer = 1024;

#pragma mark - OASettingsItem

@implementation OASettingsItem

- (instancetype) initWithType:(EOASettingsItemType)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}
 
- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary*)json
{
    self = [super init];
    if (self) {
        _type = type;
        [self readFromJSON:json];
    }
    return self;
}

- (EOASettingsItemType) getType
{
    return _type;
}

- (NSString *) getName
{
    return nil;
}

- (NSString *) getPublicName
{
    return nil;
}

- (NSString *) getFileName
{
    return nil;
}

- (BOOL) shouldReadOnCollecting
{
    return NO;
}

- (void) setShouldReplace:(BOOL)shouldReplace
{
    _shouldReplace = shouldReplace;
}

- (EOASettingsItemType) parseItemType:(NSDictionary*)json
{
    NSString *str = [json objectForKey:@"type"];
    if ([str isEqualToString:@"GLOBAL"])
        return EOAGlobal;
    if ([str isEqualToString:@"PROFILE"])
        return EOAProfile;
    if ([str isEqualToString:@"PLUGIN"])
        return EOAPlugin;
    if ([str isEqualToString:@"DATA"])
        return EOAData;
    if ([str isEqualToString:@"FILE"])
        return EOAFile;
    if ([str isEqualToString:@"QUICK_ACTION"])
        return EOAQuickAction;
    if ([str isEqualToString:@"POI_UI_FILTERS"])
        return EOAPoiUIFilters;
    if ([str isEqualToString:@"MAP_SOURCES"])
        return EOAMapSources;
    if ([str isEqualToString:@"AVOID_ROADS"])
        return EOAAvoidRoads;
    return nil;
}

- (BOOL) exists
{
    return NO;
}

- (void) apply
{
    // non implemented
}

- (void) readFromJSON:(NSDictionary*)json
{
}

- (void) writeToJSON:(NSDictionary*)json
{
    [json setValue:[NSNumber numberWithInteger:_type] forKey:[self getName]];
    [json setValue:[self getName] forKey:@"name"];
    
}

- (NSString *)toJSON
{
    NSDictionary *JSONDic=[[NSDictionary alloc] init];
    NSError *error;
    [self writeToJSON:JSONDic];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:JSONDic
                                            options:NSJSONWritingPrettyPrinted
                                            error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
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
    NSInteger result = _type;
    NSString *name = [self getName];
    result = 31 * result + (name != nil ? [name hash] : 0);
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
        return _type == item.getType &&
                        [[item getName] isEqual:[self getName]] &&
                        [[item getFileName] isEqual:[self getFileName]];
    }
    else
    {
        return NO;
    }
}

@end

#pragma mark - OASettingsItemReader

@interface OASettingsItemReader<ObjectType : OASettingsItem *>()

@property (nonatomic, assign) ObjectType item;

@end

@implementation OASettingsItemReader

- (instancetype) initWithItem:(id)item
{
    _item = item;
    return self;
}

- (void) readFromStream:(NSInputStream*)inputStream
{
    return;
}

@end

#pragma mark - OSSettingsItemWriter

@interface OASettingsItemWriter<ObjectType : OASettingsItem *>()

@property (nonatomic, assign) ObjectType item;

@end

@implementation OASettingsItemWriter

- (id) getItem
{
    return _item;
}

- (instancetype) initWithItem:(id)item
{
    _item = item;
    return self;
}

- (BOOL) writeToStream:(NSOutputStream*)outputStream
{
    return NO;
}

@end

#pragma mark - StreamSettingsItemReader

@implementation StreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item
{
    self = [super initWithItem:item];
    return self;
}

@end

#pragma mark - OAStreamSettingsItem

@interface OAStreamSettingsItem()

@property (nonatomic, retain) NSInputStream* inputStream;
@property (nonatomic, retain) NSString* name;

@end

@implementation OAStreamSettingsItem

- (instancetype) initWithType:(EOASettingsItemType)type name:(NSString*)name
{
    [super setType:type];
    _name = name;
    return self;
}

- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary*)json
{
    self = [super initWithType:type json:json];
    return self;
}

- (instancetype) initWithType:(EOASettingsItemType)type inputStream:(NSInputStream*)inputStream name:(NSString*)name
{
    [super setType:type];
    _name = name;
    _inputStream = inputStream;
    return self;
}

- (NSInputStream *) getInputStream
{
    return _inputStream;
}

- (void) setInputStream:(NSInputStream *)inputStream
{
    _inputStream = inputStream;
}

- (NSString *) getName
{
    return _name;
}

- (NSString *) getPublicName
{
    return [self getName];
}

- (void) readFromJSON:(NSDictionary *)json
{
    [super readFromJSON:json];
    _name = [[NSString alloc] initWithData:[json objectForKey:@"name"] encoding:NSUTF8StringEncoding];
}

-(OASettingsItemWriter*)getWriter
{
    OASettingsItemWriter *itemWriter = [[OASettingsItemWriter alloc] initWithItem:self];
    return itemWriter;
}

@end

#pragma mark - OADataSettingsItemReader

@interface OADataSettingsItemReader()

@property (nonatomic, retain) OADataSettingsItem *dataSettingsItem;

@end

@implementation OADataSettingsItemReader

- (instancetype)initWithItem:(OADataSettingsItem *)item
{
    self = [super initWithItem:item];
    _dataSettingsItem = item;
    return self;
}


- (void)readFromStream:(NSInputStream *)inputStream
{
    NSOutputStream *buffer = [[NSOutputStream alloc] init];
    uint8_t data[_buffer];
    NSInteger nRead;
    [buffer open];
    while ([inputStream hasBytesAvailable]) {
        nRead = [inputStream read:data maxLength:sizeof(data)];
        if (nRead > 0) {
            [buffer write:data maxLength:nRead];
        }
    }
    _dataSettingsItem.data = [buffer propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [buffer close];
}

@end


#pragma mark - OAFileSettingsItemReader

@interface OAFileSettingsItemReader()

@property (nonatomic, retain) OAFileSettingsItem *fileSettingsItem;


@end

@implementation OAFileSettingsItemReader

- (instancetype)initWithItem:(OAFileSettingsItem *)item
{
    self = [super initWithItem:item];
    _fileSettingsItem = item;
    return self;
}

- (void)readFromStream:(NSInputStream *)inputStream
{
    NSOutputStream *output;
    NSString *filePath = _fileSettingsItem.filePath;
    if (![_fileSettingsItem exists] || [_fileSettingsItem shouldReplace])
        output = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    else
        output = [NSOutputStream outputStreamToFileAtPath:[_fileSettingsItem renameFile:filePath] append:NO];
    uint8_t buffer[_buffer];
    NSInteger count;
    [output open];
    @try {
        while ([inputStream hasBytesAvailable]) {
            count = [inputStream read:buffer maxLength:count];
            if (count > 0) {
                [output write:buffer maxLength:count];
            }
        }
    } @finally {
        [output close];
    }
}

@end


#pragma mark - OADataSettingsItem

@implementation OADataSettingsItem

- (instancetype) initWithName:(NSString *)name
{
    self = [super initWithType:EOAData name:name];
    return self;
}

- (instancetype) initWithJson:(NSDictionary *)json
{
    self = [super initWithType:EOAData json:json];
    return self;
}

- (instancetype) initWithData:(NSData *)data name:(NSString *)name
{
    self = [super initWithType:EOAData name:name];
    _data = data;
    return self;
}

- (NSString *) getFileName
{
    return [[self getName] stringByAppendingString:@".dat"];
}

- (NSData *) getData {
    return _data;
}

- (OASettingsItemReader *) getReader
{
    OADataSettingsItemReader *reader = [[OADataSettingsItemReader alloc] initWithItem:self];
    [reader readFromStream: super.inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    NSInputStream *inputStream = [[NSInputStream alloc] initWithData:_data];
    [self setInputStream:inputStream];
    return [super getWriter];
}

@end


#pragma mark - OAFileSettingsItem

@implementation OAFileSettingsItem

- (instancetype) initWithFile:(NSString *)filePath
{
    self = [super initWithType:EOAFile name:filePath];
    _filePath = filePath;
    return self;
}

- (instancetype) initWithJSON:(NSDictionary*)json
{
    self = [super initWithType:EOAFile json:json];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    _filePath = [fileManager currentDirectoryPath];
    
    return self;
}

- (NSString *) getFileName
{
    return [super getName];
}

- (NSString *) getFile
{
    return _filePath;
}

- (BOOL) exists
{
    NSFileManager *filemaneger;

    filemaneger = [NSFileManager defaultManager];

    if ([filemaneger fileExistsAtPath: _filePath] == YES)
        return YES;
    else
        return NO;
}

- (NSString *) renameFile:(NSString*)filePath
{
    NSFileManager *filemaneger = [NSFileManager defaultManager];
    NSError *error = nil;
    [filemaneger moveItemAtPath:_filePath toPath: filePath error: &error];
    return _filePath;
}

- (OASettingsItemReader *) getReader
{
    OAFileSettingsItemReader *reader = [[OAFileSettingsItemReader alloc] initWithItem:self];
    [reader readFromStream: super.inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:_filePath];
    @try {
        [self setInputStream:inputStream];
    } @catch (NSException *exception) {
        NSLog(@"Failed to set input stream from file: %@", _filePath);
    }
    return [super getWriter];
}

@end
