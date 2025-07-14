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
#import "OsmAnd_Maps-Swift.h"

static NSString *kBackupSuffix = @"_osmand_backup";

@implementation OASelectedGPXHelper
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    NSMutableArray *_selectedGPXFilesBackup;
    NSMutableArray *_loadingGPXPaths;
    NSMutableDictionary<NSString *, OASGpxFile *> *_activeGpx;
    NSOperationQueue *_operationQueue;
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
        _loadingGPXPaths = [NSMutableArray new];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 4;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (NSDictionary<NSString *, OASGpxFile *> *)activeGpx
{
    return [_activeGpx copy];
}

- (void)removeGpxFileWith:(NSString *)path {
    [_activeGpx removeObjectForKey:path];
}

- (void)addGpxFile:(OASGpxFile *)file for:(NSString *)path
{
    _activeGpx[path] = file;
}

- (nullable OASGpxFile *)getGpxFileFor:(NSString *)path
{
    return _activeGpx[path];
}

- (BOOL)containsGpxFileWith:(NSString *)path
{
    return (_activeGpx[path] != nil);
}

- (void)markTrackForReload:(NSString *)filePath
{
    [self removeGpxFileWith:filePath];
}

- (BOOL)buildGpxList
{
    [_settings hideRemovedGpx];
    
    NSSet<NSString *> *mapSettingVisibleGpx = [NSSet setWithArray:[_settings.mapSettingVisibleGpx get]];
    
    if (_loadingGPXPaths.count > 0)
    {
        [self removeInactiveGpxFiles:mapSettingVisibleGpx];
        return YES;
    }
    
    NSMutableArray<GpxLoadOperation *> *gpxLoadOperations = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    
    for (NSString *filePath in mapSettingVisibleGpx)
    {
        @autoreleasepool {
            if ([filePath hasSuffix:kBackupSuffix])
            {
                [_selectedGPXFilesBackup addObject:filePath];
                continue;
            }
            NSString *absoluteGpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:filePath];
            if ([self shouldLoadFileAtPath:absoluteGpxFilepath])
            {
                [_loadingGPXPaths addObject:absoluteGpxFilepath];
                GpxLoadOperation *loadOperation = [[GpxLoadOperation alloc] initWithFilePath:absoluteGpxFilepath];
                loadOperation.completeHandler =^(NSString *absoluteFilePath, OASGpxFile *gpxFile) {
                    [weakSelf completeTrackLoadingForFilePath:absoluteFilePath gpxFile:gpxFile];
                };
                loadOperation.cancelledHandler = ^(NSString *absoluteFilePath) {
                    [weakSelf removeFilePathFromLoadingQueue:absoluteFilePath];
                };
                [gpxLoadOperations addObject:loadOperation];
            }
        }
    }
    if (gpxLoadOperations.count > 0)
        [_operationQueue addOperations:gpxLoadOperations waitUntilFinished:NO];
    
    [self removeInactiveGpxFiles:mapSettingVisibleGpx];
    
    return _loadingGPXPaths.count > 0;
}

- (void)removeInactiveGpxFiles:(NSSet<NSString *> *)mapSettingVisibleGpx
{
    NSMutableArray<NSString *> *keysToRemove = [NSMutableArray array];
    
    for (NSString *key in _activeGpx.allKeys)
    {
        NSString *gpxFilePath = [OAUtilities getGpxShortPath:key];
        
        if (![mapSettingVisibleGpx containsObject:gpxFilePath])
            [keysToRemove addObject:key];
    }
    
    if (keysToRemove.count > 0)
        [_activeGpx removeObjectsForKeys:keysToRemove];
}

- (BOOL)shouldLoadFileAtPath:(NSString *)filePath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath]
           && ![self containsGpxFileWith:filePath]
           && ![_loadingGPXPaths containsObject:filePath];
}

- (void)removeFilePathFromLoadingQueue:(NSString *)filePath
{
    [_loadingGPXPaths removeObject:filePath];
}

- (void)completeTrackLoadingForFilePath:(NSString *)absoluteFilePath
                                gpxFile:(OASGpxFile *)gpxFile
{
    _activeGpx[absoluteFilePath] = gpxFile;
    [self removeFilePathFromLoadingQueue:absoluteFilePath];
    [[_app updateGpxTracksOnMapObservable] notifyEvent];
}

- (OASGpxFile *)getSelectedGpx:(OASWptPt *)gpxWpt {
    for (OASGpxFile *gpxFile in _activeGpx.allValues) {
        if ([[gpxFile getPointsList] containsObject:gpxWpt]) {
            return gpxFile;
        }
    }
    return nil;
}

- (BOOL)isShowingAnyGpxFiles
{
    return _activeGpx.count > 0;
}

- (void)clearAllGpxFilesToShow:(BOOL) backupSelection
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

- (void)restoreSelectedGpxFiles
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

+ (void)renameVisibleTrack:(NSString *)oldPath newPath:(NSString *)newPath
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

- (NSString *)getSelectedGPXFilePath:(NSString *)fileName
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

- (NSArray<OASGpxFile *> *)getSelectedGPXFiles
{
    return [_activeGpx allValues];
}

- (OASWptPt *)getVisibleWayPointByLat:(double)lat lon:(double)lon
{
    CLLocationCoordinate2D markerLatLon = CLLocationCoordinate2DMake(lat, lon);
    if (CLLocationCoordinate2DIsValid(markerLatLon))
    {
        for (OASGpxFile *selectedGpx in _activeGpx)
        {
            for (OASWptPt *point in [selectedGpx getPointsList])
            {
                CLLocationCoordinate2D pointLatLon = CLLocationCoordinate2DMake(point.lat, point.lon);
                if (CLLocationCoordinate2DIsValid(pointLatLon) &&
                    [OAUtilities isCoordEqual:markerLatLon destLat:pointLatLon])
                    return point;
            }
        }
    }
    return nil;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    // cancel all operations download GPX
    [_operationQueue cancelAllOperations];
    [_loadingGPXPaths removeAllObjects];
}

@end
