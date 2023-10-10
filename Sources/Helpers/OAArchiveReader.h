//
//  OAArchiveReader.h
//  OsmAnd
//
//  Created by Max Kojin on 04/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@interface OAArchiveReader : NSObject

- (void) unarchiveFile:(NSString *)archiveFileName destFileName:(NSString *)destFileName dirPath:(NSString *)dirPath;
- (NSString *) getUnarchivedFileContent:(NSString *)archivedContent;
- (NSString *) getUnarchivedFileContentForData:(NSData *)archivedData;

@end
