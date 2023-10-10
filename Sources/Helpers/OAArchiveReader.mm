//
//  OAArchiveReader.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAArchiveReader.h"

#include <OsmAndCore/ArchiveReader.h>

#define TEMP_GPX_FILE_NAME @"tmp_archiving_file.txt"
#define TEMP_GPX_ARCHIVE_NAME @"tmp_archive_file.gzip"

@implementation OAArchiveReader
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
        _tmpDir = NSTemporaryDirectory();
        _tmpFilePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_FILE_NAME];
        _tmpArchivePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_ARCHIVE_NAME];
    }
    return self;
}

- (void) unarchiveFile:(NSString *)archiveFileName destFileName:(NSString *)destFileName dirPath:(NSString *)dirPath
{
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    bool ok = false;
    bool success = false;
    OsmAnd::ArchiveReader archive(QString::fromNSString(_tmpArchivePath));
    const auto archiveItems = archive.getItems(&ok, true);
    if (ok)
    {
        for (const auto& archiveItem : constOf(archiveItems))
        {
            if (!archiveItem.isValid())
                continue;
            
            success = archiveItem.isValid() && archive.extractItemToFile(archiveItem.name, QString::fromNSString(destFileName), true);
            break;
        }
    }
}

- (NSString *) getUnarchivedFileContent:(NSString *)archivedContent
{
    [archivedContent writeToFile:_tmpArchivePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self unarchiveFile:_tmpArchivePath destFileName:_tmpFilePath dirPath:_tmpDir];
    NSString *unarchivedFileContent = [NSString stringWithContentsOfFile:_tmpFilePath encoding:NSUTF8StringEncoding error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_tmpFilePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_tmpArchivePath error:nil];
    return unarchivedFileContent;
}

- (NSString *) getUnarchivedFileContentForData:(NSData *)archivedData
{
    [archivedData writeToFile:_tmpArchivePath atomically:YES];
    [self unarchiveFile:_tmpArchivePath destFileName:_tmpFilePath dirPath:_tmpDir];
    NSString *unarchivedFileContent = [NSString stringWithContentsOfFile:_tmpFilePath encoding:NSUTF8StringEncoding error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_tmpFilePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_tmpArchivePath error:nil];
    return unarchivedFileContent;
}


@end
