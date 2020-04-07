//
//  OASettingsHelper.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"
#import "OASettingsCollect.h"
#import "OACheckDuplicates.h"
#import "OASettingsImport.h"
#import "OASettingsExport.h"
#import "OASettingsImporter.h"
#import "OASettingsExporter.h"

static const NSInteger _buffer = 1024;

@interface OASettingsHelper()

@property (weak, nonatomic) id<OASettingsCollectDelegate> settingsCollectDelegate;
@property (weak, nonatomic) id<OACheckDuplicatesDelegate> checkDuplicatesDelegate;
@property (weak, nonatomic) id<OASettingsImportDelegate> settingsImportDelegate;
@property (weak, nonatomic) id<OASettingsExportDelegate> settingsExportDelegate;

@end

@implementation OASettingsHelper


+ (OASettingsHelper*)sharedInstance
{
    static OASettingsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OASettingsHelper alloc] init];
    });
    return _sharedInstance;
}

- (void) finishImport:(OASettingsImport *)listener success:(BOOL)success items:(NSMutableArray*)items
{
    _importTask = NULL;
    if (listener != NULL)
        [_settingsImportDelegate onSettingsImportFinished:success items:items];
}

- (void) collectSettings:(NSString*)settingsFile latestChanges:(NSString*)latestChanges version:(NSInteger)version listener:(OASettingsCollect*)listener
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[OAImportAsyncTask alloc] initWithFile:settingsFile latestChanges:latestChanges version:version collectListener:listener] executeParameters];
        });
}
 
- (void) checkDuplicates:(NSString *)settingsFile items:(NSMutableArray <OASettingsItem*> *)items selectedItems:(NSMutableArray <OASettingsItem*> *)selectedItems listener:(OACheckDuplicates*)listener
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[OAImportAsyncTask alloc] initWithFile:settingsFile items:items selectedItems:selectedItems duplicatesListener:listener] executeParameters];
        });
}

- (void) importSettings:(NSString *)settingsFile items:(NSMutableArray <OASettingsItem*> *)items latestChanges:(NSString*)latestChanges version:(NSInteger)version listener:(OASettingsImport*)listener
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[OAImportAsyncTask alloc] initWithFile:settingsFile items:items latestChanges:latestChanges version:version importListener:listener] executeParameters];
        });
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName listener:(OASettingsExport*)listener items:(NSMutableArray <OASettingsItem*> *)items
{
    NSString* file = [NSString stringWithString:fileName];
    OAExportAsyncTask* exportAsyncTask = [[OAExportAsyncTask alloc] initWith:file listener:listener items:items];
    [exportAsyncTask setValue:exportAsyncTask forKey:file];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [exportAsyncTask executeParameters];
        });

}

 /*
 public void exportSettings(@NonNull File fileDir, @NonNull String fileName, @Nullable SettingsExportListener listener,
                            @NonNull SettingsItem... items) {
     exportSettings(fileDir, fileName, listener, new ArrayList<>(Arrays.asList(items)));
 }
 */

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName listener:(OASettingsExport*)listener
{
    //exportSettings(fileDir, fileName, listener, new ArrayList<>(Arrays.asList(items)));
}

@end


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
        return _type == item.type &&
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

@implementation OAStreamSettingsItemReader

- (instancetype)initWithItem:(OASettingsItem *)item
{
    self = [super initWithItem:item];
    return self;
}

@end

#pragma mark - OAStreamSettingsItemWriter

@implementation OAStreamSettingsItemWriter

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

