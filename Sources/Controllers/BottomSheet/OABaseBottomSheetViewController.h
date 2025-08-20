//
//  OABaseBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OABaseBottomSheetViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomSheetView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *headerDividerView;
@property (weak, nonatomic) IBOutlet UIView *buttonsSectionDividerView;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tileLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tileLeftNoIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonsViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonsViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *headerViewCollapsedHeight;

- (void) presentInViewController:(UIViewController *)viewController;
- (void) presentInViewController:(UIViewController *)viewController animated:(BOOL)animated;

@property (nonatomic, readonly) CGFloat initialHeight;
@property (nonatomic, readonly) CGFloat buttonsViewHeight;
@property (nonatomic) BOOL isFullScreenAvailable;
@property (nonatomic, readonly) BOOL isDraggingUpAvailable;

- (void) adjustFrame;
- (void) onRightButtonPressed;

- (void) goFullScreen;
- (void) goMinimized;
- (void) hide:(BOOL)animated;
- (void) hide:(BOOL)animated completion:(void (^ __nullable)(void))completion;
- (void) hideSliderView;

- (void) setHeaderViewVisibility:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
