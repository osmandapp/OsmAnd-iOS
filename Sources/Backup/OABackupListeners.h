//
//  OABackupListeners.h
//  OsmAnd Maps
//
//  Created by Paul on 24.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OARemoteFile, OALocalFile, OABackupError, OABackupInfo;

@protocol OAOnDeleteFilesListener <NSObject>

- (void) onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files;

- (void) onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress;

- (void) onFilesDeleteDone:(NSDictionary<OARemoteFile *, NSString *> *)errors;

- (void) onFilesDeleteError:(NSInteger)status message:(NSString *)message;

@end

@protocol OAOnRegisterUserListener <NSObject>

- (void) onRegisterUser:(NSInteger)status message:(NSString *)message error:(OABackupError *)error;

@end


@protocol OAOnRegisterDeviceListener <NSObject>

- (void) onRegisterDevice:(NSInteger)status message:(NSString *)message error:(OABackupError *)error;

@end

@protocol OnUpdateSubscriptionListener <NSObject>

- (void) onUpdateSubscription:(NSInteger)status message:(NSString *)message error:(NSString *)error;

@end

@protocol OnDownloadFileListListener <NSObject>

- (void) onDownloadFileList:(NSInteger)status message:(NSString *)message remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles;

@end

@protocol OnCollectLocalFilesListener <NSObject>

- (void) onFileCollected:(OALocalFile *)localFile;
    
- (void) onFilesCollected:(NSArray<OALocalFile *> *)localFiles;

@end

@protocol OnGenerateBackupInfoListener <NSObject>

- (void) onBackupInfoGenerated:(OABackupInfo *)backupInfo error:(NSString *)error;

@end

@protocol OnUploadFileListener <NSObject>

- (void) onFileUploadStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work;
    
- (void) onFileUploadProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork;
    
- (void) onFileUploadDone:(NSString *)type fileName:(NSString *)fileName uploadTime:(long)uploadTime error:(NSString *)error;
    
- (BOOL) isUploadCancelled;

@end

@protocol OnDownloadFileListener <NSObject>

- (void) onFileDownloadStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work;
    
- (void) onFileDownloadProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork;
    
- (void) onFileDownloadDone:(NSString *)type fileName:(NSString *)fileName error:(NSString *)error;
    
- (BOOL) isDownloadCancelled;

@end

@interface OABackupListeners : NSObject

- (NSArray<id<OAOnDeleteFilesListener>> *) getDeleteFilesListeners;
- (void) addDeleteFilesListener:(id<OAOnDeleteFilesListener>)listener;
- (void) removeDeleteFilesListener:(id<OAOnDeleteFilesListener>)listener;
- (NSArray<id<OAOnRegisterUserListener>> *) getRegisterUserListeners;
- (void) addRegisterUserListener:(id<OAOnRegisterUserListener>)listener;
- (void) removeRegisterUserListener:(id<OAOnRegisterUserListener>)listener;
- (NSArray<id<OAOnRegisterDeviceListener>> *) getRegisterDeviceListeners;
- (void) addRegisterDeviceListener:(id<OAOnRegisterDeviceListener>)listener;
- (void) removeRegisterDeviceListener:(id<OAOnRegisterDeviceListener>)listener;

@end

NS_ASSUME_NONNULL_END