- (NSString *) getPublicName
{
    return self.name;
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

- (BOOL) exists
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [fileManager fileExistsAtPath: _filePath];
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


#pragma mark - OACollectionSettingsItem

@implementation OACollectionSettingsItem

- (instancetype) initWithType:(EOASettingsItemType)type items:(NSMutableArray<id>*) items
{
    self = [super initWithType:type];
    _items = items;
    return self;
}

- (instancetype) initWithType:(EOASettingsItemType)type json:(NSDictionary *)json
{
    self = [super initWithType:type json:json];
    return self;
}

- (NSMutableArray<id> *) excludeDuplicateItems
{
    if (!_items.count)
    {
        for (id item in _items)
            if ([self isDuplicate:item])
                [_duplicateItems addObject:item];
    }
    return _duplicateItems;
}

- (BOOL) isDuplicate:(id)item
{
    return NO;
}

- (id) renameItem:(id) item
{
    return nil;
}

@end

#pragma mark - OAQuickActionSettingsItemReader

@interface OAQuickActionSettingsItemReader()

@property (nonatomic, retain) OAQuickActionSettingsItem *quickActionSettingsItem;

@end

@implementation OAQuickActionSettingsItemReader

- (instancetype)initWithItem:(OAQuickActionSettingsItem *)item
{
    self = [super initWithItem:item];
    _quickActionSettingsItem = item;
    return self;
}

- (void)readFromStream:(NSInputStream *)inputStream
{
    NSMutableString *buf = [[NSMutableString alloc] init];
    @try {
        uint8_t buffer[_buffer];
        NSInteger len;
        while ([inputStream hasBytesAvailable]) {
            len = [inputStream read:buffer maxLength:sizeof(buffer)];
            if (len > 0) {
                [buf appendString: [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding]];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Cannot read json body %@", exception);
    }
    NSString *jsonStr = [buf description];
    if (![jsonStr length])
        NSLog(@"Cannot find json body");
    @try {
        NSError *jsonError;
        NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
        OAQuickActionRegistry *quickActionRegistry = [OAQuickActionRegistry sharedInstance];
        NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
        for (NSData* item in itemsJson)
        {
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:item options:kNilOptions error:&jsonError];
            NSString *name = [object objectForKey:@"name"];
            OAQuickAction *quickAction = NULL;
//            if ([object objectForKey:@"actionType"])
//                //quickAction = quickActionRegistry .newActionByStringType(object.getString("actionType"));
//                //quickAction = [quickActionRegistry ];
//            else if ([object objectForKey:@"type"])
//                //quickAction = quickActionRegistry .newActionByType(object.getInt("type"));
//                //quickAction = [quickActionRegistry ];
            if (quickAction != NULL)
            {
                NSDictionary *params = [json objectForKey:@"params"];
                if (!name.length)
                    [quickAction setName:name];
                [quickAction setParams:params];
                [_quickActionSettingsItem.items addObject:quickAction];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Json parse error %@", exception);
    }
}

@end

#pragma mark - OAQuickActionSettingsItemWriter

@interface OAQuickActionSettingsItemWriter()

@property (nonatomic, retain) OAQuickActionSettingsItem *quickActionSettingsItem;

@end

@implementation OAQuickActionSettingsItemWriter

- (instancetype)initWithItem:(OAQuickActionSettingsItem *)item
{
    self = [super initWithItem:item];
    _quickActionSettingsItem = item;
    return self;
}

- (BOOL)writeToStream:(NSOutputStream *)outputStream
{
    NSMutableDictionary *json = [[NSMutableDictionary alloc]init];
    NSMutableArray *jsonArray = [[NSMutableArray alloc]init];
    if (!_quickActionSettingsItem.items.count)
    {
        @try {
            for (OAQuickAction *action in _quickActionSettingsItem.items)
            {
                NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc]init];
                [jsonObject setValue:[action getName] forKey:@"name"];
                [jsonObject setValue:[NSString stringWithFormat:@"%ld", [action getType]] forKey:@"actionType"];
                [jsonObject setValue:[action getParams] forKey:@"params"];
                [jsonArray addObject:jsonObject];
            }
            [json setValue:jsonArray forKey:@"items"];
        } @catch (NSException *exception) {
            NSLog(@"Failed write to json %@", exception);
        }
    }
    if ([json count] > 0)
    {
        @try {
            NSError *jsonError;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&jsonError];
            [outputStream write:(uint8_t *)[jsonData bytes] maxLength:[jsonData length]];
        } @catch (NSException *exception) {
            NSLog(@"Failed to write json to stream %@", exception);
        }
        return YES;
    }
    return NO;
}

@end


#pragma mark - OAQuickActionSettingsItem

@interface OAQuickActionSettingsItem()

@property (nonatomic, retain) OAQuickActionRegistry *actionRegistry;

@end

@implementation OAQuickActionSettingsItem

- (instancetype) initWithItems:(NSMutableArray<id> *)items
{
    self = [super initWithType:EOAQuickAction items:items];
    _actionRegistry = [OAQuickActionRegistry sharedInstance];
    self.existingItems = _actionRegistry.getQuickActions;
    return self;
}

- (instancetype) initWithJSON:(NSDictionary *)json
{
    self = [super initWithType:EOAQuickAction json:json];
    _actionRegistry = [OAQuickActionRegistry sharedInstance];
    self.existingItems = _actionRegistry.getQuickActions;
    return self;
}

- (BOOL) isDuplicate:(OAQuickAction *)item
{
    return ![_actionRegistry isNameUnique:item];
}

- (OAQuickAction *) renameItem:(OAQuickAction *)item
{
    return [_actionRegistry generateUniqueName:item];
}

- (void) apply
{
    if (!self.items.count || !self.duplicateItems.count)
    {
        NSMutableArray *newActions = [NSMutableArray arrayWithObjects: self.existingItems, nil];
        if (!self.duplicateItems.count)
        {
            if ([self shouldReplace])
            {
                for (OAQuickAction * duplicateItem in self.duplicateItems)
                    for (OAQuickAction * savedAction in self.existingItems)
                        if ([duplicateItem.name isEqualToString:savedAction.name])
                            [newActions removeObject:savedAction];
            }
            else
            {
                for (OAQuickAction * duplicateItem in self.duplicateItems)
                    [self renameItem:duplicateItem];
            }
            [newActions addObjectsFromArray:self.duplicateItems];
        }
        [newActions addObjectsFromArray:self.items];
        [_actionRegistry updateQuickActions:newActions];
    }
}


- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (NSString *) getName
{
    return @"quick_actions";
}

- (NSString *) getPublicName
{
    return @"quick_actions";
}

- (NSString *) getFileName
{
    return [[self getName] stringByAppendingString:@".dat"];
}

- (OASettingsItemReader *) getReader
{
    OAQuickActionSettingsItemReader *reader = [[OAQuickActionSettingsItemReader alloc] initWithItem:self];
    //[reader readFromStream: inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    OAQuickActionSettingsItemWriter *writer = [[OAQuickActionSettingsItemWriter alloc] initWithItem:self];
    //[writer writeToStream: inputStream];
    return writer;
}

@end


#pragma mark - OAPoiUiFilterSettingsItem

@implementation OAPoiUiFilterSettingsItem
{
     OsmAndAppInstance _app;
}

- (instancetype) initWithItem:(NSMutableArray<id>*)items
{
    self = [super initWithType:EOAPoiUIFilters items:items];
    _app = [OsmAndApp instance];
    //existingItems = app.getPoiFilters().getUserDefinedPoiFilters(false);
    //self.existingItems =
    return self;
}

- (instancetype) initWithJSON:(NSDictionary*)json
{
    self = [super initWithType:EOAPoiUIFilters json:json];
    _app = [OsmAndApp instance];
    //existingItems = app.getPoiFilters().getUserDefinedPoiFilters(false);
    //self.existingItems =
    return self;
}

- (void) apply
{
    if (!self.items.count || !self.duplicateItems.count)
    {
        for (OAPOIUIFilter* duplicate in self.duplicateItems)
            [self.items addObject:[self shouldReplace] ? duplicate : [self renameItem:duplicate]];
        for (OAPOIUIFilter* filter in self.items)
        {
            //app.getPoiFilters().createPoiFilter(filter, false);
            
        }
        //app.getSearchUICore().refreshCustomPoiFilters();
        
    }
}

- (BOOL) isDuplicate:(OAPOIUIFilter*)item
{
    NSString *savedName = item.name;
    for (OAPOIUIFilter* filter in self.existingItems)
    {
        if ([filter.name isEqualToString:savedName])
            return YES;
    }
    return NO;
}

- (OAPOIUIFilter *) renameItem:(OAPOIUIFilter *)item
{
    NSInteger number = 0;
    while (true) {
        number++;
        //PoiUIFilter renamedItem = new PoiUIFilter(item,
        //      item.getName() + "_" + number,
        //      item.getFilterId() + "_" + number);
        OAPOIUIFilter *renamedItem = [[OAPOIUIFilter alloc] init];
        if (![self isDuplicate:renamedItem]) {
            return renamedItem;
        }
    }
}

- (NSString *)getName
{
    return @"poi_ui_filters";
}

- (NSString *)getPublicName
{
    return @"poi_ui_filters";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (NSString *) getFileName
{
    return [[self getName] stringByAppendingString:@".json"];
}

- (OASettingsItemReader *) getReader
{
    OAPoiUiFilterSettingsItemReader *reader = [[OAPoiUiFilterSettingsItemReader alloc] initWithItem:self];
    //[reader readFromStream: inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    OAPoiUiFilterSettingsItemWriter *writer = [[OAPoiUiFilterSettingsItemWriter alloc] initWithItem:self];
    //[writer writeToStream: inputStream];
    return writer;
}

@end

#pragma mark - OAPoiUiFilterSettingsItemReader

@interface OAPoiUiFilterSettingsItemReader()

@property (nonatomic, retain) OAPoiUiFilterSettingsItem *poiUiFilterSettingsItem;

@end

@implementation OAPoiUiFilterSettingsItemReader

- (instancetype)initWithItem:(OAPoiUiFilterSettingsItem *)item
{
    self = [super initWithItem:item];
    _poiUiFilterSettingsItem = item;
    return self;
}

- (void)readFromStream:(NSInputStream *)inputStream
{
    NSMutableString *buf = [[NSMutableString alloc] init];
    @try {
        uint8_t buffer[_buffer];
        NSInteger len;
        while ([inputStream hasBytesAvailable]) {
            len = [inputStream read:buffer maxLength:sizeof(buffer)];
            if (len > 0) {
                [buf appendString: [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding]];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Cannot read json body %@", exception);
    }
    NSString *jsonStr = [buf description];
    if (![jsonStr length])
        NSLog(@"Cannot find json body");
    @try {
        NSError *jsonError;
        NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
        NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
        //MapPoiTypes poiTypes = app.getPoiTypes();
        for (NSData* item in itemsJson)
        {
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:item options:kNilOptions error:&jsonError];
            NSString *name = [object objectForKey:@"name"];
            NSString *filterId = [object objectForKey:@"filterId"];
            NSString *acceptedTypesString = [object objectForKey:@"acceptedTypes"];
            //NSDictionary acceptedTypes = ;
            //HashMap<String, LinkedHashSet<String>> acceptedTypes = gson.fromJson(acceptedTypesString, type);
            //Map<PoiCategory, LinkedHashSet<String>> acceptedTypesDone = new HashMap<>();
            //for (Map.Entry<String, LinkedHashSet<String>> mapItem : acceptedTypes.entrySet()) {
            //    final PoiCategory a = poiTypes.getPoiCategoryByName(mapItem.getKey());
            //    acceptedTypesDone.put(a, mapItem.getValue());
            //}
            //OAPoiUIFilter *filter =  new PoiUIFilter(name, filterId, acceptedTypesDone, app);
            OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] init];
            [_poiUiFilterSettingsItem.items addObject:filter];
            
            
        }
    } @catch (NSException *exception) {
        NSLog(@"Json parse error %@", exception);
    }
}


@end

#pragma mark - OAPoiUiFilterSettingsItemWriter

@interface OAPoiUiFilterSettingsItemWriter()

@property (nonatomic, retain) OAPoiUiFilterSettingsItem *poiUiFilterSettingsItem;

@end

@implementation OAPoiUiFilterSettingsItemWriter

- (instancetype)initWithItem:(OAPoiUiFilterSettingsItem *)item
{
    self = [super initWithItem:item];
    _poiUiFilterSettingsItem = item;
    return self;
}

- (BOOL)writeToStream:(NSOutputStream *)outputStream
{
    NSMutableDictionary *json = [[NSMutableDictionary alloc]init];
    NSMutableArray *jsonArray = [[NSMutableArray alloc]init];
    if (!_poiUiFilterSettingsItem.items.count)
    {
        @try {
            for (OAPOIUIFilter *filter in _poiUiFilterSettingsItem.items)
            {
                NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc]init];
                [jsonObject setValue:[filter getName] forKey:@"name"];
                [jsonObject setValue:filter.filterId forKey:@"filterId"];
                [jsonObject setValue:[filter getAcceptedTypes] forKey:@"acceptedTypes"];
                [jsonArray addObject:jsonObject];
            }
            [json setValue:jsonArray forKey:@"items"];
        } @catch (NSException *exception) {
            NSLog(@"Failed write to json %@", exception);
        }
    }
    if ([json count] > 0)
    {
        @try {
            NSError *jsonError;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&jsonError];
            [outputStream write:(uint8_t *)[jsonData bytes] maxLength:[jsonData length]];
        } @catch (NSException *exception) {
            NSLog(@"Failed to write json to stream %@", exception);
        }
        return YES;
    }
    return NO;
}

