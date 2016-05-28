//
//  OATargetMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import <CoreLocation/CoreLocation.h>

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

- (BOOL)isInFullMode;
- (BOOL)isInFullScreenMode;

@end

@interface OATargetMenuViewControllerState : NSObject

@end

@interface OATargetMenuViewController : OASuperViewController

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

@property (nonatomic, readonly) BOOL actionButtonPressed;

@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, readonly) NSString *formattedCoords;

@property (weak, nonatomic) id<OATargetMenuViewControllerDelegate> delegate;

- (id)getTargetObj;

- (BOOL)needAddress;
- (NSString *)getTypeStr;
- (NSString *)getCommonTypeStr;
- (NSAttributedString *)getAttributedTypeStr;
- (NSAttributedString *)getAttributedCommonTypeStr;

- (NSAttributedString *)getAttributedTypeStr:(NSString *)group;

- (BOOL)supportFullMenu;
- (BOOL)supportFullScreen;
- (BOOL)fullScreenWithoutHeader;

- (void)goHeaderOnly;
- (void)goFull;
- (void)goFullScreen;

- (BOOL)showTopControls;
- (BOOL)supportMapInteraction;

- (BOOL)hasTopToolbar;
- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;

- (void)useGradient:(BOOL)gradient;

- (BOOL)disablePanWhileEditing;
- (BOOL)supportEditing;
- (void)activateEditing;
- (BOOL)commitChangesAndExit;
- (BOOL)preHide;

- (void)okPressed;
- (void)cancelPressed;

- (BOOL)hasContent;
- (CGFloat)contentHeight;
- (void)setContentBackgroundColor:(UIColor *)color;

- (OATargetMenuViewControllerState *)getCurrentState;

@end

