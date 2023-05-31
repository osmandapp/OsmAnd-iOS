//
//  OAKeyboardHintBar.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAKeyboardHintBar.h"

@implementation OAKeyboardHintBar

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OAKeyboardHintBar class]])
        {
            self = (OAKeyboardHintBar *) v;
            break;
        }
    }
    return self;
}

- (IBAction)buttonTapped:(id)sender
{
    if (self.delegate)
        [self.delegate keyboardHintBarDidTapButton];
}

@end
