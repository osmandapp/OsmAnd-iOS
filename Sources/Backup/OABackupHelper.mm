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
#import "OASettingsItemType.h"
#import "OAGpxSettingsItem.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OAIAPHelper.h"
#import "OANetworkUtilities.h"
#import "OABackupError.h"
#import "OABackupDbHelper.h"
#import "OACollectLocalFilesTask.h"
#import "OABackupInfoGenerationTask.h"
#import "OAWebClient.h"

#import "OARegisterUserCommand.h"
#import "OARegisterDeviceCommand.h"

#import <RegexKitLite.h>

#define kUpdateIdOperation @"Update order id"

static NSString *INFO_EXT = @".info";

static NSString *SERVER_URL = @"https://osmand.net";

static NSString *USER_REGISTER_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/user-register"];
static NSString *DEVICE_REGISTER_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/device-register"];
static NSString *UPDATE_ORDER_ID_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/user-update-orderid"];
static NSString *UPLOAD_FILE_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/upload-file"];
static NSString *LIST_FILES_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/list-files"];
static NSString *DOWNLOAD_FILE_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/download-file"];
static NSString *DELETE_FILE_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/delete-file"];
static NSString *DELETE_FILE_VERSION_URL = [SERVER_URL stringByAppendingPathComponent:@"/userdata/delete-file-version"];

static NSString *BACKUP_TYPE_PREFIX = @"backup_type_";
static NSString *VERSION_HISTORY_PREFIX = @"save_version_history_";

@interface OABackupHelper () <OAOnPrepareBackupListener>

@end

@implementation OABackupHelper
{
    
    OAPrepareBackupTask *_prepareBackupTask;
    NSHashTable<id<OAOnPrepareBackupListener>> *_prepareBackupListeners;
    
    OABackupDbHelper *_dbHelper;
    
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
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

+ (BOOL) isTokenValid:(NSString *)token
{
    return [token isMatchedByRegex:@"[0-9]+"];
}

+ (BOOL) applyItem:(OASettingsItem *)item type:(NSString *)type name:(NSString *)name
{
    NSString *itemFileName = [self getItemFileName:item];
    NSString *itemTypeName = [OASettingsItemType typeName:item.type];
    if ([itemTypeName isEqualToString:type])
    {
        if ([name isEqualToString:itemFileName])
        {
            return YES;
        }
        else if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            OAFileSettingsItem *fileItem = (OAFileSettingsItem *) item;
            if ([name hasPrefix:[OAFileSettingsItemFileSubtype getSubtypeFolder:fileItem.subtype]])
            {
                if (fileItem.filePath.pathExtension.length == 0 && ![itemFileName hasSuffix:@"/"])
                {
                    return [name hasPrefix:[itemFileName stringByAppendingString:@"/"]];
                }
                else
                {
                    return [name hasPrefix:itemFileName];
                }
            }
        }
    }
    return false;
}

