//
//  OAWebImagesCacheHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 27/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OADownloadMode;

@interface OAWebImagesCacheHelper : NSObject

- (NSString *) getDbFilename;
- (NSString *) getDbFoldername;

- (void) processWholeHTML:(NSString *)html downloadMode:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow onComplete:(void (^)(NSString *imageData))onComplete;

- (void) fetchSingleImageByURL:(NSString *)url downloadMode:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow onComplete:(void (^)(NSString *imageData))onComplete;

- (void) cleanAllData;
- (double) getFileSize;
- (NSString *) getFormattedFileSize;

@end
