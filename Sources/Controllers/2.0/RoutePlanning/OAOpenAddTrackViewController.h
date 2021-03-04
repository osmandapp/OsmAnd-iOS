//
//  OAOpenAddTrackViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

typedef NS_ENUM(NSInteger, EOAPlanningTrackScreenType) {
    EOAOpenExistingTrack = 0,
    EOAAddToATrack
};

@protocol OAOpenAddTrackDelegate <NSObject>

- (void) closeBottomSheet;
- (void) onFileSelected:(NSString *)gpxFilePath;

@end

@interface OAOpenAddTrackViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAOpenAddTrackDelegate> delegate;

- (instancetype) initWithScreenType:(EOAPlanningTrackScreenType)screenType;

@end