@end

#pragma mark - OAMapSourcesSettingsItem

@interface OAMapSourcesSettingsItem()

@property (nonatomic, retain) NSMutableArray<NSString *> *existingItemsNames;

@end

@implementation OAMapSourcesSettingsItem
{
    OsmAndAppInstance _app;
}

- (instancetype) initWithItems:(NSMutableArray<id>*)items
{
    self = [super initWithType:EOAMapSources items:items];
    _app = [OsmAndApp instance];
    
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        SqliteDbResourceItem *item = [[SqliteDbResourceItem alloc] init];
        item.title = [[filePath.lastPathComponent stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        item.fileName = filePath.lastPathComponent;
        [_existingItemsNames addObject:item.fileName];
    }
    const auto& resource = _app.resourcesManager->getResource(QStringLiteral("online_tiles"));
    if (resource != nullptr)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            OnlineTilesResourceItem* item = [[OnlineTilesResourceItem alloc] init];
            
            item.title = onlineTileSource->name.toNSString();
            item.path = [_app.cachePath stringByAppendingPathComponent:item.title];
            [_existingItemsNames addObject:item.title];
        }
    }
    return self;
}

- (instancetype) initWithJSON:(NSDictionary *)json
{
    self = [super initWithType:EOAMapSources json:json];
    _app = [OsmAndApp instance];
    
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        SqliteDbResourceItem *item = [[SqliteDbResourceItem alloc] init];
        item.title = [[filePath.lastPathComponent stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        item.fileName = filePath.lastPathComponent;
        [_existingItemsNames addObject:item.fileName];
    }
    const auto& resource = _app.resourcesManager->getResource(QStringLiteral("online_tiles"));
    if (resource != nullptr)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            OnlineTilesResourceItem* item = [[OnlineTilesResourceItem alloc] init];
            
            item.title = onlineTileSource->name.toNSString();
            item.path = [_app.cachePath stringByAppendingPathComponent:item.title];
            [_existingItemsNames addObject:item.title];
        }
    }
    return self;
}


