//
//  OAPrepareBackupResult.h
//  OsmAnd Maps
//
//  Created by Paul on 22.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OABackupInfo, OASettingsItem, OARemoteFile, OALocalFile;

typedef NS_ENUM(NSInteger, EOARemoteFilesType) {
    EOARemoteFilesTypeAll = 0,
    EOARemoteFilesTypeUnique,
    EOARemoteFilesTypeUniqueInfo,
    EOARemoteFilesTypeDeleted,
    EOARemoteFilesTypeOld
};

@interface OAPrepareBackupResult : NSObject

@property (nonatomic, readonly) OABackupInfo *backupInfo;
@property (nonatomic, readonly) NSArray<OASettingsItem *> *settingsItems;

@property (nonatomic) NSDictionary<NSString *, OARemoteFile *> *remoteFiles;

@property (nonatomic) NSDictionary<NSString *, OALocalFile *> *localFiles;
@property (nonatomic) NSString *error;

@end

NS_ASSUME_NONNULL_END
