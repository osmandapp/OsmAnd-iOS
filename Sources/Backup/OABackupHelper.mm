//
//  OABackupHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupHelper.h"
#import "OsmAndApp.h"
#import "OAExportSettingsType.h"
#import "OASettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OANetworkUtilities.h"
#import "OABackupError.h"
#import "OABackupDbHelper.h"
#import "OACollectLocalFilesTask.h"
#import "OABackupInfoGenerationTask.h"
#import "OACollectionSettingsItem.h"
#import "OADeleteFilesCommand.h"
#import "OAWebClient.h"
#import "OAOperationLog.h"
#import "OAURLSessionProgress.h"
#import "OADeleteAllFilesCommand.h"
#import "OADeleteOldFilesCommand.h"
#import "OARegisterUserCommand.h"
#import "OARegisterDeviceCommand.h"
#import "OABackupListeners.h"
#import "OAPrepareBackupTask.h"
#import "OAURLSessionProgress.h"
#import "OsmAnd_Maps-Swift.h"

#define kUpdateIdOperation @"Update order id"

static NSString *INFO_EXT = @"info";

static NSString *SERVER_URL = @"https://osmand.net";

static NSString *USER_REGISTER_URL = [SERVER_URL stringByAppendingString:@"/userdata/user-register"];
static NSString *DEVICE_REGISTER_URL = [SERVER_URL stringByAppendingString:@"/userdata/device-register"];
static NSString *UPDATE_ORDER_ID_URL = [SERVER_URL stringByAppendingString:@"/userdata/user-update-orderid"];
static NSString *UPLOAD_FILE_URL = [SERVER_URL stringByAppendingString:@"/userdata/upload-file"];
static NSString *LIST_FILES_URL = [SERVER_URL stringByAppendingString:@"/userdata/list-files"];
static NSString *DOWNLOAD_FILE_URL = [SERVER_URL stringByAppendingString:@"/userdata/download-file"];
static NSString *DELETE_FILE_URL = [SERVER_URL stringByAppendingString:@"/userdata/delete-file"];
static NSString *DELETE_FILE_VERSION_URL = [SERVER_URL stringByAppendingString:@"/userdata/delete-file-version"];
static NSString *ACCOUNT_DELETE_URL = [SERVER_URL stringByAppendingString:@"/userdata/delete-account"];
static NSString *SEND_CODE_URL = [SERVER_URL stringByAppendingString:@"/userdata/send-code"];
static NSString *CHECK_CODE_URL = [SERVER_URL stringByAppendingString:@"/userdata/auth/confirm-code"];

@interface OABackupHelper () <OAOnPrepareBackupListener, NSURLSessionDelegate>

@end

@implementation OABackupHelper
{
    OAPrepareBackupTask *_prepareBackupTask;
    NSHashTable<id<OAOnPrepareBackupListener>> *_prepareBackupListeners;
    
    OABackupDbHelper *_dbHelper;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    NSInteger _maximumAccountSize;
}

+ (NSString *) INFO_EXT
{
    return INFO_EXT;
}

+ (NSString *) USER_REGISTER_URL
{
    return USER_REGISTER_URL;
}

+ (NSString *) DEVICE_REGISTER_URL
{
    return DEVICE_REGISTER_URL;
}

+ (NSString *) LIST_FILES_URL
{
    return LIST_FILES_URL;
}

+ (NSString *) DELETE_FILE_VERSION_URL
{
    return DELETE_FILE_VERSION_URL;
}

+ (NSString *) DELETE_FILE_URL
{
    return DELETE_FILE_URL;
}

+ (NSString *) ACCOUNT_DELETE_URL
{
    return ACCOUNT_DELETE_URL;
}

+ (NSString *) SEND_CODE_URL
{
    return SEND_CODE_URL;
}

+ (NSString *) CHECK_CODE_URL
{
    return CHECK_CODE_URL;
}

+ (OASettingsItem *) getRestoreItem:(NSArray<OASettingsItem *> *)items remoteFile:(OARemoteFile *)remoteFile
{
    for (OASettingsItem *item in items)
    {
        if ([BackupUtils applyItem:item type:remoteFile.type name:remoteFile.name])
            return item;
    }
    return nil;
}

