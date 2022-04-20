//
//  OACustomButton.mm
//  OsmAnd
//
//  Created by Skalii on 15.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACustomLabel.h"

@implementation OACustomLabel
{
    UITapGestureRecognizer *_tapToCopyRecognizer;
    UILongPressGestureRecognizer *_longPressToCopyRecognizer;
}

- (instancetype)initWithFrame:(CGRect)frame tapToCopy:(BOOL)tapToCopy longPressToCopy:(BOOL)longPressToCopy
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit:tapToCopy longPressToCopy:longPressToCopy];
    }
    return self;
}

- (void)commonInit:(BOOL)tapToCopy longPressToCopy:(BOOL)longPressToCopy
{
    [self setUserInteractionEnabled:tapToCopy || longPressToCopy];
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
    [pb setString:self.text];
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
