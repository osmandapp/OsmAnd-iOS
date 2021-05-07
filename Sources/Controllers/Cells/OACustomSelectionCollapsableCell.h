//
//  OACustomSelectionCollapsableCell.h
//  OsmAnd
//
//  Created by Paul on 03.26.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OACustomSelectionCollapsableCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIButton *openCloseGroupButton;
@property (weak, nonatomic) IBOutlet UIView *selectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxHeightContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxWidthContainer;


@end
