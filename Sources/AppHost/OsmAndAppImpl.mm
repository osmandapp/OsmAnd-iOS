//
//  OsmAndAppImpl.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OsmAndAppImpl.h"

#import "OsmAndApp.h"
#import "OALog.h"

#include <algorithm>

#include <QList>

#include <OsmAndCore.h>

@implementation OsmAndAppImpl
{
    NSString* _worldMiniBasemapFilename;
}

@synthesize dataPath = _dataPath;
@synthesize documentsPath = _documentsPath;
@synthesize cachePath = _cachePath;

@synthesize resourcesManager = _resourcesManager;

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

#define kAppData @"app_data"

- (void)ctor
{
    // Get default paths
    _dataPath = QDir(QString::fromNSString([NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject]));
    _documentsPath = QDir(QString::fromNSString([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]));
    _cachePath = QDir(QString::fromNSString([NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]));

    // First of all, initialize user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self inflateInitialUserDefaults]];
}

- (void)dtor
{
}

- (BOOL)initialize
{
    NSError* versionError = nil;

    OALog(@"Data path: %s", qPrintable(_dataPath.absolutePath()));
    OALog(@"Documents path: %s", qPrintable(_documentsPath.absolutePath()));
    OALog(@"Cache path: %s", qPrintable(_cachePath.absolutePath()));

    // Unpack app data
    _data = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:kAppData]];

    // Get location of a shipped world mini-basemap and it's version stamp
    _worldMiniBasemapFilename = [[NSBundle mainBundle] pathForResource:@"WorldMiniBasemap"
                                                                ofType:@"obf"
                                                           inDirectory:@"Shipped"];
    NSString* worldMiniBasemapStamp = [[NSBundle mainBundle] pathForResource:@"WorldMiniBasemap.obf"
                                                                      ofType:@"stamp"
                                                                 inDirectory:@"Shipped"];
    NSString* worldMiniBasemapStampContents = [NSString stringWithContentsOfFile:worldMiniBasemapStamp
                                                                        encoding:NSASCIIStringEncoding
                                                                           error:&versionError];
    NSString* worldMiniBasemapVersion = [worldMiniBasemapStampContents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    OALog(@"Located shipped world mini-basemap (version %@) at %@", worldMiniBasemapVersion, _worldMiniBasemapFilename);

    _resourcesManager.reset(new OsmAnd::ResourcesManager(_dataPath.absoluteFilePath(QLatin1String("Resources")),
                                                         _documentsPath.absolutePath(),
                                                         QList<QString>(),
                                                         _worldMiniBasemapFilename != nil
                                                         ? QString::fromNSString(_worldMiniBasemapFilename)
                                                         : QString::null,
                                                         QString::fromNSString(NSTemporaryDirectory())));

    // Load world regions
    NSString* worldRegionsFilename = [[NSBundle mainBundle] pathForResource:@"regions"
                                                                     ofType:@"ocbf"];
    _worldRegion = [OAWorldRegion loadFrom:worldRegionsFilename];

    _mapModeObservable = [[OAObservable alloc] init];

    _locationServices = [[OALocationServices alloc] initWith:self];
    if (_locationServices.available && _locationServices.allowed)
        [_locationServices start];

    return YES;
}

- (NSDictionary*)inflateInitialUserDefaults
{
    NSMutableDictionary* initialUserDefaults = [[NSMutableDictionary alloc] init];

    [initialUserDefaults setValue:[NSKeyedArchiver archivedDataWithRootObject:[OAAppData defaults]]
                           forKey:kAppData];

    return initialUserDefaults;
}

@synthesize data = _data;
@synthesize worldRegion = _worldRegion;

@synthesize locationServices = _locationServices;

@synthesize mapMode = _mapMode;
@synthesize mapModeObservable = _mapModeObservable;

- (void)setMapMode:(OAMapMode)mapMode
{
    if (_mapMode == mapMode)
        return;
    _mapMode = mapMode;
    [_mapModeObservable notifyEvent];
}

- (void)saveState
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    // Save app data to user-defaults
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_data]
                                              forKey:kAppData];
    [userDefaults synchronize];
}

@end
