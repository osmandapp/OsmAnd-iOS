//
//  OAGPXPointViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAGpxWptItem.h"
#import <CoreLocation/CoreLocation.h>

@interface OAGPXPointViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) OAGpxWptItem* wptItem;

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIButton *btnSave;

@property (weak, nonatomic) IBOutlet UIView *distanceDirectionHolderView;
@property (weak, nonatomic) IBOutlet UILabel *itemDistance;
@property (weak, nonatomic) IBOutlet UIImageView *itemDirection;

@property (weak, nonatomic) IBOutlet UIButton *favoritesButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;

@property (nonatomic, readonly) BOOL isNew;

- (id)initWithWptItem:(OAGpxWptItem*)wptItem;
- (id)initWithLocation:(CLLocationCoordinate2D)coords andTitle:(NSString*)formattedLocation;

- (IBAction)menuFavoriteClicked:(id)sender;
- (IBAction)menuGPXClicked:(id)sender;


@end
