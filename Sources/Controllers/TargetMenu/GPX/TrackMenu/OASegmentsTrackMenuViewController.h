//
//  OASegmentsTrackMenuViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAGPX;

@interface OASegmentsTrackMenuViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) OAGPX *gpx;

- (instancetype)initWithGpx:(OAGPX *)gpx;

- (CGFloat)getHeaderHeight;

@end