//
//  OASelectionCollapsableCell.h
//  OsmAnd
//
//  Created by Skalii on 19.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASelectionCollapsableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *selectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;
@property (weak, nonatomic) IBOutlet UIButton *selectionGroupButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowIconView;
@property (weak, nonatomic) IBOutlet UIButton *openCloseGroupButton;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIButton *optionsGroupButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *arrowIconWithOptionButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *arrowIconNoOptionButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconWithSelectionButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconNoSelectionButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconWithSelectionGroupButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonWithSelectionGroupButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonNoSelectionGroupButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonWithOptionsGroupButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *openCloseGroupButtonNoOptionsGroupButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxHeightContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxWidthContainer;

- (void)showOptionsButton:(BOOL)show;
- (void)makeSelectable:(BOOL)selectable;

@end
