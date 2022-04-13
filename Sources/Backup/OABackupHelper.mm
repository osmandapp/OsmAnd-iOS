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

@implementation OABackupHelper
{
    NSOperationQueue *_executor;
    
//    private PrepareBackupTask prepareBackupTask;
//        private PrepareBackupResult backup = new PrepareBackupResult();
//        private final List<OnPrepareBackupListener> prepareBackupListeners = new ArrayList<>();
//
    
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
//    InAppPurchaseHelper purchaseHelper = app.getInAppPurchaseHelper();
//    InAppSubscription purchasedSubscription = purchaseHelper.getAnyPurchasedOsmAndProSubscription();
//    return purchasedSubscription != null ? purchasedSubscription.getOrderId() : null;
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
    OAIAPHelper *purchaseHelper = OAIAPHelper.sharedInstance;
    BOOL subscriptionActive = purchaseHelper.subscribedToLiveUpdates;
    
    
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

- (void) downloadFileList:(id<OAOnDownloadFileListListener>)listener
{
    [self checkRegistered];
    
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"deviceid"] = self.getDeviceId;
    params[@"accessToken"] = self.getAccessToken;
    params[@"allVersions"] = @"true";
//    final OperationLog operationLog = new OperationLog("downloadFileList", DEBUG);
//    operationLog.startOperation();
    [OANetworkUtilities sendRequestWithUrl:LIST_FILES_URL params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
                NSString *totalZipSize = resultJson[@"totalZipSize"];
                NSString *totalFiles = resultJson[@"totalFiles"];
                NSString *totalFileVersions = resultJson[@"totalFileVersions"];
                NSArray *allFiles = resultJson[@"allFiles"];
                for (NSDictionary *f in allFiles)
                {
                    [remoteFiles addObject:[[OARemoteFile alloc] initWithJson:f]];
                }
                status = STATUS_SUCCESS;
                message = [NSString stringWithFormat:@"Total files: %@ Total zip size: %@ Total file versions: %@", totalFiles, [NSByteCountFormatter stringFromByteCount:totalZipSize.integerValue countStyle:NSByteCountFormatterCountStyleFile], totalFileVersions];
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
        if (listener)
            [listener onDownloadFileList:status message:message remoteFiles:remoteFiles];
//        operationLog.finishOperation(status + " " + message);
    }];
}

@end
