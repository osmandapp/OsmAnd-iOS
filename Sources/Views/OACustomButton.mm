//
//  OACustomButton.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACustomButton.h"

@implementation OACustomButton
{
    UITapGestureRecognizer *_tapToCopyRecognizer;
    UILongPressGestureRecognizer *_longPressToCopyRecognizer;
}

- (instancetype)initBySystemTypeWithTapToCopy:(BOOL)tapToCopy longPressToCopy:(BOOL)longPressToCopy
{
    self = [OACustomButton buttonWithType:UIButtonTypeSystem];
    if (self)
    {
        [self commonInit:tapToCopy longPressToCopy:longPressToCopy];
    }
    return self;
}

- (void)commonInit:(BOOL)tapToCopy longPressToCopy:(BOOL)longPressToCopy
{
    if (tapToCopy)
    {
        _tapToCopyRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
        [self addGestureRecognizer:_tapToCopyRecognizer];
    }
    if (longPressToCopy)
    {
        _longPressToCopyRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
        [self addGestureRecognizer:_longPressToCopyRecognizer];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.centerVertically)
        [self applyVerticalLayout];
}

- (void)applyVerticalLayout
{
    CGFloat spacingExt = 26.0;
    if (self.extraSpacing)
        spacingExt = 30.0;

    // the space between the image and text
    CGFloat spacing = 6.0;

    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = self.imageView.image.size;
    BOOL isRTL = [self isDirectionRTL];
    self.titleEdgeInsets = UIEdgeInsetsMake(
            0.0,
            isRTL ? 0.0 : - imageSize.width,
            - (spacingExt + spacing),
            isRTL ? - imageSize.width : 0.0);

    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width, self.titleLabel.frame.size.height * 2)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName : self.titleLabel.font}
                                                          context:nil].size;
    self.imageEdgeInsets = UIEdgeInsetsMake(
            -(titleSize.height + spacing),
            isRTL ? -titleSize.width : 0.0f,
            0.0f,
            isRTL ? 0.0f : -titleSize.width);

    // increase the content height to avoid clipping
    CGFloat edgeOffset = fabsf(titleSize.height - imageSize.height) / 2.0;
    self.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0.0, edgeOffset, 0.0);

    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (BOOL)canBecomeFirstResponder
{
    return _tapToCopyRecognizer != nil || _longPressToCopyRecognizer != nil;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)copy:(id)sender
{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:self.titleLabel.text];
}

- (void)showMenu:(id)sender
{
    [self becomeFirstResponder];

    UIMenuController *menuController = UIMenuController.sharedMenuController;
    if (!menuController.isMenuVisible)
    {
        if (@available(iOS 13.0, *))
        {
            [menuController showMenuFromView:self rect:self.bounds];
        }
        else
        {
            [menuController setTargetRect:self.bounds inView:self];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

@end
