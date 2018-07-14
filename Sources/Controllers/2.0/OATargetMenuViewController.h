//
//  OATargetMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "OATargetPoint.h"

typedef NS_ENUM(NSInteger, ETopToolbarType)
{
    ETopToolbarTypeFixed = 0,
    ETopToolbarTypeMiddleFixed,
    ETopToolbarTypeFloating,
};

typedef void (^ContentHeightChangeListenerBlock)(CGFloat newHeight);

@protocol OATargetMenuViewControllerDelegate <NSObject>

@optional

- (void) contentHeightChanged:(CGFloat)newHeight;
- (void) contentChanged;

- (void) btnOkPressed;
- (void) btnCancelPressed;
- (void) btnDeletePressed;

- (void) addWaypoint;

- (void) requestHeaderOnlyMode;
- (void) requestFullScreenMode;

- (BOOL) isInFullMode;
- (BOOL) isInFullScreenMode;

- (NSString *) getTargetTitle;

- (void) keyboardWasShown:(CGFloat)keyboardHeight;
- (void) keyboardWasHidden:(CGFloat)keyboardHeight;

@end

@interface OATargetMenuViewControllerState : NSObject

@end

@interface OATargetMenuControlButton : NSObject

@property (nonatomic) NSString *title;

@end

@class OATargetPoint;

@interface OATargetMenuViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIButton *buttonBack;

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIView *navBarBackground;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleGradient;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton *buttonOK;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) UINavigationController* navController;

@property (nonatomic, readonly) BOOL editing;
@property (nonatomic, readonly) BOOL wasEdited;
@property (nonatomic, readonly) BOOL showingKeyboard;
@property (nonatomic, readonly) CGSize keyboardSize;

@property (nonatomic) ETopToolbarType topToolbarType;
@property (nonatomic, readonly) BOOL topToolbarGradient;

@property (nonatomic, readonly) BOOL actionButtonPressed;

@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, readonly) NSString *formattedCoords;

@property (nonatomic) OATargetMenuControlButton *leftControlButton;
@property (nonatomic) OATargetMenuControlButton *rightControlButton;

@property (weak, nonatomic) id<OATargetMenuViewControllerDelegate> delegate;

+ (OATargetMenuViewController *) createMenuController:(OATargetPoint *)targetPoint activeTargetType:(OATargetPointType)activeTargetType activeViewControllerState:(OATargetMenuViewControllerState *)activeViewControllerState;

- (id) getTargetObj;

- (UIImage *) getIcon;

- (BOOL) needAddress;
- (NSString *) getTypeStr;
- (NSString *) getCommonTypeStr;
- (NSAttributedString *) getAttributedTypeStr;
- (NSAttributedString *) getAttributedCommonTypeStr;

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group;

- (UIColor *) getAdditionalInfoColor;
- (NSAttributedString *) getAdditionalInfoStr;
- (UIImage *) getAdditionalInfoImage;

- (BOOL) supportFullMenu;
- (BOOL) supportFullScreen;

- (void) goHeaderOnly;
- (void) goFull;
- (void) goFullScreen;

- (BOOL) showTopControls;
- (BOOL) supportMapInteraction;
- (BOOL) showNearestWiki;

- (BOOL) hasTopToolbar;
- (BOOL) shouldShowToolbar;
- (BOOL) hasTopToolbarShadow;
- (void) applyTopToolbarTargetTitle;
- (void) setTopToolbarAlpha:(CGFloat)alpha;
- (void) setMiddleToolbarAlpha:(CGFloat)alpha;

- (void) applyGradient:(BOOL)gradient alpha:(CGFloat)alpha;

- (BOOL) disablePanWhileEditing;
- (BOOL) supportEditing;
- (void) activateEditing;
- (BOOL) commitChangesAndExit;
- (BOOL) preHide;

- (void) backPressed;
- (void) okPressed;
- (void) cancelPressed;

- (BOOL) hasContent;
- (CGFloat) contentHeight;
- (void) setContentBackgroundColor:(UIColor *)color;

- (BOOL) hasInfoView;
- (BOOL) hasInfoButton;
- (BOOL) hasRouteButton;

- (BOOL) hasControlButtons;
- (void) leftControlButtonPressed;
- (void) rightControlButtonPressed;

- (OATargetMenuViewControllerState *)getCurrentState;

- (BOOL) isLandscape;

@end

