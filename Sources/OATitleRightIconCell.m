//
//  OATitleRightIconCell.m
//  OsmAnd
//
//  Created by Paul on 31.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATitleRightIconCell.h"

@implementation OATitleRightIconCell

+ (NSString *) getCellIdentifier
{
    return @"OATitleRightIconCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    _textTrailingMarginNoIcon.active = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setIconVisibility:(BOOL)visible
{
    self.iconView.hidden = !visible;
    if (visible)
    {
        _textTrailingMarginNoIcon.active = NO;
        _textTrailingMasrginWithIcon.active = YES;
    }
    else
    {
        _textTrailingMarginNoIcon.active = YES;
        _textTrailingMasrginWithIcon.active = NO;
    }
    
    [self setNeedsUpdateConstraints];
    [self updateFocusIfNeeded];
}

- (void) setBottomOffset:(CGFloat)offset
{
    [_textBottomMargin setConstant:offset];
    [self setNeedsUpdateConstraints];
    [self updateFocusIfNeeded];
}

@end
