//
//  OATableViewCustomFooterView.m
//  OsmAnd
//
//  Created by Paul on 7/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATableViewCustomFooterView.h"
#import "OAColors.h"

static UIFont *_font;

@interface OATableViewCustomFooterView ()

@end

@implementation OATableViewCustomFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self setupView];
    }
    return self;
}

- (void) setupView
{
    self.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.userInteractionEnabled = YES;
    [self.textLabel removeFromSuperview];
    [self.detailTextLabel removeFromSuperview];
    
    if (!_font)
        _font = [UIFont systemFontOfSize:13.0];
    
    _label = [[UITextView alloc] init];
    _label.backgroundColor = [UIColor clearColor];
    _label.font = _font;
    _label.editable = NO;
    _label.scrollEnabled = NO;
    _label.userInteractionEnabled = YES;
    _label.selectable = YES;
    _label.textColor = UIColorFromRGB(text_color_gray);
    _label.dataDetectorTypes = UIDataDetectorTypeLink;
    _label.textContainerInset = UIEdgeInsetsZero;
    _label.textContainer.lineFragmentPadding = 0;
    
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
    _label.linkTextAttributes = linkAttributes;
    
    [self.contentView addSubview:_label];
}

- (void)layoutSubviews
{
    CGFloat leftMargin = OAUtilities.getLeftMargin;
    CGFloat height = [self.class getTextHeight:_label.text width:self.bounds.size.width];
    if (_label.text.length > 0)
    {
        _label.hidden = NO;
        _label.frame = CGRectMake(16.0 + leftMargin, 8.0, self.bounds.size.width - 32. - leftMargin * 2, height);
    }
    else
    {
        _label.hidden = YES;
    }
    self.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
}

+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width
{
    if (text.length > 0)
        return MAX(44.0, [self.class getTextHeight:text width:width] + 5.0);
    else
        return 0.01;
}

+ (CGFloat) getTextHeight:(NSString *)text width:(CGFloat)width
{
    if (!_font)
        _font = [UIFont systemFontOfSize:13.0];
    
    if (text.length > 0)
        return [OAUtilities calculateTextBounds:text width:width font:_font].height + 8.0;
    else
        return 0.01;
}

@end
