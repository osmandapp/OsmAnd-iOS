//
//  OASelectedGPXHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 24/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASelectedGPXHelper.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAObservable.h"
#import "OsmAndSharedWrapper.h"

#define kBackupSuffix @"_osmand_backup"

@interface OAGpxLoader : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic) OASGpxFile *gpxFile;

@end

@implementation OAGpxLoader

@end

@implementation OASelectedGPXHelper
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    NSMutableArray *_selectedGPXFilesBackup;
    NSMutableDictionary<NSString *, OASGpxFile *> *_activeGpx;
}

+ (OASelectedGPXHelper *)instance
{
    static dispatch_once_t once;
    static OASelectedGPXHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _selectedGPXFilesBackup = [NSMutableArray new];
        _activeGpx = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary<NSString *, OASGpxFile *> *)activeGpx {
    return [_activeGpx copy];
}

- (void)removeGpxFileWith:(NSString *)path {
    [_activeGpx removeObjectForKey:path];
}

- (void)addGpxFile:(OASGpxFile *)file for:(NSString *)path {
    _activeGpx[path] = file;
}

- (nullable OASGpxFile *)getGpxFileFor:(NSString *)path {
    return _activeGpx[path];
}

- (BOOL)containsGpxFileWith:(NSString *)path {
    return (_activeGpx[path] != nil);
}

- (void)markTrackForReload:(NSString *)filePath
{
    [self removeGpxFileWith:filePath];
}

- (BOOL) buildGpxList
{
    BOOL loading = NO;
    [_settings hideRemovedGpx];

    for (NSString *filePath in _settings.mapSettingVisibleGpx.get)
    {
        if ([filePath hasSuffix:kBackupSuffix])
        {
            [_selectedGPXFilesBackup addObject:filePath];
            continue;
        }
        NSString *absoluteGpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:filePath];
        OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:absoluteGpxFilepath];
        NSString __block *path = gpx.file.absolutePath;

        if ([[NSFileManager defaultManager] fileExistsAtPath:path] && ![self containsGpxFileWith:path])
        {
            OAGpxLoader __block *loader = [[OAGpxLoader alloc] init];
            loader.path = path;
            _activeGpx[path] = nil;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                OASKFile *file = [[OASKFile alloc] initWithFilePath:path];
                OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
                loader.gpxFile = gpxFile;
                dispatch_async(dispatch_get_main_queue(), ^{
                    _activeGpx[loader.path] = loader.gpxFile;
                    [[_app updateGpxTracksOnMapObservable] notifyEvent];
                });
            });
            loading = YES;
        }
    }
    
    NSArray<NSString *> *mapSettingVisibleGpx = [_settings.mapSettingVisibleGpx get];
    NSMutableArray<NSString *> *keysToRemove = [NSMutableArray array];

    for (NSString *key in _activeGpx.allKeys) {
        NSString *gpxFilePath = [OAUtilities getGpxShortPath:key];

        if (![mapSettingVisibleGpx containsObject:gpxFilePath]) {
            [keysToRemove addObject:key];
        }
    }
    [_activeGpx removeObjectsForKeys:keysToRemove];

    return loading;
}

- (OASGpxFile *)getSelectedGpx:(OASWptPt *)gpxWpt {
    for (OASGpxFile *gpxFile in _activeGpx.allValues) {
        if ([[gpxFile getPointsList] containsObject:gpxWpt]) {
            return gpxFile;
        }
    }
    return nil;
}

-(BOOL) isShowingAnyGpxFiles
{
    return _activeGpx.count > 0;
}

-(void) clearAllGpxFilesToShow:(BOOL) backupSelection
{
    NSMutableArray *backedUp = [NSMutableArray new];
    if (backupSelection)
    {
        NSArray *currentlyVisible = _settings.mapSettingVisibleGpx.get;
        for (NSString *filePath in currentlyVisible)
        {
            [backedUp addObject:[filePath stringByAppendingString:kBackupSuffix]];
        }
    }
    [_activeGpx removeAllObjects];
    [_settings.mapSettingVisibleGpx set:[NSArray arrayWithArray:backedUp]];
    [_selectedGPXFilesBackup removeAllObjects];
    [_selectedGPXFilesBackup addObjectsFromArray:backedUp];
}

-(void) restoreSelectedGpxFiles
{
    NSMutableArray *restored = [NSMutableArray new];
    if (_selectedGPXFilesBackup.count == 0)
        [self buildGpxList];
    for (NSString *backedUp in _selectedGPXFilesBackup)
    {
        if ([backedUp hasSuffix:kBackupSuffix])
        {
            [restored addObject:[backedUp stringByReplacingOccurrencesOfString:kBackupSuffix withString:@""]];
        }
    }
    [_settings.mapSettingVisibleGpx set:[NSArray arrayWithArray:restored]];
    [self buildGpxList];
    [_selectedGPXFilesBackup removeAllObjects];
}

+ (void) renameVisibleTrack:(NSString *)oldPath newPath:(NSString *)newPath
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSMutableArray *visibleGpx = [NSMutableArray arrayWithArray:settings.mapSettingVisibleGpx.get];
    for (NSString *gpx in settings.mapSettingVisibleGpx.get)
    {
        if ([gpx isEqualToString:oldPath])
        {
            [visibleGpx removeObject:gpx];
            [visibleGpx addObject:newPath];
            break;
        }
    }
    
    [settings.mapSettingVisibleGpx set:[NSArray arrayWithArray:visibleGpx]];
}

- (NSString *) getSelectedGPXFilePath:(NSString *)fileName
{
    NSString *suffix = [NSString stringWithFormat:@"/%@", fileName];
    for (NSString *selectedGpxFile in _selectedGPXFilesBackup)
    {
        if ([selectedGpxFile hasSuffix:suffix])
        {
            return fileName;
        }
    }
    return nil;
}

@end
