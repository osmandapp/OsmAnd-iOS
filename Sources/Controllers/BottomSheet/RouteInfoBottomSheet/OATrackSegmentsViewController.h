//
//  OATrackSegmentsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@class OASGpxFile;

@protocol OASegmentSelectionDelegate <NSObject>

- (void) onSegmentSelected:(NSInteger)position gpx:(OASGpxFile *)gpx;

@end

@interface OATrackSegmentsViewController : OABaseTableViewController

@property (nonatomic, weak) id<OASegmentSelectionDelegate> delegate;
@property (nonatomic, assign) BOOL startNavigationOnSelect;

- (instancetype) initWithFile:(OASGpxFile *)gpx;
- (instancetype) initWithFilepath:(NSString *)filepath isCurrentTrack:(BOOL)isCurrentTrack;

@end
