//
//  OAMapillaryImageCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImageCardCell.h"
#import "OAUtilities.h"

#define kDoubleMargin 16.0

@implementation OAImageCardCell
{
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) layoutSubviews
{
    [super layoutSubviews];
}

- (void) setUserName:(NSString *)username
{
    if (!username || username.length == 0)
        [_usernameLabel setHidden:YES];
    else
    {
        username = [NSString stringWithFormat:@"@%@", username];
        [_usernameLabel setHidden:NO];
        UIFont *font = [UIFont systemFontOfSize:13.0];
        CGSize stringBox = [username sizeWithAttributes:@{NSFontAttributeName: font}];
        CGRect usernameFrame = _usernameLabel.frame;
        stringBox.width += kDoubleMargin;
        stringBox.height += kDoubleMargin;
        usernameFrame.size = stringBox;
        usernameFrame.origin.x = self.frame.size.width - stringBox.width;
        usernameFrame.origin.y = self.frame.size.height - stringBox.height;
        _usernameLabel.frame = usernameFrame;
        _usernameLabel.text = username;
    }
    
}

@end