- (void) apply
{
    if (!self.items.count || !self.duplicateItems.count)
    {
        if ([self shouldReplace])
        {
            for (LocalResourceItem *tileSource in self.duplicateItems)
            {
                if ([tileSource isKindOfClass: SqliteDbResourceItem.class])
                {
                    SqliteDbResourceItem* item = (SqliteDbResourceItem *)tileSource;
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];

                    if (item.path != NULL && [fileManager fileExistsAtPath: item.path])
                    {
                        [[OAMapCreatorHelper alloc] removeFile:item.path];
                        [self.items addObject:tileSource];
                    }
                }
                else if ([tileSource isKindOfClass: OnlineTilesResourceItem.class])
                {
                    OnlineTilesResourceItem* item = (OnlineTilesResourceItem *)tileSource;
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    BOOL isDir;
                    if (item.path != NULL && [fileManager fileExistsAtPath: item.path isDirectory:&isDir] && isDir)
                    {
                        [[OAMapCreatorHelper alloc] removeFile:item.path];
                        [self.items addObject:tileSource];
                    }
                }
            }
        }
        else
        {
            for (LocalResourceItem *tileSource in self.duplicateItems)
                [self.items addObject:tileSource];
        }
//        for (LocalResourceItem *tileSource in self.duplicateItems)
//        {
//            if ([tileSource isKindOfClass: OnlineTilesResourceItem.class])
//            {
//                //app.getSettings().installTileSource((TileSourceManager.TileSourceTemplate) tileSource);
//                _app.
//            }
//            else if ([tileSource isKindOfClass: SqliteDbResourceItem.class])
//            {
//                //((SQLiteTileSource) tileSource).createDataBase();
//                //[(OASQLiteTileSource*) tileSource createDataBase]; -> installFile
//            }
//        }
    }
}

