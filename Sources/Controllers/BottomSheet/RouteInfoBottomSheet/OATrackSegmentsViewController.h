//
//  OATrackSegmentsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"

@class OAGPXDocument;

@protocol OASegmentSelectionDelegate <NSObject>

- (void) onSegmentSelected:(NSInteger)position gpx:(OAGPXDocument *)gpx;

@end

@interface OATrackSegmentsViewController : OABaseTableViewController

@property (nonatomic, weak) id<OASegmentSelectionDelegate> delegate;

- (instancetype) initWithFile:(OAGPXDocument *)gpx;

@end
