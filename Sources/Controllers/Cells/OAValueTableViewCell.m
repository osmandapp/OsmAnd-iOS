//
//  OAValueTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAValueTableViewCell.h"

@interface OAValueTableViewCell ()

@property (weak, nonatomic) IBOutlet UIStackView *valueStackView;
@property (nonatomic) IBOutlet NSLayoutConstraint *titleWidthGreaterThanEqualConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *titleWidthEqualConstraint;

@end

@implementation OAValueTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([self isDirectionRTL])
        self.valueLabel.textAlignment = NSTextAlignmentLeft;
    self.valueLabel.adjustsFontSizeToFitWidth = YES;
    self.valueLabel.minimumScaleFactor = 0.8;
    [self layoutIfNeeded];
}

- (void)valueVisibility:(BOOL)show
{
    self.valueStackView.hidden = !show;
    [self updateMargins];
}

- (void)showProButton:(BOOL)show
{
    [self valueVisibility:!show];
    self.proButton.hidden = !show;
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.valueStackView.hidden;
}

- (void)setActiveTitleWidthGreaterThanEqualConstraint:(BOOL)active
{
    _titleWidthGreaterThanEqualConstraint.active = active;
}

- (void)setActiveTitleWidthEqualConstraint:(BOOL)active
{
    _titleWidthEqualConstraint.active = active;
}

- (void)setTitleWidthEqualConstraintValue:(CGFloat)value
{
    _titleWidthEqualConstraint.constant = value;
}

@end