//
////public ITileSource renameItem(@NonNull ITileSource item) {
//- (LocalResourceItem *)renameItem:(LocalResourceItem *)item
//{
//    NSInteger number  = 0;
//    while (true)
//    {
//        number++;
//        //if (item instanceof SQLiteTileSource) {
//        if ([item isKindOfClass:SqliteDbResourceItem.class])
//        {
//            //SQLiteTileSource oldItem = (SQLiteTileSource) item;
//            LocalResourceItem *oldItem = (LocalResourceItem *)item;
//            //SQLiteTileSource renamedItem = new SQLiteTileSource(
//            //        oldItem,
//            //        oldItem.getName() + "_" + number,
//            //        app);
//            SqliteDbResourceItem *renamedItem = [[SqliteDbResourceItem alloc] ]; //???
//            if (![self isDuplicate:renamedItem])
//                return renamedItem;
//        }
//        //} else if (item instanceof TileSourceManager.TileSourceTemplate) {
//        else if ([item isKindOfClass: .class])
//        {
//            //TileSourceManager.TileSourceTemplate oldItem = (TileSourceManager.TileSourceTemplate) item;
//            //oldItem.setName(oldItem.getName() + "_" + number);
//            if (![self isDuplicate:<#(id)#>])
//                return ;
//        }
//    }
//}

