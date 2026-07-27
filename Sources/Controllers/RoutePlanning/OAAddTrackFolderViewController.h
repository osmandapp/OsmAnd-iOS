//
//  OAAddTrackFolderViewController.h
//  OsmAnd
//
//  Created by nnngrach on 07.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OAAddTrackFolderDelegate <NSObject>

- (void) onTrackFolderAdded:(NSString *)folderName;

@end

@interface OAAddTrackFolderViewController : OABaseNavbarViewController

@property (nonatomic, weak, nullable) id<OAAddTrackFolderDelegate> delegate;

@property (nonatomic, copy, nullable) NSString *suggestedFolderName;

@end

NS_ASSUME_NONNULL_END
