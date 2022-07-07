//
//  OABackupDbHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 05.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAUploadedFileInfo : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic) long uploadTime;
@property (nonatomic) NSString *md5Digest;

@end

@interface OABackupDbHelper : NSObject

+ (OABackupDbHelper *)sharedDatabase;

- (void) removeUploadedFileInfo:(OAUploadedFileInfo *)info;
- (void) removeUploadedFileInfos;
- (void) updateUploadedFileInfo:(OAUploadedFileInfo *)info;
- (void) addUploadedFileInfo:(OAUploadedFileInfo *)info;
- (NSDictionary<NSString *, OAUploadedFileInfo *> *) getUploadedFileInfoMap;
- (OAUploadedFileInfo *) getUploadedFileInfo:(NSString *)type name:(NSString *)name;
- (void) updateFileUploadTime:(NSString *)type name:(NSString *)name updateTime:(long)updateTime;
- (void) updateFileMd5Digest:(NSString *)type name:(NSString *)name md5Digest:(NSString *)md5Digest;
- (void) setLastModifiedTime:(NSString *)name lastModifiedTime:(long)lastModifiedTime;
- (long) getLastModifiedTime:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
