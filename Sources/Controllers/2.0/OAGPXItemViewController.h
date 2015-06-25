//
//  OAGPXItemViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAGPXWptListViewController.h"

typedef enum
{
    kSegmentStatistics = 0,
    kSegmentWaypoints
    
} OAGpxSegmentType;


@class OAGPX;
@class OAGPXDocument;


@interface OAGPXItemViewControllerState : NSObject

@property (nonatomic, assign) OAGpxSegmentType segmentType;
@property (nonatomic, assign) BOOL showFullScreen;
@property (nonatomic, assign) CGFloat scrollPos;
@property (nonatomic, assign) EPointsSortingType sortType;
@property (nonatomic, assign) BOOL showCurrentTrack;

@end



@interface OAGPXItemViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OAGPX *gpx;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *segmentViewContainer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentView;
@property (weak, nonatomic) IBOutlet UIButton *buttonMore;
@property (weak, nonatomic) IBOutlet UIButton *buttonUpdate;

@property (weak, nonatomic) IBOutlet UIButton *buttonSort;
@property (weak, nonatomic) IBOutlet UIButton *buttonEdit;

@property (nonatomic, readonly) BOOL showCurrentTrack;

- (id)initWithGPXItem:(OAGPX *)gpxItem;
- (id)initWithGPXItem:(OAGPX *)gpxItem ctrlState:(OAGPXItemViewControllerState *)ctrlState;
- (id)initWithCurrentGPXItem;
- (id)initWithCurrentGPXItem:(OAGPXItemViewControllerState *)ctrlState;

- (OAGPXItemViewControllerState *) getCurrentState;

@end
