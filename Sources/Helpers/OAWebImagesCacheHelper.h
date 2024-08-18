//
//  OAWebImagesCacheHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 27/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OADownloadMode;

@interface OAWebImagesCacheHelper : NSObject

- (NSString *) getDbFilename;
- (NSString *) getDbFoldername;

- (void) processWholeHTML:(NSString *)html downloadMode:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow onComplete:(void (^)(NSString *htmlWithImages))onComplete;

- (void) fetchSingleImageByURL:(NSString *)url customKey:(NSString *)customKey downloadMode:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow onComplete:(void (^)(NSString *imageData))onComplete;

- (NSString *) getDbKeyByLink:(NSString *)url;
- (NSString *) readImageByDbKey:(NSString *)key;
- (void) cleanAllData;
- (double) getFileSize;
- (NSString *) getFormattedFileSize;

@end
