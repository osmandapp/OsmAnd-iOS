//
//  OALoadGpxTask.m
//  OsmAnd
//
//  Created by Anna Bibyk on 31.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OALoadGpxTask.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"

#import "Localization.h"

@implementation OALoadGpxTask
{
    NSMutableArray <OAGpxInfo *> *_result;
    NSMutableDictionary<NSString *, NSArray<OAGpxInfo *> *> *_gpxFolders;
}

- (void) execute:(void(^)(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>*))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:onComplete];
        });
    });
}
- (void) doInBackground
{
    _result = [NSMutableArray array];
    [self loadGPXData:OsmAndApp.instance.gpxPath];
    _gpxFolders = [NSMutableDictionary dictionaryWithDictionary:[self getTracksByFolder]];
}

- (NSDictionary<NSString *, NSArray<OAGpxInfo *> *> *) getTracksByFolder
{
    NSMutableDictionary *folders = [NSMutableDictionary dictionary];
    NSMutableArray *tracksFolder = [NSMutableArray array];
    for (OAGpxInfo *info in _result)
    {
        if (info.subfolder.length > 0)
        {
            NSMutableArray *array = [folders objectForKey:info.subfolder];
            if (!array)
            {
                array = [NSMutableArray array];
                [folders setObject:array forKey:info.subfolder];
            }
            [array addObject:info];
        }
        else
        {
            [tracksFolder addObject:info];
        }
    }
    if (tracksFolder.count > 0)
        [folders setObject:tracksFolder forKey:OALocalizedString(@"shared_string_gpx_tracks")];
    return folders;
}

- (void) onPostExecute:(void(^)(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>*))onComplete
{
    if (onComplete)
        onComplete(_gpxFolders);
}

- (void) loadGPXData:(NSString *)mapPath
{
    [self loadGPXFolder:mapPath scanningFolderShortPath:@""];
}

- (void) loadGPXFolder:(NSString *)scanningFolderFullPath scanningFolderShortPath:(NSString *)scanningFolderShortPath
{
    NSArray* folderContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:scanningFolderFullPath error:nil];
    for (NSString *item in folderContent)
    {
        if([item hasPrefix:@"."])
            continue;
        
        NSString *itemPath = [scanningFolderFullPath stringByAppendingPathComponent:item];
        if ([OAUtilities isDirByPath:itemPath])
        {
            NSString *subfolderShortPath = [scanningFolderShortPath stringByAppendingPathComponent:item];
            NSString *subfolderFullPath = [scanningFolderFullPath stringByAppendingPathComponent:item];
            [self loadGPXFolder:subfolderFullPath scanningFolderShortPath:subfolderShortPath];
        }
        else if ([[[item lowercaseString] pathExtension] isEqualToString:@"gpx"])
        {
            NSString *gpxFilename = item;
            NSString *gpxShortPath = [scanningFolderShortPath stringByAppendingPathComponent:item];
            OAGpxInfo *info = [[OAGpxInfo alloc] init];
            info.subfolder = scanningFolderShortPath;
            info.file = gpxFilename;
            info.gpx = [OAGPXDatabase.sharedDb getGPXItem:gpxShortPath];
            [_result addObject:info];
        }
    }
}

@end