+ (OABackupHelper *)sharedInstance
{
    static OABackupHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OABackupHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _executor = [[NSOperationQueue alloc] init];
        _settings = [OAAppSettings sharedManager];
        _backupListeners = [[OABackupListeners alloc] init];
        _dbHelper = OABackupDbHelper.sharedDatabase;
        _prepareBackupListeners = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (BOOL) isBusy
{
    return !_executor.isSuspended;
}

- (NSString *) getIosId
{
    return _app.getUserIosId;
}

- (NSString *) getDeviceId
{
    return [_settings.backupDeviceId get];
}

- (NSString *) getOrderId
{
    OAIAPHelper *iapHelper = OAIAPHelper.sharedInstance;
    OASubscription *purchasedSubscription = iapHelper.getAnyPurchasedOsmAndProSubscription;
    if (purchasedSubscription)
    {
        NSLog(@"Found purchased subscription: %@", [purchasedSubscription getOrderId]);
        return [purchasedSubscription getOrderId];
    }
    return nil;
}

- (NSString *) getAccessToken
{
    return [_settings.backupAccessToken get];
}

- (NSString *) getEmail
{
    return [_settings.backupUserEmail get];
}

- (BOOL) isRegistered
{
    return [self getDeviceId].length > 0 && [self getAccessToken].length > 0;
}

- (NSInteger)getMaximumAccountSize
{
    return _maximumAccountSize;
}

- (void) checkRegistered
{
    if (self.getDeviceId.length == 0 || self.getAccessToken.length == 0)
        throw [NSException exceptionWithName:@"UserNotRegisteredException" reason:@"User is not registered" userInfo:nil];
}

- (void) updateFileUploadTime:(NSString *)type fileName:(NSString *)fileName uploadTime:(long)updateTime
{
    [_dbHelper updateFileUploadTime:type name:fileName updateTime:updateTime];
}

- (void) updateFileMd5Digest:(NSString *)type fileName:(NSString *)fileName md5Hex:(NSString *)md5Hex
{
    [_dbHelper updateFileMd5Digest:type name:fileName md5Digest:md5Hex];
}

- (void) updateBackupUploadTime
{
    [_settings.backupLastUploadedTime set:[NSDate.date timeIntervalSince1970]];
}

- (void) logout
{
    [_settings.backupPromocode resetToDefault];
    [_settings.backupDeviceId resetToDefault];
    [_settings.backupAccessToken resetToDefault];
}

- (NSArray<NSString *> *) collectItemFilesForUpload:(OAFileSettingsItem *)item
{
    NSMutableArray<NSString *> *filesToUpload = [NSMutableArray array];
    OABackupInfo *info = self.backup.backupInfo;
    if (![BackupUtils isLimitedFilesCollectionItem:item]
        && info != nil && (info.filesToUpload.count > 0 || info.filesToMerge.count > 0 || info.filesToDownload.count > 0))
    {
        for (OALocalFile *localFile in info.filesToUpload)
        {
            NSString *filePath = localFile.filePath;
            if ([item isEqual:localFile.item] && filePath != nil)
                [filesToUpload addObject:filePath];
        }
        for (NSArray *arr in info.filesToMerge)
        {
            OALocalFile *localFile = arr.firstObject;
            NSString *filePath = localFile.filePath;
            if ([item isEqual:localFile.item] && filePath != nil)
                [filesToUpload addObject:filePath];
        }
        for (OARemoteFile *remoteFile in info.filesToDownload)
        {
            if ([remoteFile.item isKindOfClass:OAFileSettingsItem.class])
            {
                NSString *fileName = remoteFile.item.fileName;
                if (fileName != nil && [item applyFileName:fileName])
                {
                    [filesToUpload addObject:((OAFileSettingsItem *) remoteFile.item).filePath];
                }
            }
        }
    }
    else
    {
        [OAUtilities collectDirFiles:item.filePath list:filesToUpload];
    }
    return filesToUpload;
}

- (void) registerUser:(NSString *)email promoCode:(NSString *)promoCode login:(BOOL)login
{
    [_executor addOperation:[[OARegisterUserCommand alloc] initWithEmail:email promoCode:promoCode login:login]];
}

- (void) registerDevice:(NSString *)token
{
    [_executor addOperation:[[OARegisterDeviceCommand alloc] initWithToken:token]];
}

- (void) checkSubscriptions:(void(^)(NSInteger status, NSString *message, NSString *error))listener
{
    BOOL subscriptionActive = NO;
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"checkSubscriptions" debug:BACKUP_DEBUG_LOGS];
    NSString *error = @"";
    try
    {
        subscriptionActive = [OAIAPHelper.sharedInstance checkBackupSubscriptions];;
    }
    catch (NSException *e)
    {
        error = e.reason;
    }
    [operationLog finishOperation:[NSString stringWithFormat:@"%@ %@", subscriptionActive ? @"true" : @"false", error]];
    if (subscriptionActive)
    {
        if (listener)
            listener(STATUS_SUCCESS, @"Subscriptions have been checked successfully", nil);
    }
    else
    {
        [self updateOrderId:listener];
    }
}

