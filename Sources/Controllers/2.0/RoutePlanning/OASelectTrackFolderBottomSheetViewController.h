//
//  OASelectTrackFolderBottomSheetViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@protocol OASelectTrackFolderDelegate <NSObject>

- (void) updateSelectedFolder;

@end

@interface OASelectTrackFolderBottomSheetViewController : OABaseTableViewController

- (instancetype) initWithFolderName:(NSString *)fileName filePath:(NSString *)filePath delegate:(id<OASelectTrackFolderDelegate>)delegate;

@end
