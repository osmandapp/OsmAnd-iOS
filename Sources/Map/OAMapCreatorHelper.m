//
//  OAMapCreatorHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 31/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapCreatorHelper.h"
#import "OALog.h"

@implementation OAMapCreatorHelper

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

        NSMutableArray *filesArray = [NSMutableArray array];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_filesDir error:nil];
        if (files)
            for (NSString *file in files)
                [filesArray addObject:file];
        
        _files = [NSArray arrayWithArray:filesArray];
    }
    return self;
}

- (BOOL)installFile:(NSString *)filePath
{
    NSString *path = [self.filesDir stringByAppendingPathComponent:[filePath lastPathComponent]];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:path error:&error];
    if (error)
        OALog(@"Failed installation MapCreator db file: %@", filePath);
    else
        [_files arrayByAddingObject:[filePath lastPathComponent]];
    
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
    return (error == nil);
}

- (void)removeFile:(NSString *)fileName
{
    NSString *path = [self.filesDir stringByAppendingPathComponent:fileName];

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

    NSMutableArray *arr = [NSMutableArray arrayWithArray:self.files];
    [arr removeObject:fileName];
    _files = [NSArray arrayWithArray:arr];
}

- (NSString *)getNewNameIfExists:(NSString *)fileName
{
    NSString *res;
    
    if ([self.files containsObject:fileName])
    {
        NSFileManager *fileMan = [NSFileManager defaultManager];
        NSString *ext = [fileName pathExtension];
        NSString *newName;
        for (int i = 2; i < 100000; i++) {
            newName = [[NSString stringWithFormat:@"%@_%d", [fileName stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
            if (![fileMan fileExistsAtPath:[self.filesDir stringByAppendingPathComponent:newName]])
                break;
        }
        res = newName;
    }
    
    return res;
}

@end