//- (BOOL) isDuplicate:(LocalResourceItem *)item
//{
//    for (NSString * name in _existingItemsNames)
//    {
//        if ([name isEqualToString:item.name])
//            return YES;
//    }
//    return NO;
//}


- (NSString *)getName
{
    return @"map_sources";
}

- (NSString *)getPublicName
{
    return @"map_sources";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (NSString *)getFileName
{
    return [[self getName] stringByAppendingString:@".json"];
}

- (OASettingsItemReader *) getReader
{
    OAMapSourcesSettingsItemReader *reader = [[OAMapSourcesSettingsItemReader alloc] initWithItem:self];
    //[reader readFromStream: inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    OAMapSourcesSettingsItemWriter *writer = [[OAMapSourcesSettingsItemWriter alloc] initWithItem:self];
    //[writer writeToStream: inputStream];
    return writer;
}

@end

#pragma mark - OAMapSourcesSettingsItemReader

@interface OAMapSourcesSettingsItemReader()

@property (nonatomic, retain) OAMapSourcesSettingsItem *mapSourcesSettingsItem;

@end

@implementation OAMapSourcesSettingsItemReader

- (instancetype)initWithItem:(OAMapSourcesSettingsItem *)item
{
    self = [super initWithItem:item];
    _mapSourcesSettingsItem = item;
    return self;
}

- (void)readFromStream:(NSInputStream *)inputStream
{
    NSMutableString *buf = [[NSMutableString alloc] init];
    @try {
        uint8_t buffer[_buffer];
        NSInteger len;
        while ([inputStream hasBytesAvailable]) {
            len = [inputStream read:buffer maxLength:sizeof(buffer)];
            if (len > 0) {
                [buf appendString: [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding]];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Cannot read json body %@", exception);
    }
    NSString *jsonStr = [buf description];
    if (![jsonStr length])
        NSLog(@"Cannot find json body");
    @try {
        NSError *jsonError;
        NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
        NSArray* jsonArray = [json mutableArrayValueForKey:@"items"];
        for (NSData* item in jsonArray)
        {
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:item options:kNilOptions error:&jsonError];
            BOOL sql = [object objectForKey:@"sql"];
//            NSString *name = [object objectForKey:@"name"];
//            NSInteger minZoom = (NSInteger)[object objectForKey:@"minZoom"];
//            NSInteger maxZoom = (NSInteger)[object objectForKey:@"maxZoom"];
//            NSString *url = [object objectForKey:@"url"];
//            NSString *randoms = [object objectForKey:@"randoms"];
//            BOOL ellipsoid = [object objectForKey:@"ellipsoid"];
//            BOOL invertedY = [object objectForKey:@"invertedY"];
//            NSString *referer = [object objectForKey:@"referer"];
//            BOOL timesupported = [object objectForKey:@"timesupported"];
//            NSInteger expire = (NSInteger)[object objectForKey:@"expire"];
//            BOOL inversiveZoom = [object objectForKey:@"inversiveZoom"];
//            NSString *ext = [object objectForKey:@"ext"];
//            NSInteger tileSize = (NSInteger)[object objectForKey:@"tileSize"];
//            NSInteger bitDensity = (NSInteger)[object objectForKey:@"bitDensity"];
//            NSInteger avgSize = (NSInteger)[object objectForKey:@"avgSize"];
//            NSString *rule = [object objectForKey:@"rule"];
            LocalResourceItem *tileSource;
            if (!sql)
                //template = new TileSourceManager.TileSourceTemplate(name, url, ext, maxZoom, minZoom, tileSize, bitDensity, avgSize);
                tileSource = [[OnlineTilesResourceItem alloc] init];
            else
                //template = new SQLiteTileSource(app, name, minZoom, maxZoom, url, randoms, ellipsoid, invertedY, referer, timesupported, expire, inversiveZoom);
                tileSource = [[SqliteDbResourceItem alloc] init];
            [_mapSourcesSettingsItem.items addObject:tileSource];
            
        }
    } @catch (NSException *exception) {
        NSLog(@"Json parse error %@", exception);
    }

}

@end

#pragma mark - OAMapSourcesSettingsItemWriter

@interface OAMapSourcesSettingsItemWriter()

@property (nonatomic, retain) OAMapSourcesSettingsItem *mapSourcesSettingsItem;

@end

@implementation OAMapSourcesSettingsItemWriter

- (instancetype)initWithItem:(OAMapSourcesSettingsItem *)item
{
    self = [super initWithItem:item];
    _mapSourcesSettingsItem = item;
    return self;
}

- (BOOL)writeToStream:(NSOutputStream *)outputStream
{
    NSMutableDictionary *json = [[NSMutableDictionary alloc]init];
    NSMutableArray *jsonArray = [[NSMutableArray alloc]init];
    if (!_mapSourcesSettingsItem.items.count)
    {
        @try {
            for (LocalResourceItem *tileSource in _mapSourcesSettingsItem.items)
            {
                NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc]init];
//                BOOL sql = [tileSource isKindOfClass:SqliteDbResourceItem.class];
//                [jsonObject setValue:sql forKey:@"sql"];
//                [jsonObject setValue:[tileSource] forKey:@"name"]; //template.getName()
//                [jsonObject setValue:[tileSource] forKey:@"minZoom"]; //template.getMinimumZoomSupported()
//                [jsonObject setValue:[tileSource] forKey:@"maxZoom"]; //template.getMaximumZoomSupported()
//                [jsonObject setValue:[tileSource] forKey:@"url"]; //template.getUrlTemplate()
//                [jsonObject setValue:[tileSource] forKey:@"randoms"]; //template.getRandoms()
//                [jsonObject setValue:[tileSource] forKey:@"ellipsoid"]; //template.isEllipticYTile()
//                [jsonObject setValue:[tileSource] forKey:@"inverted_y"]; //template.isInvertedYTile()
//                [jsonObject setValue:[tileSource] forKey:@"referer"]; //template.getReferer()
//                [jsonObject setValue:[tileSource] forKey:@"timesupported"]; //template.isTimeSupported()
//                [jsonObject setValue:[tileSource] forKey:@"expire"]; //template.getExpirationTimeMillis()
//                [jsonObject setValue:[tileSource] forKey:@"inversiveZoom"]; //template.getInversiveZoom()
//                [jsonObject setValue:[tileSource] forKey:@"ext"]; //template.getTileFormat()
//                [jsonObject setValue:[tileSource] forKey:@"tileSize"]; //template.getTileSize()
//                [jsonObject setValue:[tileSource] forKey:@"bitDensity"]; //template.getBitDensity()
//                [jsonObject setValue:[tileSource] forKey:@"avgSize"]; template.getAvgSize()
//                [jsonObject setValue:[tileSource] forKey:@"rule"]; //template.getRule()
//
                [jsonArray addObject:jsonObject];
            }
            [json setValue:jsonArray forKey:@"items"];
        } @catch (NSException *exception) {
            NSLog(@"Failed write to json %@", exception);
        }
    }
    if ([json count] > 0)
    {
        @try {
            NSError *jsonError;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&jsonError];
            [outputStream write:(uint8_t *)[jsonData bytes] maxLength:[jsonData length]];
        } @catch (NSException *exception) {
            NSLog(@"Failed to write json to stream %@", exception);
        }
        return YES;
    }
    return NO;
}

