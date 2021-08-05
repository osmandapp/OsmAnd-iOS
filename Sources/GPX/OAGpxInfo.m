//
//  OAGpxInfo.m
//  OsmAnd
//
//  Created by Anna Bibyk on 30.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxInfo.h"
#import "OAUtilities.h"

@implementation OAGpxInfo
{
    NSString *_name;
    NSInteger _sz;
    NSString *_fileName;
    BOOL _corrupted;
}
 
- (instancetype) initWithGpx:(OAGPX *)gpx name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _gpx = gpx;
        _name = name;
    }
    return self;
}

- (NSString *) getName
{
    if (!_name)
    {
        _name = [self formatName:[_file lastPathComponent]];
    }
    return [_name precomposedStringWithCanonicalMapping];
}

- (NSString *) formatName:(NSString *)name
{
    return [[name stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (BOOL) isCorrupted
{
    return _corrupted;
}

- (NSInteger) getSize
{
    if (!_sz)
    {
        if (!_file)
            return -1;
        NSUInteger fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_file error:nil] fileSize];
        NSError *error = nil;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:_file error:&error];
        if (attrs) {
            NSString *size = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleBinary];
            _sz = [size integerValue];
        }
    }
    return _sz;
}

- (NSDate *) getFileDate
{
    if (!_file)
        return 0;
    return [OAUtilities getFileLastModificationDate:_file];
}

- (NSString *) getFileName
{
    if (_fileName)
        return _fileName;
    if (!_file)
        return @"";
    return _fileName = [_file lastPathComponent];
}

@end