+ (NSString *) getItemFileName:(OASettingsItem *)item
{
    NSString *fileName;
    if ([item isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *fileItem = (OAFileSettingsItem *) item;
        fileName = [self getFileItemName:fileItem];
    }
    else
    {
        fileName = item.fileName;
        if (fileName.length == 0)
            fileName = item.defaultFileName;
    }
    if (fileName.length > 0 && [fileName characterAtIndex:0] == '/')
    {
        fileName = [fileName substringFromIndex:1];
    }
    return fileName;
}


+ (NSString *) getFileItemName:(OAFileSettingsItem *)fileSettingsItem
{
    return [self getFileItemName:nil fileSettingsItem:fileSettingsItem];
}

+ (NSString *)getFileItemName:(NSString *)filePath fileSettingsItem:(OAFileSettingsItem *)fileSettingsItem
{
    NSString *subtypeFolder = [OAFileSettingsItemFileSubtype getSubtypeFolder:fileSettingsItem.subtype];
    NSString *fileName;
    if (!filePath)
        filePath = fileSettingsItem.filePath;
    if (subtypeFolder.length == 0)
        fileName = filePath.lastPathComponent;
    else
        fileName = filePath.lastPathComponent; // TODO: check correctness!

    if (fileName.length > 0 && [fileName characterAtIndex:0] == '/')
        fileName = [fileName substringFromIndex:1];
    return fileName;
}

+ (BOOL) isLimitedFilesCollectionItem:(OAFileSettingsItem *)item
{
    return item.subtype == EOASettingsItemFileSubtypeVoice;
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
    return UIDevice.currentDevice.identifierForVendor.UUIDString;
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
    [_settings.backupLastUploadedTime set:[NSDate.date timeIntervalSince1970] * 1000 + 1];
}

- (void) logout
{
    [_settings.backupPromocode resetToDefault];
    [_settings.backupDeviceId resetToDefault];
    [_settings.backupAccessToken resetToDefault];
}

- (OACommonBoolean *) getBackupTypePref:(OAExportSettingsType *)type
{
    return [[[OACommonBoolean withKey:[NSString stringWithFormat:@"%@%@", BACKUP_TYPE_PREFIX, type.name] defValue:YES] makeGlobal] makeShared];
}

- (OACommonBoolean *) getVersionHistoryTypePref:(OAExportSettingsType *)type
{
    return [[[OACommonBoolean withKey:[NSString stringWithFormat:@"%@%@", VERSION_HISTORY_PREFIX, type.name] defValue:YES] makeGlobal] makeShared];
}

- (NSArray<NSString *> *) collectItemFilesForUpload:(OAFileSettingsItem *)item
{
    NSMutableArray<NSString *> *filesToUpload = [NSMutableArray array];
    OABackupInfo *info = self.backup.backupInfo;
    if (![self.class isLimitedFilesCollectionItem:item]
        && info != nil && info.filesToUpload.count > 0)
    {
        for (OALocalFile *localFile in info.filesToUpload)
        {
            NSString *filePath = localFile.filePath;
            if ([item isEqual:localFile.item] && filePath != nil)
                [filesToUpload addObject:filePath];
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

- (void) checkSubscriptions:(id<OAOnUpdateSubscriptionListener>)listener
{
    BOOL subscriptionActive = [OAIAPHelper isSubscribedToOsmAndPro];
    
    
//        OperationLog operationLog = new OperationLog("checkSubscriptions", DEBUG);
//        String error = "";
//        try {
//            subscriptionActive = purchaseHelper.checkBackupSubscriptions();
//        } catch (Exception e) {
//            error = e.getMessage();
//        }
//        operationLog.finishOperation(subscriptionActive + " " + error);
    if (subscriptionActive)
    {
        if (listener)
            [listener onUpdateSubscription:STATUS_SUCCESS message:@"Subscriptions have been checked successfully" error:nil];
    }
    else
    {
        [self updateOrderId:listener];
    }
}

- (void) updateOrderId:(id<OAOnUpdateSubscriptionListener>)listener
{
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"email"] = [self getEmail];
    
    NSString *orderId = [self getOrderId];
    if (orderId.length == 0)
    {
        if (listener)
        {
            NSString *message = @"Order id is empty";
            NSString *error = [NSString stringWithFormat:@"{\"error\":{\"errorCode\":%d,\"message\":\"%@\"}}", STATUS_NO_ORDER_ID_ERROR, message];
            [listener onUpdateSubscription:STATUS_NO_ORDER_ID_ERROR message:message error:error];
        }
        return;
    }
    else
    {
        params[@"orderid"] = orderId;
    }
    NSString *iosId = [self getIosId];
    if (iosId.length > 0)
        params[@"deviceid"] = iosId;
//    OperationLog operationLog = new OperationLog("updateOrderId", DEBUG);
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
            [listener onUpdateSubscription:status message:message error:err];
//        operationLog.finishOperation(status + " " + message);
    }];
}

- (void) collectLocalFiles:(id<OAOnCollectLocalFilesListener>)listener
{
//    OperationLog operationLog = new OperationLog("collectLocalFiles", DEBUG);
//    operationLog.startOperation();
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
//    final OperationLog operationLog = new OperationLog("downloadFileList", DEBUG);
//    operationLog.startOperation();
    [OANetworkUtilities sendRequestWithUrl:LIST_FILES_URL params:params post:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
//        operationLog.finishOperation(status + " " + message);
    }];
}

- (NSString *)downloadFile:(NSString *)filePath
                remoteFile:(OARemoteFile *)remoteFile
                  listener:(id<OAOnDownloadFileListener>)listener
{
    [self checkRegistered];
    
//    OperationLog operationLog = new OperationLog("downloadFile " + file.getName(), DEBUG);
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
    NSMutableString *sb = [NSMutableString stringWithString:DOWNLOAD_FILE_URL];
    __block BOOL firstParam = YES;
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [sb appendString:[NSString stringWithFormat:@"%@%@=%@", firstParam ? @"?" : @"&", key, [obj stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]];
        firstParam = NO;
    }];
    
    const auto webClient = std::make_shared<OAWebClient>();
    bool sucseess = webClient->downloadFile(QString::fromNSString(sb), QString::fromNSString(filePath));
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
    //    operationLog.finishOperation();
    return error;
}

- (void) generateBackupInfo:(NSDictionary<NSString *, OALocalFile *> *)localFiles
          uniqueRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)uniqueRemoteFiles
         deletedRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)deletedRemoteFiles
                 onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete
{
    
//    OperationLog operationLog = new OperationLog("generateBackupInfo", DEBUG, 200);
//    operationLog.startOperation();
    
    OABackupInfoGenerationTask *task = [[OABackupInfoGenerationTask alloc] initWithLocalFiles:localFiles uniqueRemoteFiles:uniqueRemoteFiles deletedRemoteFiles:deletedRemoteFiles onComplete:onComplete];
    [_executor addOperation:task];
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
