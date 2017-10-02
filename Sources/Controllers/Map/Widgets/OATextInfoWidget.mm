//
//  OATextInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

@interface OATextInfoWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UILabel *topTextView;

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
    
    UIFont *_primaryFont;
    UIColor *_primaryColor;
    UIFont *_unitsFont;
    UIColor *_unitsColor;
    
    UITapGestureRecognizer *_tapGesture;
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
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _primaryFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:21];
    _primaryColor = [UIColor blackColor];
    _unitsFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:14];
    _unitsColor = [UIColor grayColor];
    _text = @"";
    _subtext = @"";
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onWidgetClicked:)];
    [self addGestureRecognizer:_tapGesture];
}

- (void) dealloc
{
    [self removeGestureRecognizer:_tapGesture];
}

- (void) onWidgetClicked:(id)sender
{
    if (_delegate)
        [_delegate widgetClicked:sender];
}

- (void) setImage:(UIImage *)image
{
    [_imageView setImage:image];
}

- (void) setTopImage:(UIImage *)image
{
    // implement
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
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[self combine:_text subtext:_subtext]];
    
    NSUInteger subtextIndex = _text.length;
    NSRange valueRange = NSMakeRange(0, subtextIndex);
    NSRange unitRange = NSMakeRange(subtextIndex, _text.length - subtextIndex);
    
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
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible != self.hidden)
    {
        self.hidden = !visible;
        if (_delegate)
            [_delegate widgetVisibilityChanged:visible];
        
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
