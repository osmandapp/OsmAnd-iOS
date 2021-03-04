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

- (void) onFolderSelected:(NSString *)selectedFolderName;

@end

@interface OASelectTrackFolderViewController : OABaseTableViewController

@property (nonatomic, weak) id<OASelectTrackFolderDelegate> delegate;

- (instancetype) initWithGPX:(OAGPX *)gpx;
- (instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName;

@end
