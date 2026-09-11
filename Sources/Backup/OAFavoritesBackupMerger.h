//
//  OAFavoritesBackupMerger.h
//  OsmAnd Maps
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OABackupHelper, OABackupInfo, OARemoteFile, OASettingsItem;

@interface OAFavoritesBackupMerger : NSObject

+ (void)prepareMergeUploads:(OABackupInfo *)info backupHelper:(OABackupHelper *)backupHelper;
+ (void)onUploadSuccess:(OASettingsItem *)item fileName:(NSString *)fileName uploadTime:(long)uploadTime;
+ (void)onDownloadSuccess:(OASettingsItem *)item remoteFile:(OARemoteFile *)remoteFile;

@end

NS_ASSUME_NONNULL_END
