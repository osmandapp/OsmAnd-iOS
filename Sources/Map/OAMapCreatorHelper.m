//
//  OAMapCreatorHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 31/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapCreatorHelper.h"

@implementation OAMapCreatorHelper
{
    NSString *_filesDir;
}

+ (OAMapCreatorHelper *)sharedInstance
{
    static dispatch_once_t once;
    static OAMapCreatorHelper * sharedInstance;
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
        _filesDir = [NSHomeDirectory() stringByAppendingString:@"/Library/MapCreator"];
        
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:_filesDir isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:_filesDir withIntermediateDirectories:YES attributes:nil error:nil];

    }
    return self;
}

- (BOOL)containsFile:(NSString *)filePath
{
    return NO;
}

- (NSArray *)getFiles
{
    return nil;
}

- (void)addFile:(NSString *)filePath
{
    
}

@end
