//
//  OAIconTextCollapseCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAIconTextCollapseCell.h"

@implementation OAIconTextCollapseCell
{
    UIImage *_collapseIcon;
    UIImage *_expandIcon;
}

+ (NSString *) getCellIdentifier
{
    return @"OAIconTextCollapseCell";
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

-(void)setCollapsed:(BOOL)collapsed
{
    _collapsed = collapsed;
    
    if (!_collapseIcon || !_expandIcon)
    {
        _collapseIcon = [UIImage imageNamed:@"ic_arrow_close.png"];
        _collapseIcon = [_collapseIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _expandIcon = [UIImage imageNamed:@"ic_arrow_open.png"];
        _expandIcon = [_expandIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (_rightIconView.hidden)
        _rightIconView.hidden = NO;
    if (collapsed)
        _rightIconView.image = _expandIcon;
    else
        _rightIconView.image = _collapseIcon;
}

@end
