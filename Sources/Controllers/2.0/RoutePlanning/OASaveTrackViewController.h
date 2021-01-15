//
//  OASaveTrackViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@interface OASaveTrackViewController : OACompoundViewController

@property (strong, nonatomic) IBOutlet UIView *navbarView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;

- (instancetype) initWithParams:(NSString *)fileName showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack;

@end
