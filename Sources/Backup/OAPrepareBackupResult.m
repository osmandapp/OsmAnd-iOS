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
    switch (type) {
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
    NSString *typeWithName;
    if (fileName.length > 0)
        typeWithName = [type stringByAppendingPathComponent:fileName];
    else
        typeWithName = type;
    return _remoteFiles[typeWithName];
}

- (void)setRemoteFiles:(NSDictionary<NSString *,OARemoteFile *> *)remoteFiles
{
    NSMutableDictionary<NSString *, OARemoteFile *> *remoteFilesMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OARemoteFile *> *oldRemoteFiles = [NSMutableDictionary dictionary];
    for (OARemoteFile *rf in remoteFiles)
    {
        NSString *typeNamePath = rf.getTypeNamePath;
        if (!remoteFilesMap[typeNamePath])
            remoteFilesMap[typeNamePath] = rf;
        else if (!rf.isInfoFile && !rf.isDeleted)
            oldRemoteFiles[typeNamePath] = rf;
    }
    NSMutableDictionary<NSString *, OARemoteFile *> *uniqueRemoteFiles = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OARemoteFile *> *uniqueInfoRemoteFiles = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, OARemoteFile *> *deletedRemoteFiles = [NSMutableDictionary dictionary];;
    NSMutableSet<NSString *> *uniqueFileIds = [NSMutableSet set];
    [remoteFiles enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fileId, OARemoteFile * _Nonnull rf, BOOL * _Nonnull stop) {
        if (![uniqueFileIds containsObject:fileId]) {
            [uniqueFileIds addObject:fileId];
            if (rf.isInfoFile)
                uniqueInfoRemoteFiles[fileId] = rf;
            else if (rf.isDeleted)
                deletedRemoteFiles[fileId] = rf;
            else
                uniqueRemoteFiles[fileId] = rf;
        }
    }];
    _uniqueRemoteFiles = uniqueRemoteFiles;
    _uniqueInfoRemoteFiles = uniqueInfoRemoteFiles;
    _deletedRemoteFiles = deletedRemoteFiles;
    _oldRemoteFiles = oldRemoteFiles;
    _remoteFiles = remoteFilesMap;
}

- (void)setLocalFilesFromArray:(NSArray<OALocalFile *> *)localFiles
{
    NSMutableDictionary<NSString *, OALocalFile *> *localFileMap = [NSMutableDictionary dictionary];
    for (OALocalFile *localFile in localFiles)
        localFileMap[localFile.getTypeFileName] = localFile;
    _localFiles = localFileMap;
}

@end
