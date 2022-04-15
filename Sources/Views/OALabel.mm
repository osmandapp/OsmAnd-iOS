//
//  OAButton.mm
//  OsmAnd
//
//  Created by Skalii on 15.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OALabel.h"

@implementation OALabel

- (BOOL)canBecomeFirstResponder
{
    return self.delegate != nil && [self.delegate respondsToSelector:@selector(onCopy)];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)copy:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onCopy)])
        [self.delegate onCopy];
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
