//
//  OsmAndAppImpl.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OsmAndAppImpl.h"

#include <QStandardPaths>

@implementation OsmAndAppImpl
{
    QString _documentsPath;
    //QString _dataPath;
    //QString _cachePath;
    //QString _downloadsPath;
}

@synthesize obfsCollection = _obfsCollection;
@synthesize mapStyles = _mapStyles;

- (id)init
{
    self = [super init];
    if (self) {
        _documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        NSLog(@"Documents path: %s", qPrintable(_documentsPath));
        /*
         _dataPath = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
         NSLog(@"Data path: %s", qPrintable(_dataPath));
         _cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
         NSLog(@"Cache path: %s", qPrintable(_cachePath));
         _downloadsPath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
         NSLog(@"Downloads path: %s", qPrintable(_downloadsPath));
         */
        
        [self initObfsCollection];
        [self initMapStyles];
    }
    return self;
}

- (void)initObfsCollection
{
    _obfsCollection.reset(new OsmAnd::ObfsCollection());
    
    // Watch shared "Documents" directory
    _obfsCollection->watchDirectory(_documentsPath);
}

- (void)initMapStyles
{
    _mapStyles.reset(new OsmAnd::MapStyles());
}

@end
