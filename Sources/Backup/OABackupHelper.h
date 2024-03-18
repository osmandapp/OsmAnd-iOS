//
//  OABackupHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABackupListeners.h"
#import "OAPrepareBackupTask.h"

#define BACKUP_DEBUG_LOGS YES

#define STATUS_SUCCESS 0
#define STATUS_PARSE_JSON_ERROR 1
#define STATUS_EMPTY_RESPONSE_ERROR 2
#define STATUS_SERVER_ERROR 3
#define STATUS_NO_ORDER_ID_ERROR 4
#define STATUS_EXECUTION_ERROR 5
#define STATUS_SERVER_TEMPORALLY_UNAVAILABLE_ERROR 6

#define SERVER_ERROR_CODE_EMAIL_IS_INVALID 101
#define SERVER_ERROR_CODE_NO_VALID_SUBSCRIPTION 102
#define SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED 103
#define SERVER_ERROR_CODE_TOKEN_IS_NOT_VALID_OR_EXPIRED 104
#define SERVER_ERROR_CODE_PROVIDED_TOKEN_IS_NOT_VALID 105
#define SERVER_ERROR_CODE_FILE_NOT_AVAILABLE 106
#define SERVER_ERROR_CODE_GZIP_ONLY_SUPPORTED_UPLOAD 107
#define SERVER_ERROR_CODE_SIZE_OF_SUPPORTED_BOX_IS_EXCEEDED 108
#define SERVER_ERROR_CODE_SUBSCRIPTION_WAS_USED_FOR_ANOTHER_ACCOUNT 109
#define SERVER_ERROR_CODE_SUBSCRIPTION_WAS_EXPIRED_OR_NOT_PRESENT 110
#define SERVER_ERROR_CODE_USER_IS_ALREADY_REGISTERED 111


static inline BOOL backupDebugLogs()
{
    return BACKUP_DEBUG_LOGS;
}

@class OAExportSettingsType, OACommonBoolean, OAPrepareBackupResult, OABackupListeners, OASettingsItem, OAFileSettingsItem;

@interface OABackupHelper : NSObject

@property (nonatomic) OAPrepareBackupResult *backup;
@property (nonatomic, readonly) OABackupListeners *backupListeners;

@property (nonatomic, readonly) NSOperationQueue *executor;

+ (NSString *) INFO_EXT;

+ (NSString *) USER_REGISTER_URL;
+ (NSString *) DEVICE_REGISTER_URL;
+ (NSString *) LIST_FILES_URL;
+ (NSString *) DELETE_FILE_VERSION_URL;
+ (NSString *) DELETE_FILE_URL;
+ (NSString *) ACCOUNT_DELETE_URL;
+ (NSString *) SEND_CODE_URL;
+ (NSString *) CHECK_CODE_URL;

+ (OABackupHelper *)sharedInstance;

+ (NSString *) getItemFileName:(OASettingsItem *)item;
+ (NSString *) getFileItemName:(OAFileSettingsItem *)fileSettingsItem;
+ (NSString *)getFileItemName:(NSString *)filePath fileSettingsItem:(OAFileSettingsItem *)fileSettingsItem;

+ (void) setLastModifiedTime:(NSString *)name;
+ (void) setLastModifiedTime:(NSString *)name lastModifiedTime:(long)lastModifiedTime;
+ (long) getLastModifiedTime:(NSString *)name;

- (OACommonBoolean *) getBackupTypePref:(OAExportSettingsType *)type;
- (OACommonBoolean *) getVersionHistoryTypePref:(OAExportSettingsType *)type;

- (NSString *) getOrderId;
- (NSString *) getIosId;
- (NSString *) getDeviceId;
- (NSString *) getAccessToken;
- (NSString *) getEmail;
- (BOOL) isRegistered;
- (NSInteger)getMaximumAccountSize;

- (void) logout;
- (void) updateOrderId:(void(^)(NSInteger status, NSString *message, NSString *error))listener;
- (void) checkSubscriptions:(void(^)(NSInteger status, NSString *message, NSString *error))listener;

- (void) registerUser:(NSString *)email promoCode:(NSString *)promoCode login:(BOOL)login;
- (void) registerDevice:(NSString *)token;

- (NSArray<NSString *> *) collectItemFilesForUpload:(OAFileSettingsItem *)item;
- (void) collectLocalFiles:(id<OAOnCollectLocalFilesListener>)listener;
- (void) downloadFileList:(void(^)(NSInteger status, NSString *message, NSArray<OARemoteFile *> *remoteFiles))onComplete;
- (void) deleteAllFiles:(NSArray<OAExportSettingsType *> *)types;
- (void) deleteAllFiles:(NSArray<OAExportSettingsType *> *)types listener:(id<OAOnDeleteFilesListener>)listener;
- (void) deleteOldFiles:(NSArray<OAExportSettingsType *> *)types;
- (void) deleteOldFiles:(NSArray<OAExportSettingsType *> *)types listener:(id<OAOnDeleteFilesListener>)listener;
- (void) deleteAccount:(NSString *)email token:(NSString *)token;
- (void) checkCode:(NSString *)email token:(NSString *)token;
- (void) sendCode:(NSString *)email action:(NSString *)action;
- (NSString *)downloadFile:(NSString *)filePath
                remoteFile:(OARemoteFile *)remoteFile
                  listener:(id<OAOnDownloadFileListener>)listener;
- (void) generateBackupInfo:(NSDictionary<NSString *, OALocalFile *> *)localFiles
          uniqueRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)uniqueRemoteFiles
         deletedRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)deletedRemoteFiles
                 onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete;

- (NSString *) uploadFile:(NSString *)fileName
                     type:(NSString *)type
                     data:(NSData *)data
                     size:(int)size
         lastModifiedTime:(long)lastModifiedTime
                 listener:(id<OAOnUploadFileListener>)listener;

- (void) updateFileUploadTime:(NSString *)type fileName:(NSString *)fileName uploadTime:(long)updateTime;
- (void) updateFileMd5Digest:(NSString *)type fileName:(NSString *)fileName md5Hex:(NSString *)md5Hex;
- (void) updateBackupUploadTime;

- (void) deleteFilesSync:(NSArray<OARemoteFile *> *)remoteFiles byVersion:(BOOL)byVersion listener:(id<OAOnDeleteFilesListener>)listener;

- (BOOL) prepareBackup;
- (void) addPrepareBackupListener:(id<OAOnPrepareBackupListener>)listener;
- (void) removePrepareBackupListener:(id<OAOnPrepareBackupListener>)listener;

- (BOOL) isBackupPreparing;
- (NSDictionary<NSString *, OALocalFile *> *)getPreparedLocalFiles;

- (BOOL) isObfMapExistsOnServer:(NSString *)name;

- (NSInteger) calculateFileSize:(OARemoteFile *)remoteFile;

+ (BOOL) isTokenValid:(NSString *)token;

+ (BOOL) applyItem:(OASettingsItem *)item type:(NSString *)type name:(NSString *)name;
+ (NSArray<OASettingsItem *> *) getItemsForRestore:(OABackupInfo *)info settingsItems:(NSArray<OASettingsItem *> *)settingsItems;
+ (NSDictionary<OARemoteFile *, OASettingsItem *> *) getItemsMapForRestore:(OABackupInfo *)info settingsItems:(NSArray<OASettingsItem *> *)settingsItems;
+ (NSDictionary<OARemoteFile *, OASettingsItem *> *) getRemoteFilesSettingsItems:(NSArray<OASettingsItem *> *)items
                                                                     remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles
                                                                       infoFiles:(BOOL)infoFiles;

@end
