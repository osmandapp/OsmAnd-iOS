//
//  OATrackMenuViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"

@class OAGPX;
@class OATabBar;

@protocol OATrackMenuViewControllerDelegate <NSObject>

@optional

- (void)overviewContentChanged;
- (BOOL)onShowHidePressed;
- (void)onColorPressed;
- (void)onExportPressed;
- (void)onNavigationPressed;

@end

@interface OATrackMenuViewController : OABaseScrollableHudViewController

@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;
@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

- (instancetype)initWithGpx:(OAGPX *)gpx;

@end
