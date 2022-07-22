//
//  OAMapCreatorHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 31/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObservable.h"

@interface OAMapCreatorHelper : NSObject

@property (nonatomic, readonly) NSString *filesDir;
@property (nonatomic, readonly) NSString *documentsDir;
@property (nonatomic, readonly) NSDictionary *files;

@property(readonly) OAObservable *sqlitedbResourcesChangedObservable;

+ (OAMapCreatorHelper *) sharedInstance;

- (BOOL) installFile:(NSString *)filePath newFileName:(NSString *)newFileName;
- (void) removeFile:(NSString *)fileName;
- (NSString *) getNewNameIfExists:(NSString *)fileName;
- (void) renameFile:(NSString *)fileName toName:(NSString *)newName;
- (void) fetchSQLiteDBFiles:(BOOL)notifyChange;

@end
