//
//  OAArchiveWriter.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAArchiveWriter.h"

#include <OsmAndCore/ArchiveWriter.h>

#define TEMP_DIR_NAME @"travelguides"
#define TEMP_GPX_FILE_NAME @"tmp_archiving_file.txt"
#define TEMP_GPX_ARCHIVE_NAME @"tmp_archive_file.gzip"

@implementation OAArchiveWriter
{
    NSString *_tmpDir;
    NSString *_tmpFilePath;
    NSString *_tmpArchivePath;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:TEMP_DIR_NAME];
        _tmpFilePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_FILE_NAME];
        _tmpArchivePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_ARCHIVE_NAME];
    }
    return self;
}

- (void) archiveFile:(NSString *)sourceFileName destPath:(NSString *)archiveFileName dirPath:(NSString *)dirPath
{
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    BOOL ok = YES;
    OsmAnd::ArchiveWriter archiveWriter;
    archiveWriter.createArchive(&ok, {QString::fromNSString(archiveFileName)}, {QString::fromNSString(sourceFileName)}, QString::fromNSString(dirPath), true);
}

- (NSData *) getArchivedFileContent:(NSString *)content
{
    if (content)
    {
        [content writeToFile:_tmpFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [self archiveFile:_tmpFilePath destPath:_tmpArchivePath dirPath:_tmpDir];
        NSData *archivedFileData = [NSData dataWithContentsOfFile:_tmpArchivePath];
        [[NSFileManager defaultManager] removeItemAtPath:_tmpFilePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:_tmpArchivePath error:nil];
        return archivedFileData;
    }
    return  nil;;
}

@end
