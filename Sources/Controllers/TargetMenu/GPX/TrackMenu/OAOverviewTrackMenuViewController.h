//
//  OAOverviewTrackMenuViewController.h
//  OsmAnd
//
//  Created by Skalii on 08.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAGPX;
@class OAButton;

@protocol OAOverviewTrackMenuViewControllerDelegate <NSObject>

@required

- (void)overviewContentChanged;
- (void)onExport;
- (BOOL)onShowHide;

@end

@interface OAOverviewTrackMenuViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (weak, nonatomic) IBOutlet UICollectionView *statisticsCollectionView;

@property (weak, nonatomic) IBOutlet UIImageView *directionIconView;
@property (weak, nonatomic) IBOutlet UILabel *directionTextView;
@property (weak, nonatomic) IBOutlet UILabel *dirLocSeparatorTextView;
@property (weak, nonatomic) IBOutlet UIImageView *locationIconView;
@property (weak, nonatomic) IBOutlet UILabel *locationTextView;

@property (weak, nonatomic) IBOutlet OAButton *showHideButton;
@property (weak, nonatomic) IBOutlet OAButton *appearanceButton;
@property (weak, nonatomic) IBOutlet OAButton *exportButton;
@property (weak, nonatomic) IBOutlet OAButton *navigationButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id<OAOverviewTrackMenuViewControllerDelegate> delegate;

- (instancetype)initWithGpx:(OAGPX *)gpx;

- (CGFloat)getHeaderHeight;

@end
