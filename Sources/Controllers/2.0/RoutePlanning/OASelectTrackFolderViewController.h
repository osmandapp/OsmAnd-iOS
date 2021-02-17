//
//  OASelectTrackFolderViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import "OAGPXDatabase.h"

@protocol OASelectTrackFolderDelegate <NSObject>

- (void) updateSelectedFolder:(OAGPX *)gpx oldFilePath:(NSString *)oldFilePath newFilePath:(NSString *)newFilePath;

@end

@interface OASelectTrackFolderViewController : OABaseTableViewController

- (instancetype) initWithGPX:(OAGPX *)gpx delegate:(id<OASelectTrackFolderDelegate>)delegate;

@end
