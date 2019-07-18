//
//  OAMapImportHelper.h
//  OsmAnd
//
//  Created by Paul on 17/07/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObservable.h"

@interface OAMapImportHelper : NSObject

@property (nonatomic, readonly) NSString *documentsDir;

+ (OAMapImportHelper *)sharedInstance;

- (BOOL)importFileFromPath:(NSString *)filePath newFileName:(NSString *)newFileName;
- (NSString *)getNewNameIfExists:(NSString *)fileName;

@end
