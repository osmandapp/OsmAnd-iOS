//
//  OATargetMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef void (^ContentHeightChangeListenerBlock)(CGFloat newHeight);

@interface OATargetMenuViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton *buttonOK;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic, copy) ContentHeightChangeListenerBlock heightChangeListenerBlock;

- (BOOL)hasTopToolbar;

- (void)okPressed;
- (void)cancelPressed;

- (CGFloat)contentHeight;
- (void)setContentHeightChangeListener:(ContentHeightChangeListenerBlock)block;
- (void)setContentBackgroundColor:(UIColor *)color;

@end

