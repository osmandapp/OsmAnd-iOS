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

typedef NS_ENUM(NSUInteger, EOAScrollableMenuHudMode)
{
    EOAScrollableMenuHudBaseMode = 0,
    EOAScrollableMenuHudExtraHeaderInLandscapeMode
};

@interface OABaseScrollableHudViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIView *scrollableView;
@property (weak, nonatomic) IBOutlet UIView *topHeaderContainerView;

@property (nonatomic, readonly) CGFloat initialMenuHeight;
@property (nonatomic, readonly) CGFloat expandedMenuHeight;

@property (nonatomic, readonly) EOAScrollableMenuHudMode menuHudMode;
@property (nonatomic, readonly) EOADraggableMenuState currentState;

@property (nonatomic, readonly) BOOL supportsFullScreen;

- (void) show:(BOOL)animated state:(EOADraggableMenuState)state onComplete:(void (^)(void))onComplete;
- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;

- (void) goExpanded;
- (void) goMinimized;
- (void) goFullScreen;
- (void) goExpanded:(BOOL)animated;
- (void) goMinimized:(BOOL)animated;
- (void) goFullScreen:(BOOL)animated;

- (CGFloat) getViewHeight:(EOADraggableMenuState)state;
- (CGFloat) getViewHeight;
- (CGFloat) getToolbarHeight;

- (void) doAdditionalLayout;
- (void) updateLayoutCurrentState;
- (CGFloat) getLandscapeYOffset;
- (CGFloat) additionalLandscapeOffset;
- (void) updateShowingState:(EOADraggableMenuState)state;

- (void) updateViewAnimated;
- (BOOL) isLandscape;
- (BOOL) isLeftSidePresentation;

@end
