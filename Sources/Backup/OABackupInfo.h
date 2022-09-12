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

@property (nonatomic, retain) NSMutableArray<OARemoteFile *> *filesToDownload;
@property (nonatomic, retain) NSMutableArray<OALocalFile *> *filesToUpload;
@property (nonatomic, retain) NSMutableArray<OARemoteFile *> *filesToDelete;
@property (nonatomic, retain) NSMutableArray<OALocalFile *> *localFilesToDelete;
@property (nonatomic, retain) NSMutableArray<NSArray *> *filesToMerge;

@property (nonatomic, retain) NSMutableArray<OASettingsItem *> *itemsToUpload;
@property (nonatomic, retain) NSMutableArray<OASettingsItem *> *itemsToDelete;
@property (nonatomic, retain) NSMutableArray<OALocalFile *> *filteredFilesToUpload;
@property (nonatomic, retain) NSMutableArray<OARemoteFile *> *filteredFilesToDelete;
@property (nonatomic, retain) NSMutableArray<NSArray *> *filteredFilesToMerge;

- (void) createItemCollections;

@end

NS_ASSUME_NONNULL_END
