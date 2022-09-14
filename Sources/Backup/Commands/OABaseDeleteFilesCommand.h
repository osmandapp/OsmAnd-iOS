//
//  OABaseDeleteFilesCommand.h
//  OsmAnd Maps
//
//  Created by Paul on 13.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABackupListeners.h"


NS_ASSUME_NONNULL_BEGIN

@interface OABaseDeleteFilesCommand : NSOperation

- (instancetype)initWithVersion:(BOOL)byVersion;
- (instancetype)initWithVersion:(BOOL)byVersion listener:(id<OAOnDeleteFilesListener>)listener;

- (void) onPreExecute;
- (void) doInBackground;
- (void) publishProgress:(id)object;

- (void) setFilesToDelete:(NSArray *)files;
- (void) deleteFiles:(NSArray<OARemoteFile *> *)remoteFiles;
- (NSArray<id<OAOnDeleteFilesListener>> *)getListeners;

@end

NS_ASSUME_NONNULL_END
