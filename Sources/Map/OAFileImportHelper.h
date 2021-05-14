//
//  OAMapImportHelper.h
//  OsmAnd
//
//  Created by Paul on 17/07/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObservable.h"

@interface OAFileImportHelper : NSObject

@property (nonatomic, readonly) NSString *documentsDir;

+ (OAFileImportHelper *)sharedInstance;

- (BOOL)importObfFileFromPath:(NSString *)filePath newFileName:(NSString *)newFileName;
- (NSString *)getNewNameIfExists:(NSString *)fileName;
- (BOOL)importResourceFileFromPath:(NSString *)filePath toPath:(NSString *)destPath;

@end
