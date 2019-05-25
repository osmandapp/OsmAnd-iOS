//
//  OAMapillaryImageCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapillaryImageCell.h"
#import "OAUtilities.h"

@implementation OAMapillaryImageCell
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
        username = [NSString stringWithFormat:@"@%@ ", username];
        [_usernameLabel setHidden:NO];
        UIFont *font = [UIFont systemFontOfSize:13.0];
        CGSize stringBox = [username sizeWithAttributes:@{NSFontAttributeName: font}];
        CGRect usernameFrame = _usernameLabel.frame;
        usernameFrame.size = stringBox;
        usernameFrame.origin.x = self.frame.size.width - stringBox.width;
        usernameFrame.origin.y = self.frame.size.height - stringBox.height;
        _usernameLabel.frame = usernameFrame;
        _usernameLabel.text = username;
    }
    
}

@end
