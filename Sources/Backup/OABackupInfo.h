//
//  OABackupInfo.h
//  OsmAnd Maps
//
//  Created by Paul on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OARemoteFile, OALocalFile, OASettingsItem;

@interface OABackupInfo : NSObject

@property (nonatomic) NSMutableArray<OARemoteFile *> *filesToDownload;
@property (nonatomic) NSMutableArray<OALocalFile *> *filesToUpload;
@property (nonatomic) NSMutableArray<OARemoteFile *> *filesToDelete;
@property (nonatomic) NSMutableArray<OALocalFile *> *localFilesToDelete;
@property (nonatomic) NSMutableArray<NSArray *> *filesToMerge;

@property (nonatomic) NSMutableArray<OASettingsItem *> *itemsToUpload;
@property (nonatomic) NSMutableArray<OASettingsItem *> *itemsToDelete;
@property (nonatomic) NSMutableArray<OALocalFile *> *filteredFilesToUpload;
@property (nonatomic) NSMutableArray<OARemoteFile *> *filteredFilesToDelete;
@property (nonatomic) NSMutableArray<NSArray *> *filteredFilesToMerge;

@end

NS_ASSUME_NONNULL_END
