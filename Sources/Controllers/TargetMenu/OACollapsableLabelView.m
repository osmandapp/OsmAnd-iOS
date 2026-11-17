//
//  OACollapsableLabelView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableLabelView.h"
#import "OALabel.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OACollapsableLabelView () <OALabelDelegate>

@end

@implementation OACollapsableLabelView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        CGFloat viewWidth = frame.size.width;
        _label = [[OALabel alloc] initWithFrame:CGRectMake(kMarginLeft, 12.0, viewWidth - kMarginLeft - kMarginRight, 21.0)];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _label.font = font;
        _label.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        _label.numberOfLines = 0;
        [_label setUserInteractionEnabled:YES];
        [_label bringSubviewToFront:self];
        _label.delegate = self;
        [self addSubview:_label];
    }
    return self;
}

- (instancetype) initWithText:(NSString *)text collapsed:(BOOL)collapsed
{
    self = [self initWithDefaultParameters:collapsed];
    if (self)
    {
        [self setText:text];
    }
    return self;
}

- (void)adjustHeightForWidth:(CGFloat)width
{
    CGFloat leftMargin = OAUtilities.isLandscape && !OAUtilities.isIPad ? 2 * kMarginLeft : kMarginLeft;
    CGFloat textWidth = width - leftMargin - kMarginRight;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:_label.text ?: @""
                                                                            attributes:@{NSFontAttributeName: _label.font}];
    [_label.attributedText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, text.length) options:0 usingBlock:^(UIFont *font, NSRange range, BOOL *stop) {
        if (font)
            [text addAttribute:NSFontAttributeName value:font range:range];
    }];
    CGSize bounds = [text boundingRectWithSize:CGSizeMake(ceil(textWidth), 10000.0)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     context:nil].size;
    bounds.height = ceil(bounds.height);
    CGFloat viewHeight = MAX(bounds.height, 21.0) + 0.0 + 11.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
    _label.frame = CGRectMake(leftMargin, 0.0, width - leftMargin - kMarginRight, viewHeight - 0.0 - 11.0);
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return action == @selector(copy:);
}

- (void)copy:(id)sender
{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:_label.text];
}

- (void) setText:(NSString *)text
{
    _label.text = text;
}

#pragma mark - OACustomButtonDelegate

- (void)onLabelTapped:(NSInteger)tag
{
    [OAUtilities showMenuInView:self fromView:_label];
}

- (void)onLabelLongPressed:(NSInteger)tag
{
    [OAUtilities showMenuInView:self fromView:_label];
}

@end
