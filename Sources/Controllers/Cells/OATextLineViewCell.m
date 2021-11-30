//
//  OATextLineViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATextLineViewCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 51.0
#define defaultCellContentHeight 50.0
#define deltaTextWidth 24.0
#define textMarginVertical 5.0

static UIFont *_textFont;

@implementation OATextLineViewCell
{
    BOOL _smallMargins;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateConstraints
{
    self.textTopLargeConstraint.active = !_smallMargins;
    self.textTopSmallConstraint.active = _smallMargins;
    self.textBottomLargeConstraint.active = !_smallMargins;
    self.textBottomSmallConstraint.active = _smallMargins;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        res |= self.textTopLargeConstraint.active != !_smallMargins;
        res |= self.textTopSmallConstraint.active != _smallMargins;
        res |= self.textBottomLargeConstraint.active != !_smallMargins;
        res |= self.textBottomSmallConstraint.active != _smallMargins;
    }
    return res;
}

- (void)makeSmallMargins:(BOOL)small
{
    _smallMargins = small;
}

@end
