//
//  OADeleteAllFilesCommand.mm
//  OsmAnd Maps
//
//  Created by Skalii on 23.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OADeleteAllFilesCommand.h"
#import "OAOperationLog.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "OARemoteFile.h"
#import "OAExportSettingsType.h"
#import "OANetworkUtilities.h"

@implementation OADeleteAllFilesCommand
{
    OABackupHelper *_backupHelper;
    NSArray<OAExportSettingsType *> *_types;
}

- (instancetype)initWithTypes:(NSArray<OAExportSettingsType *> *)types
{
    self = [super initWithVersion:YES];
    if (self)
    {
        _types = types;
        _backupHelper = [OABackupHelper sharedInstance];
    }
    return self;
}

- (instancetype)initWithTypes:(NSArray<OAExportSettingsType *> *)types listener:(id<OAOnDeleteFilesListener>)listener
{
    self = [super initWithVersion:YES listener:listener];
    if (self)
    {
        _types = types;
        _backupHelper = [OABackupHelper sharedInstance];
    }
    return self;
}

- (void)doInBackground
{
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"deviceid"] = [_backupHelper getDeviceId];
    params[@"accessToken"] = [_backupHelper getAccessToken];
    params[@"allVersions"] = @"true";
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"deleteAllFileList" debug:BACKUP_DEBUG_LOGS];
    [operationLog startOperation];
    [OANetworkUtilities sendRequestWithUrl:OABackupHelper.LIST_FILES_URL params:params post:NO async:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        int status;
        NSString *message;
        NSMutableArray<OARemoteFile *> *remoteFiles = [NSMutableArray array];
        NSString *result = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        if (((NSHTTPURLResponse *) response).statusCode != 200)
        {
            status = STATUS_SERVER_ERROR;
            OABackupError *backupError = [[OABackupError alloc] initWithError:result];
            message = [NSString stringWithFormat:@"Download file list error: %@", backupError.toString];
        }
        else if (result.length > 0)
        {
            NSError *jsonParsingError = nil;
            NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
            if (!jsonParsingError)
            {
                NSArray *allFiles = resultJson[@"allFiles"];
                for (NSDictionary *file in allFiles)
                {
                    [remoteFiles addObject:[[OARemoteFile alloc] initWithJson:file]];
                }
                status = STATUS_SUCCESS;
                message = @"OK";
            }
            else
            {
                message = @"Download file list error: json parsing";
                status = STATUS_PARSE_JSON_ERROR;
            }
        }
        else
        {
            status = STATUS_EMPTY_RESPONSE_ERROR;
            message = @"Download file list error: empty response";
        }

        if (status != STATUS_SUCCESS)
        {
            [self publishProgress:@[@(status), message]];
        }
        else
        {
            NSMutableArray<OARemoteFile *> *filesToDelete = [NSMutableArray array];
            if (_types)
            {
                for (OARemoteFile *file in remoteFiles)
                {
                    OAExportSettingsType *exportType = [OAExportSettingsType findByRemoteFile:file];
                    if ([_types containsObject:exportType])
                        [filesToDelete addObject:file];
                }
            }
            else
            {
                [filesToDelete addObjectsFromArray:remoteFiles];
            }
            [self publishProgress:filesToDelete];
            if (filesToDelete.count > 0)
                [self setFilesToDelete:filesToDelete];
        }
        [operationLog finishOperation:[NSString stringWithFormat:@"%d %@", status, message]];
    }];
}

- (void)publishProgress:(id)object
{
    [super publishProgress:object];

    for (id<OAOnDeleteFilesListener> listener in [self getListeners])
    {
        if ([object isKindOfClass:NSArray.class])
        {
            NSArray *files = (NSArray *) object;
            if (files.count == 0)
            {
                [listener onFilesDeleteDone:@{}];
            }
            else if (files.count == 2 && [files.firstObject isKindOfClass:NSNumber.class] && [files.lastObject isKindOfClass:NSString.class])
            {
                int status = [files.firstObject intValue];
                NSString *message = (NSString *) files.lastObject;
                [listener onFilesDeleteError:status message:message];
            }
            else
            {
                [listener onFilesDeleteStarted:object];
            }
        }
    }
}

@end
