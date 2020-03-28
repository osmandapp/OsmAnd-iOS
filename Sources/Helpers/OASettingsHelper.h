//
//  OASettingsHelper.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndAppProtocol.h"

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

@interface OASettingsHelper : NSObject

@end

#pragma mark - OASettingsItem

@interface OASettingsItem : NSObject

@property (nonatomic, assign) EOASettingsItemType type;
@property (nonatomic, assign) BOOL shouldReplace;

- (instancetype) initWithType:(EOASettingsItemType)type;
- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary*)json;
- (EOASettingsItemType) getType;
- (BOOL) shouldReadOnCollecting;
- (void) setShouldReplace:(BOOL)shouldReplace;
- (EOASettingsItemType) parseItemType:(NSDictionary*)json;
- (void) readFromJSON:(NSDictionary*)json;
- (void) writeToJSON:(NSDictionary*)json;
- (NSString *)toJSON;
- (NSUInteger) hash;
- (BOOL) isEqual:(id)object;

@end

#pragma mark - SettingsItemReader

@interface OASettingsItemReader<ObjectType : OASettingsItem *> : NSObject

- (instancetype) initWithItem:(ObjectType)item;
- (void) readFromStream:(NSInputStream*)inputStream;

@end

#pragma mark - SettingsItemWriter

@interface OASettingsItemWriter<ObjectType : OASettingsItem *> : NSObject

- (instancetype) initWithItem:(ObjectType)item;
- (BOOL) writeToStream:(NSOutputStream*)outputStream;

@end

#pragma mark - StreamSettingsItemReader

@interface StreamSettingsItemReader : OASettingsItemReader<OASettingsItem *>

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAStreamSettingsItem

@interface OAStreamSettingsItem : OASettingsItem

@property (nonatomic, retain, readonly) NSString* name;

- (instancetype) initWithType:(EOASettingsItemType)type name:(NSString*)name;
- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary*)json;
- (instancetype) initWithType:(EOASettingsItemType)type inputStream:(NSInputStream*)inputStream name:(NSString*)name;
- (NSInputStream *) getInputStream;
- (void) setInputStream:(NSInputStream *)inputStream;
- (NSString *) getName;
- (NSString *) getPublicName;
- (void) readFromJSON:(NSDictionary *)json;
- (OASettingsItemWriter*) getWriter;


@end

#pragma mark - OADataSettingsItemReader

@interface OADataSettingsItemReader: StreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - DataSettingsItem

@interface OADataSettingsItem : OAStreamSettingsItem

@property (nonatomic, retain) NSData *data;

- (instancetype) initWithName:(NSString *)name;
- (instancetype) initWithJson:(NSDictionary *)json;
- (instancetype) initWithData:(NSData *)data name:(NSString *)name;
- (NSString *) getFileName;
- (NSData *) getData;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end

#pragma mark - OAFileSettingsItemReader

@interface OAFileSettingsItemReader: StreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end


#pragma mark - OAFileSettingsItem

@interface OAFileSettingsItem : OAStreamSettingsItem

@property (nonatomic, retain) NSString *filePath;

- (instancetype) initWithFile:(NSString *)filePath;
- (instancetype) initWithJSON:(NSDictionary*)json;
- (NSString *) getFileName;
- (NSString *) getFile;
- (BOOL) exists;
- (NSString *) renameFile:(NSString*)file;
- (OASettingsItemReader *) getReader;
- (OASettingsItemWriter *) getWriter;

@end
