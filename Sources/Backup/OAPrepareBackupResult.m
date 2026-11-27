//
//  OAPrepareBackupResult.m
//  OsmAnd Maps
//
//  Created by Paul on 22.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAPrepareBackupResult.h"
#import "OARemoteFile.h"
#import "OALocalFile.h"

@implementation OAPrepareBackupResult
{
    NSDictionary<NSString *, OARemoteFile *> *_uniqueRemoteFiles;
    NSDictionary<NSString *, OARemoteFile *> *_uniqueInfoRemoteFiles;
    NSDictionary<NSString *, OARemoteFile *> *_deletedRemoteFiles;
    NSDictionary<NSString *, OARemoteFile *> *_oldRemoteFiles;
}

- (NSDictionary<NSString *, OARemoteFile *> *) getRemoteFiles:(EOARemoteFilesType)type
{
    switch (type)
    {
        case EOARemoteFilesTypeUnique:
            return _uniqueRemoteFiles;
        case EOARemoteFilesTypeUniqueInfo:
            return _uniqueInfoRemoteFiles;
        case EOARemoteFilesTypeDeleted:
            return _deletedRemoteFiles;
        case EOARemoteFilesTypeOld:
            return _oldRemoteFiles;
        default:
            return _remoteFiles;
    }
}

- (OARemoteFile *) getRemoteFile:(NSString *)type fileName:(NSString *)fileName
{
    return _remoteFiles[[self getTypeWithName:type fileName:fileName]];
}

- (OARemoteFile *) getNormalizedRemoteFile:(NSString *)type fileName:(NSString *)fileName
{
    return _normalizedRemoteFiles[[self getTypeWithName:type fileName:fileName].precomposedStringWithCanonicalMapping];
}

- (NSString *) getTypeWithName:(NSString *)type fileName:(NSString *)fileName
{
    return fileName.length > 0 ? [type stringByAppendingPathComponent:fileName] : type;
}

+ (BOOL) isRemoteFile:(OARemoteFile *)remoteFile preferredTo:(OARemoteFile *)other
{
    if (remoteFile.isDeleted != other.isDeleted)
        return other.isDeleted;
    return remoteFile.updatetimems > other.updatetimems;
}

- (void)setRemoteFilesFromArray:(NSArray<OARemoteFile *> *)remoteFiles
{
    NSMutableDictionary<NSString *, OARemoteFile *> *remoteFilesMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OARemoteFile *> *oldRemoteFiles = [NSMutableDictionary dictionary];
    for (OARemoteFile *file in remoteFiles)
    {
        NSString *typeNamePath = file.getTypeNamePath;
        if (!remoteFilesMap[typeNamePath])
            remoteFilesMap[typeNamePath] = file;
        else if (![oldRemoteFiles.allKeys containsObject:typeNamePath] && !file.isInfoFile && !file.isDeleted)
            oldRemoteFiles[typeNamePath] = file;
    }
    NSMutableDictionary<NSString *, OARemoteFile *> *uniqueRemoteFiles = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OARemoteFile *> *uniqueInfoRemoteFiles = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OARemoteFile *> *deletedRemoteFiles = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *uniqueFileIds = [NSMutableSet set];
    [remoteFilesMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fileId, OARemoteFile * _Nonnull file, BOOL * _Nonnull stop) {
        if (![uniqueFileIds containsObject:fileId])
        {
            [uniqueFileIds addObject:fileId];
            if (file.isInfoFile)
                uniqueInfoRemoteFiles[fileId] = file;
            else if (file.isDeleted)
                deletedRemoteFiles[fileId] = file;
            else
                uniqueRemoteFiles[fileId] = file;
        }
    }];
    _uniqueRemoteFiles = uniqueRemoteFiles;
    _uniqueInfoRemoteFiles = uniqueInfoRemoteFiles;
    _deletedRemoteFiles = deletedRemoteFiles;
    _oldRemoteFiles = oldRemoteFiles;
    _remoteFiles = remoteFilesMap;
    NSMutableDictionary<NSString *, OARemoteFile *> *normalizedRemoteFiles = [NSMutableDictionary dictionaryWithCapacity:uniqueRemoteFiles.count + deletedRemoteFiles.count];
    for (NSDictionary<NSString *, OARemoteFile *> *files in @[uniqueRemoteFiles, deletedRemoteFiles])
    {
        for (OARemoteFile *remoteFile in files.allValues)
        {
            NSString *normalizedKey = [remoteFile getNormalizedTypeNamePath];
            OARemoteFile *existing = normalizedRemoteFiles[normalizedKey];
            if (!existing || [self.class isRemoteFile:remoteFile preferredTo:existing])
                normalizedRemoteFiles[normalizedKey] = remoteFile;
        }
    }
    _normalizedRemoteFiles = normalizedRemoteFiles;
}

- (void)setLocalFilesFromArray:(NSArray<OALocalFile *> *)localFiles
{
    NSMutableDictionary<NSString *, OALocalFile *> *localFileMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OALocalFile *> *normalizedLocalFiles = [NSMutableDictionary dictionary];
    for (OALocalFile *localFile in localFiles)
    {
        localFileMap[localFile.getTypeFileName] = localFile;
        NSString *normalizedKey = [localFile getNormalizedTypeFileName];
        OALocalFile *existing = normalizedLocalFiles[normalizedKey];
        if (!existing || localFile.localModifiedTime > existing.localModifiedTime)
            normalizedLocalFiles[normalizedKey] = localFile;
    }
    _localFiles = localFileMap;
    _normalizedLocalFiles = normalizedLocalFiles;
}

@end
