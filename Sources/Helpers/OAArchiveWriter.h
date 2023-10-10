//
//  OAArchiveWriter.h
//  OsmAnd
//
//  Created by Max Kojin on 04/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@interface OAArchiveWriter : NSObject

- (void) archiveFile:(NSString *)sourceFileName destPath:(NSString *)archiveFileName dirPath:(NSString *)dirPath;
- (NSData *) getArchivedFileContent:(NSString *)content;

@end
