//
//  OASettingsHelper.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndApp.h"
#import "OAQuickAction.h"
#import "OAQuickActionRegistry.h"
#import "OASQLiteTileSource.h"

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
- (BOOL) shouldReadOnCollecting;
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

#pragma mark - DataSettingsItem

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

#pragma mark - OAQuickActionSettingsItemReader

@interface OAQuickActionSettingsItemReader: OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item;

@end

#pragma mark - OAQuickActionSettingsItemWriter

@interface OAQuickActionSettingsItemWriter : OAStreamSettingsItemWriter



@end


#pragma mark - OAQuickActionSettingsItem

@interface OAQuickActionSettingsItem : OACollectionSettingsItem<OAQuickAction *>



@end


#pragma mark - OAMapSourcesSettingsItem

@interface OAMapSourcesSettingsItem : OACollectionSettingsItem<OAMapSource *>


@end
