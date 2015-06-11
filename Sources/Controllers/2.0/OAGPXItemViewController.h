//
//  OAGPXItemViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@class OAGPX;
@class OAGPXDocument;

@interface OAGPXItemViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic) OAGPX *gpx;

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (nonatomic, readonly) BOOL showCurrentTrack;

- (IBAction)showPointsClicked:(id)sender;
- (IBAction)deleteClicked:(id)sender;

- (id)initWithGPXItem:(OAGPX *)gpxItem;
- (id)initWithCurrentGPXItem;
- (id)initWithCurrentGPXItemNoToolbar;

@end
