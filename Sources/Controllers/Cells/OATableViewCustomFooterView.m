//
//  OATableViewCustomFooterView.m
//  OsmAnd
//
//  Created by Paul on 7/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATableViewCustomFooterView.h"
#import "OAColors.h"

@interface OATableViewCustomFooterView ()

@end

@implementation OATableViewCustomFooterView
{
    UIImageView *_iconView;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self setupView];
    }
    return self;
}

+ (UIFont *) font
{
    static UIFont *_font;
    if (!_font)
        _font = [UIFont systemFontOfSize:13.0];
    
    return _font;
}

- (void) setupView
{
    self.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.userInteractionEnabled = YES;
    [self.textLabel removeFromSuperview];
    [self.detailTextLabel removeFromSuperview];
    
    _iconView = [[UIImageView alloc] init];
    
    _label = [[UITextView alloc] init];
    _label.backgroundColor = [UIColor clearColor];
    _label.font = self.class.font;
    _label.editable = NO;
    _label.scrollEnabled = NO;
    _label.userInteractionEnabled = YES;
    _label.selectable = YES;
    _label.textColor = UIColorFromRGB(color_text_footer);
    _label.dataDetectorTypes = UIDataDetectorTypeLink;
    _label.textContainerInset = UIEdgeInsetsZero;
    _label.textContainer.lineFragmentPadding = 0;
    _label.textContainer.maximumNumberOfLines = 0;
    _label.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
    _label.linkTextAttributes = linkAttributes;
    
    [self.contentView addSubview:_label];
}

- (void)layoutSubviews
{
    CGFloat leftMargin = OAUtilities.getLeftMargin;
    BOOL hasIcon = _iconView != nil && _iconView.superview != nil;
    if (hasIcon)
    {
        _iconView.frame = CGRectMake(16.0 + leftMargin, 8.0, 30.0, 30.0);
    }
    CGFloat w = self.bounds.size.width - 32. - leftMargin * 2 - (hasIcon ? 30.0 : 0.0) - 16.;
    CGFloat height = _label.attributedText.length > 0 ? [OAUtilities calculateTextBounds:_label.attributedText width:w].height : [self.class getTextHeight:_label.text width:w];
    if (_label.text.length > 0)
    {
        _label.hidden = NO;
        _label.frame = CGRectMake(16.0 + (hasIcon ? CGRectGetMaxX(_iconView.frame) : leftMargin), 8.0, w, height);
    }
    else
    {
        _label.hidden = YES;
    }
    self.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
}

- (void) setIcon:(NSString *)imageName
{
    if (!imageName)
    {
        if (_iconView && _iconView.superview)
            [_iconView removeFromSuperview];
        
        _iconView.image = nil;
    }
    else
    {
        _iconView.image = [UIImage templateImageNamed:imageName];
        [_iconView sizeToFit];
        _iconView.tintColor = UIColorFromRGB(color_footer_icon_gray);
        if (!_iconView.superview)
            [self.contentView addSubview:_iconView];
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width
{
    if (text.length > 0)
        return [self.class getTextHeight:text width:width - 32.0 - OAUtilities.getLeftMargin * 2] + 5.0;
    else
        return 0.01;
}

+ (CGFloat) getTextHeight:(NSString *)text width:(CGFloat)width
{
    if (text.length > 0)
        return [OAUtilities calculateTextBounds:text width:width font:self.class.font].height + 8.0;
    else
        return 0.01;
}

@end
