//
//  OAMapCreatorHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 31/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMapCreatorHelper : NSObject

@property (nonatomic, readonly) NSString *filesDir;
@property (nonatomic, readonly) NSArray *files;

+ (OAMapCreatorHelper *)sharedInstance;

- (BOOL)installFile:(NSString *)filePath;
- (void)removeFile:(NSString *)fileName;
- (NSString *)getNewNameIfExists:(NSString *)fileName;

@end
