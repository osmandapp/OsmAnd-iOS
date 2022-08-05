//
//  OADeleteFilesCommand.h
//  OsmAnd Maps
//
//  Created by Paul on 13.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseDeleteFilesCommand.h"

NS_ASSUME_NONNULL_BEGIN

@class OARemoteFile;

@interface OADeleteFilesCommand : OABaseDeleteFilesCommand

- (instancetype) initWithVersion:(BOOL)byVersion listener:(id<OAOnDeleteFilesListener>)listener remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles;

@end

NS_ASSUME_NONNULL_END
