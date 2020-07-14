//
//  OATargetInfoCollapsableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoCollapsableViewCell.h"
#import "OACollapsableView.h"

@implementation OATargetInfoCollapsableViewCell
{
    UIImage *_collapseIcon;
    UIImage *_expandIcon;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (_collapsableView)
        [_collapsableView setSelected:selected animated:animated];
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (_collapsableView)
        [_collapsableView setHighlighted:highlighted animated:animated];
}

- (void) setCollapsed:(BOOL)collapsed rawHeight:(int)rawHeight
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
        _textView.frame = CGRectMake(tf.origin.x, 0, _rightIconView.frame.origin.x - tf.origin.x, rawHeight);
        [self updateCollapsedState:collapsed];
        
        if (!_collapsableView.superview || _collapsableView.superview != self)
        {
            [self addSubview:_collapsableView];
        }
        _collapsableView.frame = CGRectMake(0, rawHeight, self.frame.size.width, _collapsableView.frame.size.height);
        _collapsableView.collapsed = collapsed;
    }
}

-(void) updateCollapsedState:(BOOL)collapsed
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

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGRect textFrame = self.textView.frame;
    CGRect leftImageFrame = self.iconView.frame;
    CGRect rightImageFrame = self.rightIconView.frame;
    CGFloat x;
    if (self.iconView.image)
        x = 60.0;
    else
        x = leftImageFrame.origin.x;
    
    self.textView.frame = CGRectMake(x, textFrame.origin.y, rightImageFrame.origin.x - x, textFrame.size.height);
}

- (void) setImage:(UIImage *)image
{
    self.iconView.image = image;
    [self setNeedsLayout];
}

@end
