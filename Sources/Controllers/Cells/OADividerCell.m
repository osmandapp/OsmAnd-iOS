//
//  OADividerCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OADividerCell
{
    CALayer *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _dividerColor = [SeparatorAppearance color];
    _dividerHight = [SeparatorAppearance thicknessForView:self];
    _dividerInsets = UIEdgeInsetsMake(0, 44.0, 0, 0);
    
    _divider = [[CALayer alloc] init];
    [self.layer addSublayer:_divider];
    [self updateDividerColor];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    CGFloat leading = _alignsWithLayoutMargins ? self.directionalLayoutMargins.leading : _dividerInsets.left;
    CGFloat trailing = _alignsWithLayoutMargins ? self.directionalLayoutMargins.trailing : _dividerInsets.right;
    CGFloat w = self.frame.size.width - leading - trailing;
    _divider.frame = CGRectMake([self isDirectionRTL] ? trailing : leading, _dividerInsets.top, w, _dividerHight);
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self updateDividerColor];
}

- (void) setDividerColor:(UIColor *)dividerColor
{
    _dividerColor = dividerColor;
    [self updateDividerColor];
}

- (void) setAlignsWithLayoutMargins:(BOOL)alignsWithLayoutMargins
{
    _alignsWithLayoutMargins = alignsWithLayoutMargins;
    [self setNeedsLayout];
}

- (void) updateDividerColor
{
    if (_divider)
        _divider.backgroundColor = [_dividerColor resolvedColorWithTraitCollection:self.traitCollection].CGColor;
}

- (CGFloat) cellHeight
{
    return _dividerInsets.top + _dividerHight + _dividerInsets.bottom;
}

+ (CGFloat) cellHeight:(CGFloat)dividerHight dividerInsets:(UIEdgeInsets)dividerInsets
{
    return dividerInsets.top + dividerHight + dividerInsets.bottom;
}

@end
