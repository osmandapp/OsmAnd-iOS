//
//  OASettingsExporter.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsExporter.h"
#import "OASettingsHelper.h"
#import "OASettingsExport.h"
#import "OAAppSettings.h"

static const NSInteger _buffer = 1024;

#pragma mark - OASettingsExporter

@interface OASettingsExporter()

@property (nonatomic) NSMutableDictionary *items;
@property (nonatomic) NSMutableDictionary *additionalParams;

@end

@implementation OASettingsExporter
 
- (instancetype) init
{
    self = [super init];
    _items = [NSMutableDictionary dictionary];
    _additionalParams = [NSMutableDictionary dictionary];
    return self;
}
 
- (void) addSettingsItem:(OASettingsItem *)item
{
    if (_items[item.name])
        NSLog(@"Already has such item: %@", item.name);
    _items[item.name] = item;
}
 
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value
{
    [_additionalParams setValue:value forKey:key];
}
 
- (void) exportSettings:(NSString *)file error:(NSError * _Nullable *)error
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"osmand_settings_version"] = [NSString stringWithFormat:@"%ld", OAAppSettings.version];
    for (NSString *key in _additionalParams)
        json[key] = _additionalParams[key];
    NSMutableArray *itemsJson = [NSMutableArray array];
    for (OASettingsItem *item in _items.allValues)
        [itemsJson addObject:item];
    json[@"items"] = itemsJson;
    
    // not completed
}

@end

#pragma mark - OAExportAsyncTask

@interface OAExportAsyncTask()

@property (nonatomic) NSString *filePath;
@property (weak, nonatomic) id<OASettingsExportDelegate> settingsExportDelegate;

@end

@implementation OAExportAsyncTask
{
    OASettingsHelper *_settingsHelper;
    OASettingsExporter *_exporter;
    OASettingsExport *_exportListener;
}
 
- (instancetype) initWithFile:(NSString *)settingsFile listener:(OASettingsExport * _Nullable)listener items:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settingsHelper = [OASettingsHelper sharedInstance];
        _filePath = settingsFile;
        _exportListener = listener;
        _exporter = [[OASettingsExporter alloc] init];
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
    [_settingsHelper.exportTask removeObjectForKey:_filePath];
    if (_exportListener)
        [_settingsExportDelegate onSettingsExportFinished:_filePath succeed:success];
    
}

@end
