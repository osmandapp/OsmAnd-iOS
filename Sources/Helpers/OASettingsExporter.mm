//
//  OASettingsExporter.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsExporter.h"
#import "OASettingsHelper.h"
#import "OAAppSettings.h"
#import "OrderedDictionary.h"
#import "OsmAndApp.h"

#define kVersion 1

static const NSInteger _buffer = 1024;

#pragma mark - OASettingsExporter

@implementation OASettingsExporter
{

    MutableOrderedDictionary *_items;
    MutableOrderedDictionary *_additionalParams;
    BOOL _exportItemsFiles;
    
    OsmAndAppInstance _app;
}

- (instancetype) initWithExportParam:(BOOL)exportItemsFiles
{
    self = [super init];
    if (self)
    {
        _items = [MutableOrderedDictionary new];
        _additionalParams = [MutableOrderedDictionary new];
        _exportItemsFiles = exportItemsFiles;
        
        _app = OsmAndApp.instance;
    }
    return self;
}

- (void) addSettingsItem:(OASettingsItem *)item
{
    if (_items[item.name])
        NSLog(@"Already has such item: %@", item.name);
    [_items setObject:item forKey:item.name];
}
 
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value
{
    [_additionalParams setValue:value forKey:key];
}
 
- (void) exportSettings:(NSString *)file error:(NSError * _Nullable *)error
{
    // TODO: check this functionality while testing export!
    NSMutableArray<NSString *> *paths = [NSMutableArray new];
    NSDictionary *json = [self createItemsJson];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"items.json"];
    [paths addObject:path];
    [fileManager removeItemAtPath:path error:nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:error];
    if (!error)
        [jsonData writeToFile:path atomically:YES];
    if(_exportItemsFiles)
    {
        [self writeItemsFiles:paths];
    }
    // TODO: write archive writer!
    
    for (NSString *path in paths)
         [fileManager removeItemAtPath:path error:nil];
}

- (void) writeItemsFiles:(NSMutableArray<NSString *> *)paths
{
    for (OASettingsItem *item : _items)
    {
        OASettingsItemWriter *writer = [item getWriter];
        if (writer != nil)
        {
            NSString *fileName = item.fileName;
            if (fileName.length > 0)
                fileName = item.defaultFileName;
            
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            NSError *error = nil;
            [writer writeToFile:path error:&error];
            if (!error)
                [paths addObject:path];
        }
    }
}

- (NSDictionary *) createItemsJson
{
    MutableOrderedDictionary *json = [MutableOrderedDictionary new];
    [json setObject:@(kVersion) forKey:@"version"];
    [_additionalParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [json setObject:obj forKey:key];
    }];
    [json setObject:_items.allValues forKey:@"items"];
    
    return json;
}

@end

#pragma mark - OAExportAsyncTask

@interface OAExportAsyncTask()

@property (nonatomic) NSString *filePath;

@end

@implementation OAExportAsyncTask
{
    OASettingsHelper *_settingsHelper;
    OASettingsExporter *_exporter;
}
 
- (instancetype) initWithFile:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles
{
    self = [super init];
    if (self)
    {
        _settingsHelper = [OASettingsHelper sharedInstance];
        _filePath = settingsFile;
        _exporter = [[OASettingsExporter alloc] initWithExportParam:exportItemFiles];
        for (OASettingsItem *item in items)
            [_exporter addSettingsItem:item];
    }
    return self;
}

- (void) execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:YES];
        });
    });
}

- (BOOL) doInBackground
{
    NSError *exportError;
    [_exporter exportSettings:_filePath error:&exportError];
    if (exportError)
    {
        NSLog(@"Failed to export items to: %@ %@", _filePath, exportError);
        return NO;
    }
    return YES;
}

- (void) onPostExecute:(BOOL)success
{
    [_settingsHelper.exportTasks removeObjectForKey:_filePath];
    if (_settingsExportDelegate)
        [_settingsExportDelegate onSettingsExportFinished:_filePath succeed:success];
    
}

@end
