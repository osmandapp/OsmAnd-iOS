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
@property (nonatomic) IBOutlet NSLayoutConstraint *titleWidthConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *valueWidthConstraint;

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

// Give value label more space to be closer to title label
- (void)setupValueLabelFlexible
{
    _titleWidthConstraint.active = NO;
    _valueWidthConstraint.active = NO;
    [_valueStackView setContentHuggingPriority:UILayoutPriorityDefaultLow - 1 forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentInsideStackView setDistribution:UIStackViewDistributionFillProportionally];
}

- (void)resetValueLabelToDefault
{
    _titleWidthConstraint.active = YES;
    _valueWidthConstraint.active = YES;
    [_valueStackView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentInsideStackView setDistribution:UIStackViewDistributionFill];
}

@end
