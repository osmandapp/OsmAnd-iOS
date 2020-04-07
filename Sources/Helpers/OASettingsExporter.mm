//
//  OASettingsExporter.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsExporter.h"
#import "OASettingsExport.h"

static const NSInteger _buffer = 1024;

#pragma mark - OASettingsExporter

@interface OASettingsExporter()

@property(nonatomic, retain)NSMutableDictionary* items;
@property(nonatomic, retain)NSMutableDictionary* additionalParams;

@end

@implementation OASettingsExporter
 
- (instancetype) init
{
    self = [super init];
    _items = [[NSMutableDictionary alloc] init];
    _additionalParams = [[NSMutableDictionary alloc] init];
    return self;
}
 
- (void) addSettingsItem:(OASettingsItem*)item
{
    if ([_items objectForKey:[item getName]])
        NSLog(@"Already has such item: %@", [item getName]);
    [_items setObject:item forKey:[item getName]];
}
 
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value
{
    [_additionalParams setValue:value forKey:key];
}
 
- (void) exportSettings:(NSString *)file
{
    NSDictionary *json=[[NSDictionary alloc] init];
    [json setValue:[NSString stringWithFormat:@"%ld", OAAppSettings.version] forKey:@"osmand_settings_version"];
    for (NSString*key in _additionalParams)
        [json setValue:[_additionalParams objectForKey:key] forKey:key];
    NSMutableArray *itemsJson = [[NSMutableArray alloc]init];
    for (OASettingsItem *item in [_items allValues])
        [itemsJson addObject:item];
    [json setValue:itemsJson forKey:@"items"];
    
    // not completed
}

@end

#pragma mark - OAExportAsyncTask

@interface OAExportAsyncTask()

@property(nonatomic, retain) NSString *filePath;
@property (weak, nonatomic) id<OASettingsExportDelegate> settingsExportDelegate;


@end

@implementation OAExportAsyncTask
{
    OASettingsHelper* _settingsHelper;
    OASettingsExporter *_exporter;
    OASettingsExport *_exportListener;
}
 
- (instancetype) initWith:(NSString *)settingsFile listener:(OASettingsExport*)listener items:(NSMutableArray<OASettingsItem *>*)items
{
    self = [super init];
    _settingsHelper = [OASettingsHelper sharedInstance];
    _filePath = settingsFile;
    _exportListener = listener;
    _exporter = [[OASettingsExporter alloc] init];
    for (OASettingsItem *item in items)
         [_exporter addSettingsItem:item];
    return self;
}

- (void) executeParameters
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
    @try {
        [_exporter exportSettings:_filePath];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"Failed to export items to: %@ %@", _filePath, exception);
    }
    return NO;
}

- (void) onPostExecute:(BOOL) success
{
    [_settingsHelper.exportTask removeObjectForKey:_filePath];
    if (_exportListener != NULL)
        [_settingsExportDelegate onSettingsExportFinished:_filePath succeed:success];
    
}

@end