@end


#pragma mark - OAAvoidRoadsSettingsItem

@implementation OAAvoidRoadsSettingsItem
{
    OsmAndAppInstance _app;
    OAAppSettings* settings;
    OAAvoidSpecificRoads *specificRoads;
}

- (instancetype) initWithItems:(NSMutableArray<id>*)items
{
    self = [super initWithType:EOAAvoidRoads items:items];
    _app = [OsmAndApp instance];
    //settings = app.getSettings();
    //_settings =
    //specificRoads = app.getAvoidSpecificRoads();
    //_specificRoads =
    //existingItems = new ArrayList<>(specificRoads.getImpassableRoads().values());
    //self.existingItems =
    return self;
}

- (instancetype) initWithJSON:(NSDictionary*)json
{
    self = [super initWithType:EOAAvoidRoads json:json];
    _app = [OsmAndApp instance];
    //settings = app.getSettings();
    //_settings =
    //specificRoads = app.getAvoidSpecificRoads();
    //_specificRoads =
    //existingItems = new ArrayList<>(specificRoads.getImpassableRoads().values());
    //self.existingItems =
    return self;
}

- (NSString *) getName
{
    return @"avoid_roads";
}

- (NSString *) getPublicName
{
    return @"avoid_roads";
}

- (NSString *) getFileName
{
    return [[self getName] stringByAppendingString:@".json"];
}

- (void) apply
{
    
}

