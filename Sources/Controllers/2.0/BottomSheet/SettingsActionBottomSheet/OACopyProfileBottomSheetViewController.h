//
//  OACopyProfileBottomSheetViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 05.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAApplicationMode.h"

@interface OACopyProfileBottomSheetViewController : UIView<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *cpyProfileButton;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;

- (instancetype) initWithFrame:(CGRect)frame mode:(OAApplicationMode *)am;
- (void) show:(BOOL)animated;
- (void) hide:(BOOL)animated;

@end
/*
@class OACopyProfileBottomSheetViewController;

@interface OACopyProfileBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OACopyProfileBottomSheetViewController *)viewController appMode:(OAApplicationMode *)am;

@end

@interface OACopyProfileBottomSheetViewController : OABottomSheetTwoButtonsViewController

- (instancetype) initWithMode:(OAApplicationMode *)am;

@end
*/
