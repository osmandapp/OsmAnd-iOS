//
//  OABaseSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
#import "OACompoundViewController.h"

@class OAApplicationMode;

@protocol OASettingsDataDelegate <NSObject>

- (void) onSettingsChanged;
- (void) closeSettingsScreenWithRouteInfo;
- (void) openNavigationSettings;

@end

@interface OABaseSettingsViewController : OACompoundViewController <OASettingsDataDelegate>

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navBarHeightConstraint;

@property (weak, nonatomic) id<OASettingsDataDelegate> delegate;
@property (nonatomic) OAApplicationMode *appMode;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;

- (CGFloat) heightForLabel:(NSString *)text;
- (void) setupTableHeaderViewWithText:(NSString *)text;

@end
