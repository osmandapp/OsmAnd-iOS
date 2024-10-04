//
//  OAUploadGPXFilesTask.h
//  OsmAnd
//
//  Created by nnngrach on 06.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAOsmEditingViewController.h"
#import "OAGPXDatabase.h"
#import "OABackupListeners.h"

@class OAOsmEditingPlugin;

@interface OAUploadGPXFilesTask : NSObject

- (instancetype) initWithPlugin:(OAOsmEditingPlugin *)plugin gpxItemsToUpload:(NSArray<OASGpxDataItem *> *)gpxItemsToUpload tags:(NSString *)tags visibility:(NSString *)visibility description:(NSString *)description listener:(id<OAOnUploadFileListener>)listener;

- (void) uploadTracks;

- (void) setInterrupted:(BOOL)interrupted;

@end
