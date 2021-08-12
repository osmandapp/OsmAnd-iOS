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

@protocol OACopyProfileBottomSheetDelegate <NSObject>

@required

- (void) onCopyProfileCompleted;
- (void) onCopyProfileDismessed;

@end

@interface OACopyProfileBottomSheetView : UIView<UITableViewDelegate, UITableViewDataSource>

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

@property (nonatomic) id<OACopyProfileBottomSheetDelegate> delegate;

- (instancetype) initWithFrame:(CGRect)frame mode:(OAApplicationMode *)am;
- (void) show:(BOOL)animated;
- (void) hide:(BOOL)animated;

@end
