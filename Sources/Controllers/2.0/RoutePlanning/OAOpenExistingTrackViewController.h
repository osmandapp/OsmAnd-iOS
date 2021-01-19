//
//  OAOpenExistingTrackViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

typedef NS_ENUM(NSInteger, EOAScreenType) {
    EOAOpenExistingTrack = 0,
    EOAAddToATrack
};

@protocol OAOpenExistingTrackDelegate <NSObject>

- (void) closeBottomSheet;

@end

@interface OAOpenExistingTrackViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAOpenExistingTrackDelegate> delegate;

- (instancetype) initWithScreen:(EOAScreenType)screenType;

@end
