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
#import "OAExportAsyncTask.h"
#import "OALog.h"

#include <OsmAndCore/ArchiveWriter.h>

#define kTmpProfileFolder @"tmpProfileData"

#pragma mark - OASettingsExporter

@implementation OASettingsExporter
{
    MutableOrderedDictionary *_additionalParams;
    BOOL _exportItemsFiles;
    
    OsmAndAppInstance _app;
    
    NSString *_tmpFilesDir;
    
    NSSet<NSString *> *_acceptedExtensions;
}

- (instancetype) initWithExportParam:(BOOL)exportItemsFiles acceptedExtensions:(NSSet<NSString *> *)extensions
{
    self = [super initWithListener:nil];
    if (self)
    {
        _additionalParams = [MutableOrderedDictionary new];
        _exportItemsFiles = exportItemsFiles;
        _acceptedExtensions = extensions;
        
        _app = OsmAndApp.instance;

        _tmpFilesDir = [NSTemporaryDirectory() stringByAppendingPathComponent:kTmpProfileFolder];
    }
    return self;
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
        NSString *message = [NSString stringWithFormat:@"Archive creation failed: %@", file];
        OALog(@"%@", message);
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:message forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"SettingsExporter" code:0 userInfo:details];
    }
    else
    {
        error = nil;
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
    for (OASettingsItem *item in self.getItems)
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

@end
