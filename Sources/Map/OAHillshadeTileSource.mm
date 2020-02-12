//
//  OAHillshadeTileSource.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHillshadeTileSource.h"

@implementation OAHillshadeTileSource

@synthesize tileSize = _tileSize;
@synthesize name = _name;
@synthesize tileFormat = _tileFormat;

-(instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super initWithFilePath:filePath];
    if (self)
    {
        _name = @"Hillshade";
        _tileFormat = @"jpg";
        _tileSize = 256;
    }
    return self;
}

-(BOOL)isLocked
{
    return NO;
}

-(int)bitDensity
{
    return 32;
}

-(int)minimumZoomSupported
{
    return 5;
}

-(int)maximumZoomSupported
{
    return 11;
}

@end