- (void) updateOrderId:(void(^)(NSInteger status, NSString *message, NSString *error))listener
{
    NSString *orderId = [self getOrderId];
    if (orderId.length == 0)
    {
        return;
    }
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"email"] = [self getEmail];
    params[@"orderid"] = orderId;
    NSString *iosId = [self getIosId];
    if (iosId.length > 0)
        params[@"deviceid"] = iosId;
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"updateOrderId" debug:BACKUP_DEBUG_LOGS];
    [OANetworkUtilities sendRequestWithUrl:UPDATE_ORDER_ID_URL params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        int status;
        NSString *message;
        NSString *err;
        NSString *result = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        if (((NSHTTPURLResponse *)response).statusCode != 200)
        {
            OABackupError *backupError = [[OABackupError alloc] initWithError:result];
            message = [NSString stringWithFormat:@"Update order id error: %@", backupError.toString];
            status = STATUS_SERVER_ERROR;
        }
        else if (result.length > 0)
        {
            NSError *jsonParsingError = nil;
            NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
            if (!jsonParsingError)
            {
                if (resultJson[@"status"] && [@"ok" isEqualToString:resultJson[@"status"]])
                {
                    message = @"Order id have been updated successfully";
                    status = STATUS_SUCCESS;
                }
                else
                {
                    message = @"Update order id error: unknown";
                    status = STATUS_SERVER_ERROR;
                }
            }
            else
            {
                message = @"Update order id error: json parsing";
                status = STATUS_PARSE_JSON_ERROR;
            }
            
        }
        else
        {
            message = @"Update order id error: empty response";
            status = STATUS_EMPTY_RESPONSE_ERROR;
        }
        if (listener)
            listener(status, message, err);
        [operationLog finishOperation:[NSString stringWithFormat:@"%d %@", status, message]];
    }];
}

- (void) collectLocalFiles:(id<OAOnCollectLocalFilesListener>)listener
{
    OACollectLocalFilesTask *task = [[OACollectLocalFilesTask alloc] initWithListener:listener];
    [task execute];
}

