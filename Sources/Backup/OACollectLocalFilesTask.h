//
//  OAСollectLocalFilesTask.h
//  OsmAnd Maps
//
//  Created by Paul on 07.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABackupListeners.h"

NS_ASSUME_NONNULL_BEGIN

@interface OACollectLocalFilesTask : NSObject

- (instancetype) initWithListener:(id<OAOnCollectLocalFilesListener>)listener;

- (void) execute;

@end

NS_ASSUME_NONNULL_END