- (BOOL) isDuplicate:()item // AvoidRoadInfo
{
    return [self.existingItems containsObject:item];
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

//- () renameItem:() item //AvoidRoadInfo
//{
//
//}

- (OASettingsItemReader *) getReader
{
    OAAvoidRoadsSettingsItemReader *reader = [[OAAvoidRoadsSettingsItemReader alloc] initWithItem:self];
    //[reader readFromStream: super.inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    OAAvoidRoadsSettingsItemWriter *writer = [[OAAvoidRoadsSettingsItemWriter alloc] initWithItem:self];
    //[writer writeToStream: super.inputStream];
    return writer;
}

@end

#pragma mark - OAAvoidRoadsSettingsItemReader

@interface OAAvoidRoadsSettingsItemReader()

@property (nonatomic, retain) OAAvoidRoadsSettingsItem *avoidRoadsSettingsItem;

@end

@implementation OAAvoidRoadsSettingsItemReader

- (instancetype)initWithItem:(OAAvoidRoadsSettingsItem *)item
{
    self = [super initWithItem:item];
    _avoidRoadsSettingsItem = item;
    return self;
}

- (void)readFromStream:(NSInputStream *)inputStream
{
    NSMutableString *buf = [[NSMutableString alloc] init];
        @try {
            uint8_t buffer[_buffer];
            NSInteger len;
            while ([inputStream hasBytesAvailable]) {
                len = [inputStream read:buffer maxLength:sizeof(buffer)];
                if (len > 0) {
                    [buf appendString: [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding]];
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"Cannot read json body %@", exception);
        }
        NSString *jsonStr = [buf description];
        if (![jsonStr length])
            NSLog(@"Cannot find json body");
        @try {
            NSError *jsonError;
            NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
            NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
            for (NSData* item in itemsJson)
            {
//                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:item options:kNilOptions error:&jsonError];
//                double latitude = [[object objectForKey:@"latitude"] doubleValue];
//                double longitude = [[object objectForKey:@"longitude"] doubleValue];
//                NSString *name = [object objectForKey:@"name"];
//                NSString *appModeKey = [object objectForKey:@"appModeKey"];
//                //AvoidRoadInfo roadInfo = new AvoidRoadInfo();
//                //roadInfo.id = 0;
//                //roadInfo.latitude = latitude;
//                //roadInfo.longitude = longitude;
//                //roadInfo.name = name;
//                if ([OAApplicationMode valueOfStringKey:appModeKey def:NULL])
//                {
//                    //roadInfo.appModeKey = appModeKey;
//                } else
//                {
//                    //roadInfo.appModeKey = app.getRoutingHelper().getAppMode().getStringKey();
//                }
//                //[_avoidRoadsSettingsItem.items addObject:roadInfo];
            }
        } @catch (NSException *exception) {
            NSLog(@"Json parse error %@", exception);
        }
}

@end

#pragma mark - OAAvoidRoadsSettingsItemWriter

@interface OAAvoidRoadsSettingsItemWriter()

@property (nonatomic, retain) OAAvoidRoadsSettingsItem *avoidRoadsSettingsItem;

@end

@implementation OAAvoidRoadsSettingsItemWriter

- (instancetype)initWithItem:(OAAvoidRoadsSettingsItem *)item
{
    self = [super initWithItem:item];
    _avoidRoadsSettingsItem = item;
    return self;
}

- (BOOL)writeToStream:(NSOutputStream *)outputStream
{
    NSMutableDictionary *json = [[NSMutableDictionary alloc]init];
    NSMutableArray *jsonArray = [[NSMutableArray alloc]init];
    if (!_avoidRoadsSettingsItem.items.count)
    {
        @try {
//            for ( *avoidRoad in _avoidRoadsSettingsItem.items) //AvoidRoadInfo
//            {
//                NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc]init];
//
//                [jsonObject setValue:[avoidRoad] forKey:@"latitude"]; //avoidRoad.latitude
//                [jsonObject setValue:[avoidRoad] forKey:@"longitude"]; //avoidRoad.longitude
//                [jsonObject setValue:[avoidRoad] forKey:@"name"]; //avoidRoad.name
//                [jsonObject setValue:[avoidRoad] forKey:@"appModeKey"]; //avoidRoad.appModeKey
//
//                [jsonArray addObject:jsonObject];
//            }
            [json setValue:jsonArray forKey:@"items"];
        } @catch (NSException *exception) {
            NSLog(@"Failed write to json %@", exception);
        }
    }
    if ([json count] > 0)
    {
        @try {
            NSError *jsonError;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&jsonError];
            [outputStream write:(uint8_t *)[jsonData bytes] maxLength:[jsonData length]];
        } @catch (NSException *exception) {
            NSLog(@"Failed to write json to stream %@", exception);
        }
        return YES;
    }
    return NO;
}

@end

