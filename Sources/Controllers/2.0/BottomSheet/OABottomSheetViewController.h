//
//  OABottomSheetViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OABottomSheetScreen.h"
#import "OATableView.h"

@interface OABottomSheetViewController : UIViewController

@property (nonatomic) IBOutlet UIView *backgroundView;
@property (nonatomic) IBOutlet UIView *contentView;
@property (nonatomic) IBOutlet OATableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic) id<OABottomSheetScreen> screenObj;
@property (nonatomic) id customParam;

@property (nonatomic, getter = isVisible) BOOL visible;

- (instancetype) initWithParam:(id)param;

- (CGRect) contentViewFrame;

- (void) show;
- (void) dismiss;

- (void) commonInit;
- (void) setupView;

- (void) applyLocalization;

- (void) setTapToDismissEnabled:(BOOL)enabled;

@end