- (void) downloadFileList:(void(^)(NSInteger status, NSString *message, NSArray<OARemoteFile *> *remoteFiles))onComplete
{
    [self checkRegistered];
    
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"deviceid"] = self.getDeviceId;
    params[@"accessToken"] = self.getAccessToken;
    params[@"allVersions"] = @"true";
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"downloadFileList" debug:BACKUP_DEBUG_LOGS];
    [operationLog startOperation];
    [OANetworkUtilities sendRequestWithUrl:LIST_FILES_URL params:params post:NO async:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        int status;
        NSString *message;
        NSString *result = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        NSMutableArray<OARemoteFile *> *remoteFiles = [NSMutableArray array];
        if (((NSHTTPURLResponse *)response).statusCode != 200)
        {
            OABackupError *backupError = [[OABackupError alloc] initWithError:result];
            message = [NSString stringWithFormat:@"Download file list error: %@", backupError.toString];
            status = STATUS_SERVER_ERROR;
        }
        else if (result.length > 0)
        {
            NSError *jsonParsingError = nil;
            NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
            if (!jsonParsingError)
            {
                NSInteger totalZipSize = [resultJson[@"totalZipSize"] integerValue];
                NSInteger totalFiles = [resultJson[@"totalFiles"] integerValue];
                NSInteger totalFileVersions = [resultJson[@"totalFileVersions"] integerValue];
                _maximumAccountSize = [resultJson[@"maximumAccountSize"] integerValue];
                NSArray *allFiles = resultJson[@"allFiles"];
                for (NSDictionary *f in allFiles)
                {
                    [remoteFiles addObject:[[OARemoteFile alloc] initWithJson:f]];
                }
                status = STATUS_SUCCESS;
                message = [NSString stringWithFormat:@"Total files: %ld Total zip size: %@ Total file versions: %ld", totalFiles, [NSByteCountFormatter stringFromByteCount:totalZipSize countStyle:NSByteCountFormatterCountStyleFile], totalFileVersions];
            }
            else
            {
                message = @"Download file list error: json parsing";
                status = STATUS_PARSE_JSON_ERROR;
            }
            
        }
        else
        {
            message = @"Download file list error: empty response";
            status = STATUS_EMPTY_RESPONSE_ERROR;
        }
        if (onComplete)
            onComplete(status, message, remoteFiles);
        [operationLog finishOperation:[NSString stringWithFormat:@"%d %@", status, message]];
    }];
}

- (void)deleteAllFiles:(NSArray<OAExportSettingsType *> *)types
{
    [self checkRegistered];
    [_executor addOperation:[[OADeleteAllFilesCommand alloc] initWithTypes:types]];
}

- (void)deleteAllFiles:(NSArray<OAExportSettingsType *> *)types listener:(id<OAOnDeleteFilesListener>)listener
{
    [self checkRegistered];
    [_executor addOperation:[[OADeleteAllFilesCommand alloc] initWithTypes:types listener:listener]];
}

- (void)deleteOldFiles:(NSArray<OAExportSettingsType *> *)types
{
    [self checkRegistered];
    [_executor addOperation:[[OADeleteOldFilesCommand alloc] initWithTypes:types]];
}

- (void)deleteOldFiles:(NSArray<OAExportSettingsType *> *)types listener:(id<OAOnDeleteFilesListener>)listener
{
    [self checkRegistered];
    [_executor addOperation:[[OADeleteOldFilesCommand alloc] initWithTypes:types listener:listener]];
}

- (void)deleteAccount:(NSString *)email token:(NSString *)token
{
    [self checkRegistered];
    [_executor addOperation:[[OADeleteAccountCommand alloc] initWith:email token:token]];
}

- (void)checkCode:(NSString *)email token:(NSString *)token
{
    [self checkRegistered];
    [_executor addOperation:[[OACheckCodeCommand alloc] initWith:email token:token]];
}

- (void)sendCode:(NSString *)email action:(NSString *)action
{
    [self checkRegistered];
    [_executor addOperation:[[OASendCodeCommand alloc] initWith:email action:action]];
}

- (NSInteger)calculateFileSize:(OARemoteFile *)remoteFile
{
    NSInteger sz = remoteFile.filesize / 1024;
    if (remoteFile.item.type == EOASettingsItemTypeFile)
    {
        OAFileSettingsItem *flItem = (OAFileSettingsItem *) remoteFile.item;
        if (flItem.subtype == EOASettingsItemFileSubtypeObfMap)
        {
            NSString *mapId = flItem.fileName.lowerCase;
            const auto res = _app.resourcesManager->getResourceInRepository(QString::fromNSString(mapId));
            if (res)
            {
                sz = res->size / 1024;
            }
        }
    }
    return sz;
}

