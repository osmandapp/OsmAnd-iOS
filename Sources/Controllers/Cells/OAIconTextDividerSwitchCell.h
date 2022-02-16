//
//  OAIconTextDividerSwitchCell.h
//  OsmAnd
//
//  Created by Skalii on 02.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTextDividerSwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *textLeftConstraintNoImage;
@property (nonatomic) IBOutlet NSLayoutConstraint *textRightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *textRightConstraintNoDivider;

- (void)showIcon:(BOOL)show;

@end