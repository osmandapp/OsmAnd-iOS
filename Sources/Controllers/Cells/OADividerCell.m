//
//  OADividerCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OADividerCell
{
    CALayer *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _dividerColor = UIColorFromRGB(color_divider_light);
    _dividerHight = 0.5;
    _dividerInsets = UIEdgeInsetsMake(0, 44.0, 0, 0);
    
    _divider = [[CALayer alloc] init];
    _divider.backgroundColor = _dividerColor.CGColor;
    [self.layer addSublayer:_divider];
}

+ (NSString *) getCellIdentifier
{
    return [OADividerCell getCellIdentifier];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.frame.size.width - _dividerInsets.left - _dividerInsets.right;
    _divider.frame = CGRectMake(_dividerInsets.left, _dividerInsets.top, w, _dividerHight);
}

- (void) setDividerColor:(UIColor *)dividerColor
{
    _dividerColor = dividerColor;
    
    if (_divider)
        _divider.backgroundColor = _dividerColor.CGColor;
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
