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

#define kBackupSuffix @"_osmand_backup"

@interface OAGpxLoader : NSObject

@property (nonatomic) QString path;
@property (nonatomic) std::shared_ptr<const OsmAnd::GeoInfoDocument> document;

@end

@implementation OAGpxLoader

@end


@implementation OASelectedGPXHelper
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    NSMutableArray *_selectedGPXFilesBackup;
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
    }
    return self;
}

- (BOOL) buildGpxList
{
    BOOL loading = NO;
    [_settings hideRemovedGpx];

    for (NSString *filePath in _settings.mapSettingVisibleGpx)
    {
        if ([filePath hasSuffix:kBackupSuffix])
        {
            [_selectedGPXFilesBackup addObject:filePath];
            continue;
        }
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filePath];
        NSString __block *path = [_app.gpxPath stringByAppendingPathComponent:gpx.file];
        QString qPath = QString::fromNSString(path);
        if ([[NSFileManager defaultManager] fileExistsAtPath:path] && !_activeGpx.contains(qPath))
        {
            OAGpxLoader __block *loader = [[OAGpxLoader alloc] init];
            loader.path = qPath;
    
            _activeGpx[qPath] = nullptr;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                loader.document = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path));
                dispatch_async(dispatch_get_main_queue(), ^{
                    _activeGpx[loader.path] = loader.document;
                    [[_app updateGpxTracksOnMapObservable] notifyEvent];
                });
            });
            loading = YES;
        }
    }
    for (auto it = _activeGpx.begin(); it != _activeGpx.end(); )
    {
        NSString *gpxFilePath = [OAGPXDatabase.sharedDb getGpxStoringPathByFullPath:it.key().toNSString()];
        if (![_settings.mapSettingVisibleGpx containsObject:gpxFilePath])
            it = _activeGpx.erase(it);
        else
            ++it;
    }
    return loading;
}

-(BOOL) isShowingAnyGpxFiles
{
    return _activeGpx.count() > 0;
}

-(void) clearAllGpxFilesToShow:(BOOL) backupSelection
{
    NSMutableArray *backedUp = [NSMutableArray new];
    if (backupSelection)
    {
        NSArray *currentlyVisible = _settings.mapSettingVisibleGpx;
        for (NSString *filePath in currentlyVisible)
        {
            [backedUp addObject:[filePath stringByAppendingString:kBackupSuffix]];
        }
    }
    _activeGpx.clear();
    [_settings setMapSettingVisibleGpx:[NSArray arrayWithArray:backedUp]];
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
    [_settings setMapSettingVisibleGpx:[NSArray arrayWithArray:restored]];
    [self buildGpxList];
    [_selectedGPXFilesBackup removeAllObjects];
}

+ (void) renameVisibleTrack:(NSString *)oldPath newPath:(NSString *)newPath
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSMutableArray *visibleGpx = [NSMutableArray arrayWithArray:settings.mapSettingVisibleGpx];
    for (NSString *gpx in settings.mapSettingVisibleGpx)
    {
        if ([gpx isEqualToString:oldPath])
        {
            [visibleGpx removeObject:gpx];
            [visibleGpx addObject:newPath];
            break;
        }
    }
    
    settings.mapSettingVisibleGpx = [NSArray arrayWithArray:visibleGpx];
}

@end