- (NSString *)downloadFile:(NSString *)filePath
                remoteFile:(OARemoteFile *)remoteFile
                  listener:(id<OAOnDownloadFileListener>)listener
{
    [self checkRegistered];
    
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"downloadFile" debug:BACKUP_DEBUG_LOGS];
    NSString *error;
    NSString *type = remoteFile.type;
    NSString *fileName = remoteFile.name;
    
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    NSString *deviceId = [self getDeviceId];
    if (deviceId)
        params[@"deviceid"] = deviceId;
    params[@"accessToken"] = [self getAccessToken];
    params[@"name"] = fileName;
    params[@"type"] = type;
    params[@"updatetime"] = @(remoteFile.updatetimems).stringValue;
    NSMutableString *builder = [NSMutableString stringWithString:DOWNLOAD_FILE_URL];
    __block BOOL firstParam = YES;
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [builder appendString:[NSString stringWithFormat:@"%@%@=%@", firstParam ? @"?" : @"&", key, [obj stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]];
        firstParam = NO;
    }];
    
    OAURLSessionProgress *progress = [[OAURLSessionProgress alloc] init];
    NSInteger sz = [self calculateFileSize:remoteFile];
    __block int64_t work = 0;
    [progress setOnProgress:^(int progress, int64_t deltaWork) {
        work += deltaWork;
        int prog = ((double)work / (double)sz) * 100;
        [listener onFileDownloadProgress:type fileName:fileName progress:prog deltaWork:deltaWork itemFileName:nil];
    }];
    
    bool sucseess = [OANetworkUtilities downloadFile:filePath url:builder progress:progress];
    if (!sucseess)
        error = [NSString stringWithFormat:@"Could not download remote file:%@", fileName];
    
//    IProgress progress = new AbstractProgress() {
//
//        private int work = 0;
//        private int progress = 0;
//        private int deltaProgress = 0;
//
//        @Override
//        public void startWork(int work) {
//            if (listener != null) {
//                this.work = work > 0 ? work : 1;
//                listener.onFileDownloadStarted(type, fileName, work);
//            }
//        }
//
//        @Override
//        public void progress(int deltaWork) {
//            if (listener != null) {
//                deltaProgress += deltaWork;
//                if ((deltaProgress > (work / 100)) || ((progress + deltaProgress) >= work)) {
//                    progress += deltaProgress;
//                    listener.onFileDownloadProgress(type, fileName, progress, deltaProgress);
//                    deltaProgress = 0;
//                }
//            }
//        }
//
//        @Override
//        public boolean isInterrupted() {
//            if (listener != null) {
//                return listener.isDownloadCancelled();
//            }
//            return super.isInterrupted();
//        }
//    };
//    progress.startWork((int) (remoteFile.getFilesize() / 1024));
    
    if (listener)
        [listener onFileDownloadDone:type fileName:fileName error:error];
    [operationLog finishOperation];
    return error;
}

- (void) generateBackupInfo:(NSDictionary<NSString *, OALocalFile *> *)localFiles
          uniqueRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)uniqueRemoteFiles
         deletedRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)deletedRemoteFiles
                 onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete
{
    OABackupInfoGenerationTask *task = [[OABackupInfoGenerationTask alloc] initWithLocalFiles:localFiles uniqueRemoteFiles:uniqueRemoteFiles deletedRemoteFiles:deletedRemoteFiles onComplete:onComplete];
    [_executor addOperation:task];
}

- (NSDictionary<NSString *, OALocalFile *> *)getPreparedLocalFiles
{
    if (self.isBackupPreparing)
        return _prepareBackupTask.backup.localFiles;
    return nil;
}

- (BOOL) isBackupPreparing
{
    return _prepareBackupTask != nil;
}

- (void) addPrepareBackupListener:(id<OAOnPrepareBackupListener>)listener
{
    [_prepareBackupListeners addObject:listener];
    if ([self isBackupPreparing])
        [listener onBackupPreparing];
}

- (void) removePrepareBackupListener:(id<OAOnPrepareBackupListener>)listener
{
    [_prepareBackupListeners removeObject:listener];
}

- (BOOL) prepareBackup
{
    if ([self isBackupPreparing])
        return NO;

    OAPrepareBackupTask *prepareBackupTask = [[OAPrepareBackupTask alloc] initWithListener:self];
    
    _prepareBackupTask = prepareBackupTask;
    [prepareBackupTask prepare];
    return YES;
}

