//
//  OASelectionIconTitleCollapsableWithIconCell.h
//  OsmAnd
//
//  Created by Skalii on 19.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASelectionIconTitleCollapsableWithIconCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *selectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;
@property (weak, nonatomic) IBOutlet UIButton *selectionGroupButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;
@property (weak, nonatomic) IBOutlet UIButton *openCloseGroupButton;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *arrowIconWithRightIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *arrowIconNoRightIconConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonWithRightIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonNoRightIconConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconWithSelectionButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconNoSelectionButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconWithSelectionGroupButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonWithSelectionGroupButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonNoSelectionGroupButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxHeightContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxWidthContainer;

- (void)showRightIcon:(BOOL)show;
- (void)makeSelectable:(BOOL)selectable;

@end
