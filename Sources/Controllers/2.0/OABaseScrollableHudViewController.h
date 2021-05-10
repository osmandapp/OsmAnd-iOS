//
//  OABaseScrollableHudViewController.h
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOADraggableMenuState)
{
    EOADraggableMenuStateInitial = 0,
    EOADraggableMenuStateExpanded,
    EOADraggableMenuStateFullScreen
};

@interface OABaseScrollableHudViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIView *scrollableView;
@property (weak, nonatomic) IBOutlet UIView *topHeaderContainerView;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *sliderView;

@property (nonatomic, readonly) CGFloat initialMenuHeight;
@property (nonatomic, readonly) CGFloat expandedMenuHeight;

@property (nonatomic) EOADraggableMenuState currentState;

@property (nonatomic) BOOL supportsFullScreen;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) BOOL isHiding;

- (void) show:(BOOL)animated state:(EOADraggableMenuState)state onComplete:(void (^)(void))onComplete;
- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;
- (void) applyCornerRadius:(BOOL)enable;

- (void) goExpanded;
- (void) goMinimized;
- (void) goFullScreen;

- (CGFloat) getViewHeight:(EOADraggableMenuState)state;
- (CGFloat) getViewHeight;
- (CGFloat) getViewWidthForPad;
- (CGFloat) additionalLandscapeOffset;

@end