- (NSString *) uploadFile:(NSString *)fileName
                     type:(NSString *)type
                     data:(NSData *)data
                     size:(int)size
         lastModifiedTime:(long)lastModifiedTime
                 listener:(id<OAOnUploadFileListener>)listener
{
    [self checkRegistered];
    
    OAURLSessionProgress *progress = nil;
    BOOL hasSize = size != -1;
    if (!hasSize)
    {
        progress = [[OAURLSessionProgress alloc] init];
        [progress setOnProgress:^(int progress, int64_t deltaWork) {
            [listener onFileUploadProgress:type fileName:fileName progress:progress deltaWork:deltaWork];
        }];
    }
    
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"deviceid"] = [self getDeviceId];
    params[@"accessToken"] = [self getAccessToken];
    params[@"name"] = fileName;
    params[@"type"] = type;
    params[@"clienttime"] = [NSString stringWithFormat:@"%ld", lastModifiedTime];
    
    NSMutableDictionary<NSString *, NSString *> *headers = [NSMutableDictionary dictionary];
    headers[@"Accept-Encoding"] = @"deflate, gzip";
    
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"uploadFile" debug:BACKUP_DEBUG_LOGS];
    [operationLog startOperation:[NSString stringWithFormat:@"%@ %@", type, fileName]];
    __block NSData *resp = nil;
    __block NSString *error = nil;
    [listener onFileUploadStarted:type fileName:fileName work:hasSize ? size : data.length];
    [OANetworkUtilities uploadFile:UPLOAD_FILE_URL fileName:fileName params:params headers:headers data:data gzip:YES autorizationHeader:nil progress:progress onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
        if (((NSHTTPURLResponse *)response).statusCode != 200)
            error = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        else
            resp = data;
        if (hasSize)
            [listener onFileUploadProgress:type fileName:fileName progress:100 deltaWork:size];
    }];
    long uploadTime = 0;
    NSString *status = @"";
    if (resp.length > 0)
    {
        NSError *jsonParsingError = nil;
        NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:resp options:NSJSONReadingMutableContainers error:&jsonParsingError];
        if (!jsonParsingError)
        {
            status = resultJson[@"status"];
            uploadTime = [resultJson[@"updatetime"] longValue];
        }
        else
        {
            NSLog(@"Cannot obtain updatetime after upload. Server response: %@", [[NSString alloc] initWithData:resp encoding:NSUTF8StringEncoding]);
        }
    }
    if (error == nil && [status isEqualToString:@"ok"])
    {
        [self updateFileUploadTime:type fileName:fileName uploadTime:uploadTime];
    }
    if (listener != nil)
    {
        [listener onFileUploadDone:type fileName:fileName uploadTime:uploadTime error:error];
    }
    [operationLog finishOperation:[NSString stringWithFormat:@"%@ %@ %@", type, fileName, (error ? [NSString stringWithFormat:@"Error: %@", [[OABackupError alloc] initWithError:error].getLocalizedError] : @"OK")]];
    return error;
}

- (void) deleteFilesSync:(NSArray<OARemoteFile *> *)remoteFiles byVersion:(BOOL)byVersion listener:(id<OAOnDeleteFilesListener>)listener
{
    [self checkRegistered];
    @try
    {
        OADeleteFilesCommand *command = [[OADeleteFilesCommand alloc] initWithVersion:byVersion listener:listener remoteFiles:remoteFiles];
        NSOperationQueue *executor = [[NSOperationQueue alloc] init];
        [executor addOperations:@[command] waitUntilFinished:YES];
    }
    @catch (NSException *e)
    {
        if (listener != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [listener onFilesDeleteError:STATUS_EXECUTION_ERROR message:@"Execution error while deleting files"];
            });
        }
    }
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPreparing
{
    for (id<OAOnPrepareBackupListener> listener in _prepareBackupListeners)
        [listener onBackupPreparing];
}

- (void)onBackupPrepared:(OAPrepareBackupResult *)backupResult
{
    _prepareBackupTask = nil;
    for (id<OAOnPrepareBackupListener> listener in _prepareBackupListeners)
        [listener onBackupPrepared:backupResult];
}

@end
