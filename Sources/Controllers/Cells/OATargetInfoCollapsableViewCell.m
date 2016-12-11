//
//  OATargetInfoCollapsableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoCollapsableViewCell.h"

@implementation OATargetInfoCollapsableViewCell
{
    UIImage *_collapseIcon;
    UIImage *_expandIcon;
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

- (void)setCollapsed:(BOOL)collapsed rawHeight:(int)rawHeight
{
    CGRect tf = _textView.frame;
    _collapsable = YES;
    if (_collapsableView)
    {
        if (!_collapseIcon || !_expandIcon)
        {
            _collapseIcon = [UIImage imageNamed:@"ic_arrow_close.png"];
            _collapseIcon = [_collapseIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _expandIcon = [UIImage imageNamed:@"ic_arrow_open.png"];
            _expandIcon = [_expandIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        _rightIconView.hidden = NO;
        _textView.frame = CGRectMake(tf.origin.x, tf.origin.y, _rightIconView.frame.origin.x - tf.origin.x, tf.size.height);
        _textView.autoresizingMask -= UIViewAutoresizingFlexibleHeight;
        [self updateCollapsedState:collapsed];
        
        if (!_collapsableView.superview || _collapsableView.superview != self)
        {
            [self addSubview:_collapsableView];
        }
        _collapsableView.frame = CGRectMake(0, rawHeight, self.frame.size.width, _collapsableView.frame.size.height);
    }
}

-(void)updateCollapsedState:(BOOL)collapsed
{
    if (collapsed)
    {
        _rightIconView.image = _expandIcon;
        _collapsableView.hidden = YES;
    }
    else
    {
        _rightIconView.image = _collapseIcon;
        _collapsableView.hidden = NO;
    }
}

@end
