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
//                quickAction = [quickActionRegistry ];
//            else if ([object objectForKey:@"type"])
//                quickAction = [quickActionRegistry ];
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

/*
 @Override
 public boolean writeToStream(@NonNull OutputStream outputStream) throws IOException {
     JSONObject json = new JSONObject();
     JSONArray jsonArray = new JSONArray();
     Gson gson = new Gson();
     Type type = new TypeToken<HashMap<String, String>>() {
     }.getType();
     if (!items.isEmpty()) {
         try {
             for (QuickAction action : items) {
                 JSONObject jsonObject = new JSONObject();
                 jsonObject.put("name", action.hasCustomName(app)
                         ? action.getName(app) : "");
                 jsonObject.put("actionType", action.getActionType().getStringId());
                 jsonObject.put("params", gson.toJson(action.getParams(), type));
                 jsonArray.put(jsonObject);
             }
             json.put("items", jsonArray);
         } catch (JSONException e) {
             LOG.error("Failed write to json", e);
         }
     }
     if (json.length() > 0) {
         try {
             String s = json.toString(2);
             outputStream.write(s.getBytes("UTF-8"));
         } catch (JSONException e) {
             LOG.error("Failed to write json to stream", e);
         }
         return true;
     }
     return false;
 }
 */

- (BOOL)writeToStream:(NSOutputStream *)outputStream
{
    
    if (!_quickActionSettingsItem.items.count)
    {
        
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
    //[reader readFromStream: super.inputStream];
    return reader;
}

- (OASettingsItemWriter *) getWriter
{
    OAQuickActionSettingsItemWriter *writer = [[OAQuickActionSettingsItemWriter alloc] initWithItem:self];
    //[writer writeToStream: super.inputStream];
    return writer;
}

@end

#pragma mark - OAMapSourcesSettingsItem

@interface OAMapSourcesSettingsItem()

@property (nonatomic, retain) NSMutableArray<NSString *> *existingItemsNames;

@end

@implementation OAMapSourcesSettingsItem

- (instancetype) initWithItems:(NSMutableArray<id>*)items
{
    self = [super initWithType:EOAMapSources items:items];
    //_existingItemsNames = [];
    return self;
}

- (instancetype) initWithJSON:(NSDictionary *)json
{
    self = [super initWithType:EOAMapSources json:json];
    //_existingItemsNames = [];
    return self;
}

/*
     @Override
     public void apply() {
         if (!items.isEmpty() || !duplicateItems.isEmpty()) {
             if (shouldReplace) {
                 for (ITileSource tileSource : duplicateItems) {
                     if (tileSource instanceof SQLiteTileSource) {
                         File f = app.getAppPath(IndexConstants.TILES_INDEX_DIR + tileSource.getName() + IndexConstants.SQLITE_EXT);
                         if (f != null && f.exists()) {
                             if (f.delete()) {
                                 items.add(tileSource);
                             }
                         }
                     } else if (tileSource instanceof TileSourceManager.TileSourceTemplate) {
                         File f = app.getAppPath(IndexConstants.TILES_INDEX_DIR + tileSource.getName());
                         if (f != null && f.exists() && f.isDirectory()) {
                             if (f.delete()) {
                                 items.add(tileSource);
                             }
                         }
                     }
                 }
             } else {
                 for (ITileSource tileSource : duplicateItems) {
                     items.add(renameItem(tileSource));
                 }
             }
             for (ITileSource tileSource : items) {
                 if (tileSource instanceof TileSourceManager.TileSourceTemplate) {
                     app.getSettings().installTileSource((TileSourceManager.TileSourceTemplate) tileSource);
                 } else if (tileSource instanceof SQLiteTileSource) {
                     ((SQLiteTileSource) tileSource).createDataBase();
                 }
             }
         }
     }
*/

- (void) apply
{
    if (!self.items.count || !self.duplicateItems.count)
    {
        if ([self shouldReplace])
        {
            for (OAMapSource *tileSource in self.duplicateItems)
            {
                //if ([tileSource isKindOfClass: SQLiteTileSource])
                if (tileSource)
                {
                    NSString *path = @"";///
                    NSFileManager *fileManager = [NSFileManager defaultManager];

                    if (path != NULL && [fileManager fileExistsAtPath: path])
                    {
                        if ([fileManager removeItemAtPath:path error:nil])
                            [self.items addObject:tileSource];
                    }
                }
                else if ([tileSource isKindOfClass: [OASettingsItem class])
                {
                    NSString *path = @"";///
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    BOOL isDir;
                    if (path != NULL && [fileManager fileExistsAtPath: path isDirectory:&isDir] && isDir)
                    {
                        if ([fileManager removeItemAtPath:path error:nil])
                            [self.items addObject:tileSource];
                    }
                }
            }
        }
        else
        {
            for (OAMapSource *tileSource in self.duplicateItems)
                [self.items addObject:tileSource];
        }
        for (OAMapSource *tileSource in self.duplicateItems)
        {
            
        }
    }
}

/*
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
 */

/*
     @NonNull
     @Override
     public ITileSource renameItem(@NonNull ITileSource item) {
         int number = 0;
         while (true) {
             number++;
             if (item instanceof SQLiteTileSource) {
                 SQLiteTileSource oldItem = (SQLiteTileSource) item;
                 SQLiteTileSource renamedItem = new SQLiteTileSource(
                         oldItem,
                         oldItem.getName() + "_" + number,
                         app);
                 if (!isDuplicate(renamedItem)) {
                     return renamedItem;
                 }
             } else if (item instanceof TileSourceManager.TileSourceTemplate) {
                 TileSourceManager.TileSourceTemplate oldItem = (TileSourceManager.TileSourceTemplate) item;
                 oldItem.setName(oldItem.getName() + "_" + number);
                 if (!isDuplicate(oldItem)) {
                     return oldItem;
                 }
             }
         }
     }
*/

- (BOOL) isDuplicate:(OAMapSource *)item
{
    for (NSString * name in _existingItemsNames)
    {
        if ([name isEqualToString:item.name])
            return YES;
    }
    return NO;
}

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

/*
     @NonNull
     @Override
     SettingsItemReader getReader() {
         return new SettingsItemReader<MapSourcesSettingsItem>(this) {
             @Override
             public void readFromStream(@NonNull InputStream inputStream) throws IOException, IllegalArgumentException {
                 StringBuilder buf = new StringBuilder();
                 try {
                     BufferedReader in = new BufferedReader(new InputStreamReader(inputStream, "UTF-8"));
                     String str;
                     while ((str = in.readLine()) != null) {
                         buf.append(str);
                     }
                 } catch (IOException e) {
                     throw new IOException("Cannot read json body", e);
                 }
                 String jsonStr = buf.toString();
                 if (Algorithms.isEmpty(jsonStr)) {
                     throw new IllegalArgumentException("Cannot find json body");
                 }
                 final JSONObject json;
                 try {
                     json = new JSONObject(jsonStr);
                     JSONArray jsonArray = json.getJSONArray("items");
                     for (int i = 0; i < jsonArray.length(); i++) {
                         JSONObject object = jsonArray.getJSONObject(i);
                         boolean sql = object.optBoolean("sql");
                         String name = object.optString("name");
                         int minZoom = object.optInt("minZoom");
                         int maxZoom = object.optInt("maxZoom");
                         String url = object.optString("url");
                         String randoms = object.optString("randoms");
                         boolean ellipsoid = object.optBoolean("ellipsoid", false);
                         boolean invertedY = object.optBoolean("inverted_y", false);
                         String referer = object.optString("referer");
                         boolean timesupported = object.optBoolean("timesupported", false);
                         long expire = object.optLong("expire");
                         boolean inversiveZoom = object.optBoolean("inversiveZoom", false);
                         String ext = object.optString("ext");
                         int tileSize = object.optInt("tileSize");
                         int bitDensity = object.optInt("bitDensity");
                         int avgSize = object.optInt("avgSize");
                         String rule = object.optString("rule");

                         ITileSource template;
                         if (!sql) {
                             template = new TileSourceManager.TileSourceTemplate(name, url, ext, maxZoom, minZoom, tileSize, bitDensity, avgSize);
                         } else {
                             template = new SQLiteTileSource(app, name, minZoom, maxZoom, url, randoms, ellipsoid, invertedY, referer, timesupported, expire, inversiveZoom);
                         }
                         items.add(template);
                     }
                 } catch (JSONException e) {
                     throw new IllegalArgumentException("Json parse error", e);
                 }
             }
         };
     }
*/

/*
     @NonNull
     @Override
     SettingsItemWriter getWriter() {
         return new SettingsItemWriter<MapSourcesSettingsItem>(this) {
             @Override
             public boolean writeToStream(@NonNull OutputStream outputStream) throws IOException {
                 JSONObject json = new JSONObject();
                 JSONArray jsonArray = new JSONArray();
                 if (!items.isEmpty()) {
                     try {
                         for (ITileSource template : items) {
                             JSONObject jsonObject = new JSONObject();
                             boolean sql = template instanceof SQLiteTileSource;
                             jsonObject.put("sql", sql);
                             jsonObject.put("name", template.getName());
                             jsonObject.put("minZoom", template.getMinimumZoomSupported());
                             jsonObject.put("maxZoom", template.getMaximumZoomSupported());
                             jsonObject.put("url", template.getUrlTemplate());
                             jsonObject.put("randoms", template.getRandoms());
                             jsonObject.put("ellipsoid", template.isEllipticYTile());
                             jsonObject.put("inverted_y", template.isInvertedYTile());
                             jsonObject.put("referer", template.getReferer());
                             jsonObject.put("timesupported", template.isTimeSupported());
                             jsonObject.put("expire", template.getExpirationTimeMillis());
                             jsonObject.put("inversiveZoom", template.getInversiveZoom());
                             jsonObject.put("ext", template.getTileFormat());
                             jsonObject.put("tileSize", template.getTileSize());
                             jsonObject.put("bitDensity", template.getBitDensity());
                             jsonObject.put("avgSize", template.getAvgSize());
                             jsonObject.put("rule", template.getRule());
                             jsonArray.put(jsonObject);
                         }
                         json.put("items", jsonArray);

                     } catch (JSONException e) {
                         LOG.error("Failed write to json", e);
                     }
                 }
                 if (json.length() > 0) {
                     try {
                         String s = json.toString(2);
                         outputStream.write(s.getBytes("UTF-8"));
                     } catch (JSONException e) {
                         LOG.error("Failed to write json to stream", e);
                     }
                     return true;
                 }
                 return false;
             }
         };
     }
 }
 
 */


@end
