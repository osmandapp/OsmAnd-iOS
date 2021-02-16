//
//  OAAddTrackFolderViewController.h
//  OsmAnd
//
//  Created by nnngrach on 07.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@protocol OAAddTrackFolderDelegate <NSObject>

- (void) onTrackFolderAdded:(NSString *)folderName;

@end

@interface OAAddTrackFolderViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAAddTrackFolderDelegate> delegate;

@end

