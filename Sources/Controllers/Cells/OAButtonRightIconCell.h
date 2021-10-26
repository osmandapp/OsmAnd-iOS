//
//  OAButtonRightIconCell.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 22.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAButtonRightIconCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (nonatomic) IBOutlet NSLayoutConstraint *buttonHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *buttonTopConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *buttonVerticallyAllignmentConstraint;

- (void)setButtonTopOffset:(CGFloat)offset;

@end
