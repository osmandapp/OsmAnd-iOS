//
//  OsmAndAppImpl.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OsmAndAppImpl.h"

#include <algorithm>

#include <QStandardPaths>
#include <QList>

#include <OsmAndCore.h>
#include <OsmAndCore/Data/ObfFile.h>
#include <OsmAndCore/Data/ObfReader.h>

@implementation OsmAndAppImpl
{
    std::shared_ptr<OsmAnd::ObfFile> _worldMiniBasemap;
    QString _documentsPath;
    QString _cachePath;
}

@synthesize obfsCollection = _obfsCollection;
@synthesize mapStyles = _mapStyles;

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    // First of all, initialize configuration
    _configuration = [[OAConfiguration alloc] init];
    
    // Get location of a shipped world mini-basemap and it's version stamp
    NSString* worldMiniBasemapFilename = [[NSBundle mainBundle] pathForResource:@"WorldMiniBasemap"
                                                        ofType:@"obf"
                                                   inDirectory:@"Shipped"];
    NSString* worldMiniBasemapStamp = [[NSBundle mainBundle] pathForResource:@"WorldMiniBasemap.obf"
                                                                      ofType:@"stamp"
                                                                 inDirectory:@"Shipped"];
    NSError* versionError = nil;
    NSString* worldMiniBasemapStampContents = [NSString stringWithContentsOfFile:worldMiniBasemapStamp
                                                                  encoding:NSASCIIStringEncoding
                                                                     error:&versionError];
    NSString* worldMiniBasemapVersion = [worldMiniBasemapStampContents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"Located shipped world mini-basemap (version %@) at %@", worldMiniBasemapVersion, worldMiniBasemapFilename);
    _worldMiniBasemap.reset(new OsmAnd::ObfFile(QString::fromNSString(worldMiniBasemapFilename)));
    
    // Get default paths
    _documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    NSLog(@"Documents path: %s", qPrintable(_documentsPath));
    _cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    NSLog(@"Cache path: %s", qPrintable(_cachePath));
    
    [self initObfsCollection];
    [self initMapStyles];
    
    _mapModeObservable = [[OAObservable alloc] init];
    
    _locationServices = [[OALocationServices alloc] initWith:self];
    if(_locationServices.available && _locationServices.allowed)
        [_locationServices start];
}

- (void)initObfsCollection
{
    _obfsCollection.reset(new OsmAnd::ObfsCollection());
    
    // Set modifier to add world mini-basemap if there's no other basemap available
    _obfsCollection->setSourcesSetModifier([self](const OsmAnd::ObfsCollection& collection, QList< std::shared_ptr<OsmAnd::ObfReader> >& inOutSources)
    {
        const auto basemapPresent = std::any_of(inOutSources.cbegin(), inOutSources.cend(), [](const std::shared_ptr<OsmAnd::ObfReader>& obfReader)
        {
            return obfReader->obtainInfo()->isBasemap;
        });
        
        // If there's no basemap present, add mini-basemap
        if(!basemapPresent)
            inOutSources.push_back(std::shared_ptr<OsmAnd::ObfReader>(new OsmAnd::ObfReader(_worldMiniBasemap)));
    });
    
    // Register "Documents" directory (which is accessible from iTunes)
    _obfsCollection->registerDirectory(_documentsPath);
}

- (void)initMapStyles
{
    _mapStyles.reset(new OsmAnd::MapStyles());
}

@synthesize configuration = _configuration;

@synthesize locationServices = _locationServices;

@synthesize mapMode = _mapMode;
@synthesize mapModeObservable = _mapModeObservable;

- (void)setMapMode:(OAMapMode)mapMode
{
    if(_mapMode == mapMode)
        return;
    _mapMode = mapMode;
    [_mapModeObservable notifyEvent];
}

@end
