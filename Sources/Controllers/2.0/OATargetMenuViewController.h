//
//  OATargetMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef void (^ContentHeightChangeListenerBlock)(CGFloat newHeight);

@protocol OATargetMenuViewControllerDelegate <NSObject>

@optional

- (void) contentHeightChanged:(CGFloat)newHeight;
- (void) contentChanged;

- (void) btnOkPressed;
- (void) btnCancelPressed;
- (void) btnDeletePressed;

- (void) requestFullScreenMode;

@end

@interface OATargetMenuViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleGradient;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton *buttonOK;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) UINavigationController* navController;

@property (nonatomic, readonly) BOOL editing;
@property (nonatomic, readonly) BOOL wasEdited;
@property (nonatomic, readonly) BOOL showingKeyboard;

@property (nonatomic, assign) BOOL showCoords;
@property (nonatomic, copy) NSString* formattedCoords;

@property (weak, nonatomic) id<OATargetMenuViewControllerDelegate> delegate;

- (id)getTargetObj;

- (BOOL)supportFullScreen;
- (BOOL)hasTopToolbar;
- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;

- (void)useGradient:(BOOL)gradient;

- (BOOL)supportEditing;
- (void)activateEditing;
- (BOOL)commitChangesAndExit;
- (BOOL)preHide;

- (void)okPressed;
- (void)cancelPressed;

- (CGFloat)contentHeight;
- (void)setContentBackgroundColor:(UIColor *)color;

@end

