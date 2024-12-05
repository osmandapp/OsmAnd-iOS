//
//  OAExportAsyncTask.m
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAExportAsyncTask.h"
#import "OASettingsExporter.h"
#import "OALog.h"

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
        BOOL success = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:success];
        });
    });
}

- (BOOL) doInBackground
{
    NSError *exportError;
    [_exporter exportSettings:_filePath error:&exportError];
    if (exportError)
    {
        OALog(@"Failed to export items to: %@ %@", _filePath, exportError);
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
