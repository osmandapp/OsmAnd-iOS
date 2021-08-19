//
//  OASaveTrackViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@protocol OASaveTrackViewControllerDelegate <NSObject>

- (void) onSaveAsNewTrack:(NSString *)fileName showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack;

@end

@interface OASaveTrackViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (weak, nonatomic) id<OASaveTrackViewControllerDelegate> delegate;

- (instancetype) initWithFileName:(NSString *)fileName filePath:(NSString *)filePath showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack;

@end
