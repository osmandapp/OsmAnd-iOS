//
//  OACollapsableCoordinatesView.m
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableCoordinatesView.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"
#import "OALocationConvert.h"
#import "OAPointDescription.h"
#import "OAButton.h"
#import "GeneratedAssetSymbols.h"

#define kButtonHeight 32.0
#define kDefaultZoomOnShow 16.0f

@interface OACollapsableCoordinatesView () <OAButtonDelegate>

@end

@implementation OACollapsableCoordinatesView
{
    NSArray<OAButton *> *_buttons;
    NSInteger _selectedButtonIndex;
    NSArray<FormattedCoordinateItem *> *_coordinates;
    UILabel *_viewLabel;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _lat = 0;
        _lon = 0;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame lat:(double)lat lon:(double)lon
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _lat = lat;
        _lon = lon;
        _coordinates = [CoordinateFormatBridge collapsedRowsWithLat:lat lon:lon];
        [self buildViews];
    }
    return self;
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self updateButtonBorderColor];
}

- (void) buildViews
{
    _viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMarginLeft, 5.0, 100, 20)];
    _viewLabel.numberOfLines = 0;
    _viewLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _viewLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _viewLabel.adjustsFontForContentSizeCategory = YES;
    _viewLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    _viewLabel.backgroundColor = [UIColor clearColor];
    _viewLabel.text = OALocalizedString(@"coordinates_copy_descr");
    
    [self addSubview:_viewLabel];
    
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:_coordinates.count];
    int i = 0;
    for (FormattedCoordinateItem *item in _coordinates)
    {
        OAButton *btn = [OAButton buttonWithType:UIButtonTypeSystem];
        if (item.prefix.length > 0)
        {
            NSString *full = [NSString stringWithFormat:@"%@: %@", item.prefix, item.text];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full];
            NSRange prefixRange = NSMakeRange(0, item.prefix.length + 2);
            [attr addAttribute:NSForegroundColorAttributeName
                         value:[UIColor colorNamed:ACColorNameTextColorSecondary]
                         range:prefixRange];
            [btn setAttributedTitle:attr forState:UIControlStateNormal];
        }
        else
        {
            [btn setTitle:item.text forState:UIControlStateNormal];
        }
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
        btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        btn.layer.cornerRadius = 4.0;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 0.8;
        btn.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
        btn.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        btn.tag = i++;
        [btn setBackgroundImage:[OAUtilities imageWithColor:[UIColor colorNamed:ACColorNameIconColorActive]] forState:UIControlStateHighlighted];
        btn.delegate = self;

        [self addSubview:btn];
        [buttons addObject:btn];
    }
    _buttons = [NSArray arrayWithArray:buttons];
}

- (void) updateButtonBorderColor
{
    if (_buttons)
    {
        for (OAButton *btn in _buttons)
        {
            btn.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
        }
    }
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 0;
    CGFloat viewHeight = 0;
    
    CGSize labelSize = [OAUtilities calculateTextBounds:_viewLabel.text width:width - 65.0 - 10.0 - 10.0 font:_viewLabel.font];
    _viewLabel.frame = CGRectMake(kMarginLeft, 5.0, labelSize.width, labelSize.height);
    
    viewHeight += labelSize.height + 10.0;
    y += viewHeight;
    
    int i = 0;
    for (OAButton *btn in _buttons)
    {
        if (i > 0)
        {
            y += kButtonHeight + 10.0;
            viewHeight += 10.0;
        }
        
        btn.frame = CGRectMake(kMarginLeft, y, width - kMarginLeft - kMarginRight, kButtonHeight);
        viewHeight += kButtonHeight;
        i++;
    }
    
    viewHeight += 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
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
    if (_buttons.count > _selectedButtonIndex && _coordinates.count > _selectedButtonIndex)
    {
        UIPasteboard.generalPasteboard.string = _coordinates[_selectedButtonIndex].copyText;
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    _selectedButtonIndex = tag;
    if (_buttons.count > _selectedButtonIndex)
    {
        OAButton *button = _buttons[_selectedButtonIndex];
        [UIView animateWithDuration:0.2 animations:^{
            button.layer.backgroundColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
            button.layer.borderColor = UIColor.clearColor.CGColor;
            button.tintColor = UIColor.whiteColor;
        }                completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                button.layer.backgroundColor = UIColor.clearColor.CGColor;
                button.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
                button.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            }];
        }];
        [OAUtilities showMenuInView:self fromView:button];
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    _selectedButtonIndex = tag;
    if (_buttons.count > _selectedButtonIndex)
        [OAUtilities showMenuInView:self fromView:_buttons[_selectedButtonIndex]];
}

@end
