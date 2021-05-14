//
//  OASettingsExporter.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsExporter.h"
#import "OASettingsHelper.h"
#import "OASettingsItem.h"
#import "OAAppSettings.h"
#import "OrderedDictionary.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"

#include <OsmAndCore/ArchiveWriter.h>

#define kVersion 1
#define kTmpProfileFolder @"tmpProfileData"

#pragma mark - OASettingsExporter

@implementation OASettingsExporter
{
    MutableOrderedDictionary *_items;
    MutableOrderedDictionary *_additionalParams;
    BOOL _exportItemsFiles;
    
    OsmAndAppInstance _app;
    
    NSString *_tmpFilesDir;
    
    NSSet<NSString *> *_acceptedExtensions;
}

- (instancetype) initWithExportParam:(BOOL)exportItemsFiles acceptedExtensions:(NSSet<NSString *> *)extensions
{
    self = [super init];
    if (self)
    {
        _items = [MutableOrderedDictionary new];
        _additionalParams = [MutableOrderedDictionary new];
        _exportItemsFiles = exportItemsFiles;
        _acceptedExtensions = extensions;
        
        _app = OsmAndApp.instance;

        _tmpFilesDir = [NSTemporaryDirectory() stringByAppendingPathComponent:kTmpProfileFolder];
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
    NSFileManager *fileManager = NSFileManager.defaultManager;
    // Clear temp profile data
    [fileManager removeItemAtPath:_tmpFilesDir error:nil];
    [fileManager createDirectoryAtPath:_tmpFilesDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSMutableArray<NSString *> *paths = [NSMutableArray new];
    NSDictionary *json = [self createItemsJson];
    NSString *path = [_tmpFilesDir stringByAppendingPathComponent:@"items.json"];
    [paths addObject:path];
    [fileManager removeItemAtPath:path error:nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:error];
    if (!*error)
        [jsonData writeToFile:path atomically:YES];
    if(_exportItemsFiles)
    {
        [self writeItemsFiles:paths];
    }
    OsmAnd::ArchiveWriter archiveWriter;
    const auto stringList = [self stringArrayToQList:paths];
    BOOL ok = YES;
    QString filePath = QString::fromNSString(file);
    archiveWriter.createArchive(&ok, filePath, stringList, QString::fromNSString(_tmpFilesDir));
    if (!ok)
    {
        NSLog(@"Archive creation failed: %@", file);
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            OARootViewController *rootVC = [OARootViewController instance];
            
            UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:file]]
                                              applicationActivities:nil];
            
            activityViewController.popoverPresentationController.sourceView = rootVC.view;
            activityViewController.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(rootVC.view.bounds), CGRectGetMidY(rootVC.view.bounds), 0., 0.);
            activityViewController.popoverPresentationController.permittedArrowDirections = 0;
            
            [rootVC presentViewController:activityViewController
                                 animated:YES
                               completion:nil];
        });
    }
    
    [fileManager removeItemAtPath:_tmpFilesDir error:nil];
}

- (QList<QString>) stringArrayToQList:(NSArray<NSString *> *)array
{
    QList<QString> res;
    for (NSString *str in array)
    {
        res.append(QString::fromNSString(str));
    }
    return res;
}

- (void) writeItemsFiles:(NSMutableArray<NSString *> *)paths
{
    for (OASettingsItem *item in _items.allValues)
    {
        OASettingsItemWriter *writer = [item getWriter];
        if (writer != nil)
        {
            NSString *fileName = item.fileName;
            if (!fileName || fileName.length == 0)
                fileName = item.defaultFileName;
            if (_acceptedExtensions && ![_acceptedExtensions containsObject:fileName.pathExtension])
                continue;
            NSString *path = [_tmpFilesDir stringByAppendingPathComponent:fileName];
            [NSFileManager.defaultManager removeItemAtPath:path error:nil];
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
    json[@"version"] = @(kVersion);
    [_additionalParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        json[key] = obj;
    }];
    NSMutableArray *items = [NSMutableArray new];
    for (OASettingsItem *item in _items.allValues)
    {
        MutableOrderedDictionary *json = [MutableOrderedDictionary new];
        [item writeToJson:json];
        [items addObject:json];
    }
    json[@"items"] = items;
    
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
 
- (instancetype) initWithFile:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles extensionsFilter:(NSString *)extensionsFilter
{
    self = [super init];
    if (self)
    {
        _settingsHelper = [OASettingsHelper sharedInstance];
        _filePath = settingsFile;
        NSSet<NSString *> *acceptedExtensions = nil;
        if (extensionsFilter && extensionsFilter.length > 0)
            acceptedExtensions = [NSSet setWithArray:[extensionsFilter componentsSeparatedByString:@","]];
        _exporter = [[OASettingsExporter alloc] initWithExportParam:exportItemFiles acceptedExtensions:acceptedExtensions];
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
