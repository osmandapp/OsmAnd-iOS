//
//  OATableViewCustomHeaderView.m
//  OsmAnd
//
//  Created by Paul on 7/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATableViewCustomHeaderView.h"
#import "OAColors.h"

@interface OATableViewCustomHeaderView ()

@end

@implementation OATableViewCustomHeaderView
{
    CGFloat _yOffset;
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

- (void) setYOffset:(CGFloat)yOffset
{
    _yOffset = yOffset;
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
    _yOffset = 17.;
    
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
    CGFloat w = self.bounds.size.width - 32. - leftMargin * 2;
    CGFloat height = [self.class getTextHeight:_label.text ? _label.text : _label.attributedText.string width:w font:_label.font];
    if (_label.text.length > 0 || _label.attributedText.length > 0)
    {
        _label.hidden = NO;
        _label.frame = CGRectMake(16.0 + leftMargin, _yOffset, w, height);
    }
    else
    {
        _label.hidden = YES;
    }
    self.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
}

+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width
{
    return [self getHeight:text width:width yOffset:17. font:self.class.font];
}

+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width yOffset:(CGFloat)yOffset font:(UIFont *)font
{
    if (text.length > 0)
        return [self.class getTextHeight:text width:width - 32.0 - OAUtilities.getLeftMargin * 2 font:font] + 5.0 + yOffset;
    else
        return 0.01;
}

+ (CGFloat) getTextHeight:(NSString *)text width:(CGFloat)width font:(UIFont *)font
{
    if (text.length > 0)
        return [OAUtilities calculateTextBounds:text width:width font:font].height;
    else
        return 0.01;
}

@end
