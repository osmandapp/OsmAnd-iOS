//
//  OATextInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"
#import "OAUtilities.h"

#define textHeight 22
#define minTextWidth 64

@interface OATextInfoWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textView;

@end

@implementation OATextInfoWidget
{
    NSString *_contentTitle;
    NSString *_text;
    NSString *_subtext;
    BOOL _explicitlyVisible;
    
    NSString *_dayIcon;
    NSString *_nightIcon;
    BOOL _isNight;
    
    UIColor *_backgroundColor;
    UIButton *_shadowButton;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATextInfoWidget class]])
        {
            self = (OATextInfoWidget *)v;
            break;
        }
    }

    if (self)
        self.frame = CGRectMake(0, 0, kTextInfoWidgetWidth, kTextInfoWidgetHeight);

    [self commonInit];

    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATextInfoWidget class]])
        {
            self = (OATextInfoWidget *)v;
            break;
        }
    }
    
    if (self)
        self.frame = frame;

    [self commonInit];
    
    return self;
}

- (void) commonInit
{
    CGFloat radius = 3.0;
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = radius;
    
    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:2.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _primaryFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:21];
    _primaryColor = [UIColor blackColor];
    _unitsFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:14];
    _unitsColor = [UIColor grayColor];
    _text = @"";
    _subtext = @"";
    
    _shadowButton = [[UIButton alloc] initWithFrame:self.frame];
    _shadowButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_shadowButton addTarget:self action:@selector(onWidgetClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_shadowButton];
}

- (void) onWidgetClicked:(id)sender
{
    if (self.onClickFunction)
        self.onClickFunction(self);
    
    if (_delegate)
        [_delegate widgetClicked:self];
}

- (void) setImage:(UIImage *)image
{
    [_imageView setImage:image];
}

- (void) setImageHidden:(BOOL)hidden
{
    _imageView.hidden = hidden;
}

- (BOOL) setIcons:(NSString *)widgetDayIcon widgetNightIcon:(NSString *)widgetNightIcon
{
    if (![_dayIcon isEqualToString:widgetDayIcon] || ![_nightIcon isEqualToString:widgetNightIcon])
    {
        _dayIcon = widgetDayIcon;
        _nightIcon = widgetNightIcon;
        [self setImage:[UIImage imageNamed:(![self isNight] ? _dayIcon : _nightIcon)]];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL) isNight
{
    return _isNight;
}

- (NSString *) combine:(NSString *)text subtext:(NSString *)subtext
{
    if (text.length == 0)
        return subtext;
    else if (subtext.length == 0)
        return text;
    
    return [NSString stringWithFormat:@"%@ %@", text, subtext];
}

- (void) setContentDescription:(NSString *)text
{
    //view.setContentDescription(combine(contentTitle, text));
}

- (void) setContentTitle:(NSString *)text
{
    _contentTitle = text;
    [self setContentDescription:_textView.text];
}

- (void) setText:(NSString *)text subtext:(NSString *)subtext
{
    [self setTextNoUpdateVisibility:text subtext:subtext];
    [self updateVisibility:text != nil];
}

- (void) setTextNoUpdateVisibility:(NSString *)text subtext:(NSString *)subtext
{
    [self setContentDescription:[self combine:text subtext:subtext]];
    //        if(this.text != null && this.text.length() > 7) {
    //            this.text = this.text.substring(0, 6) +"..";
    //        }
    if (text.length == 0 && subtext.length == 0)
    {
        _textView.text = @"";
    }
    else
    {
        _text = text;
        _subtext = subtext;
        [self refreshLabel];
    }
}

- (void) refreshLabel
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    if (_imageView.hidden)
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[self combine:_text subtext:_subtext] attributes:attributes];
    
    NSRange valueRange = NSMakeRange(0, _text.length);
    NSRange unitRange = NSMakeRange(_text.length + 1, _subtext.length);
    
    if (valueRange.length > 0)
    {
        [string addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
        [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
    }
    if (unitRange.length > 0)
    {
        [string addAttribute:NSForegroundColorAttributeName value:_unitsColor range:unitRange];
        [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
    }
    
    _textView.attributedText = string;
    if (_delegate)
        [_delegate widgetChanged:self];
}

- (void) adjustViewSize
{
    [_textView sizeToFit];
    CGRect tf = _textView.frame;
    tf.origin.x = _imageView.hidden ? 2 : 28;
    tf.size.height = 22;
    tf.size.width = MAX(tf.size.width, minTextWidth);
    _textView.frame = tf;
    
    CGRect f = self.frame;
    f.size.width = tf.origin.x + tf.size.width + 2;
    f.size.height = 32;
    self.frame = f;
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (_delegate)
            [_delegate widgetVisibilityChanged:self visible:visible];
        
        return YES;
    }
    return NO;
}

- (BOOL) isVisible
{
    return !self.hidden && self.superview;
}

- (BOOL) updateInfo
{
    if (self.updateInfoFunction)
        return self.updateInfoFunction();
    else
        return NO;
}

- (void) setExplicitlyVisible:(BOOL)explicitlyVisible
{
    _explicitlyVisible = explicitlyVisible;
}

- (BOOL) isExplicitlyVisible
{
    return _explicitlyVisible;
}

- (void) updateIconMode:(BOOL)night
{
    _isNight = night;
    if (_dayIcon)
        [self setImage:(!night? [UIImage imageNamed:_dayIcon] : [UIImage imageNamed:_nightIcon])];
}

- (void) updateTextColor:(UIColor *)textColor bold:(BOOL)bold
{
    _primaryColor = textColor;
    [self refreshLabel];
}

@end
