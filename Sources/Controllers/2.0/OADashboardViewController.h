//
//  OADashboardViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OADashboardScreen.h"

@interface OADashboardViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *navbarBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *navbarBackgroundImg;

@property (weak, nonatomic) IBOutlet UIView *pickerView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *pickerImg;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL showFull;

@property (nonatomic) OADashboardViewController *parentVC;
@property (nonatomic) NSInteger screenType;
@property (nonatomic) id<OADashboardScreen> screenObj;
@property (nonatomic) id customParam;
@property (nonatomic) BOOL topControlsVisible;

- (void) deleteParentVC:(BOOL)deleteAll;

- (void) updateLayout:(UIInterfaceOrientation)interfaceOrientation;
- (CGRect) contentViewFrame;

- (void) show:(UIViewController *)rootViewController parentViewController:(OADashboardViewController *)parentViewController animated:(BOOL)animated;
- (void) hide:(BOOL)hideAll animated:(BOOL)animated;
- (void) hide:(BOOL)hideAll animated:(BOOL)animated duration:(CGFloat)duration;

- (void) waitForIdle;

- (instancetype) initWithScreenType:(NSInteger)screenType;
- (instancetype) initWithScreenType:(NSInteger)screenType param:(id)param;

- (void) commonInit;
- (BOOL) isMainScreen;
- (void) closeDashboard;
- (void) setupView;

@end
