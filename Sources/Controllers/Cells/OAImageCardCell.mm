//
//  OAMapillaryImageCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImageCardCell.h"
#import "OAUtilities.h"

#define kTextMargin 4.0
#define urlTextMargin 32

@implementation OAImageCardCell

+ (NSString *)getCellIdentifier
{
    return @"OAImageCardCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGSize cellSize = self.bounds.size;
    CGSize indicatorSize = _loadingIndicatorView.frame.size;
    _loadingIndicatorView.frame = CGRectMake(cellSize.width / 2 - indicatorSize.width / 2,
                                             cellSize.height / 2 - indicatorSize.height / 2,
                                             indicatorSize.width,
                                             indicatorSize.height);
    CGSize urlTextViewSize = CGSizeMake(cellSize.width - urlTextMargin, cellSize.height - urlTextMargin);
    _urlTextView.frame = CGRectMake(16.0, 16.0, urlTextViewSize.width, urlTextViewSize.height);
    
}

- (void)applyBottomCornerRadius {
    UIBezierPath *maskPath = [UIBezierPath
                              bezierPathWithRoundedRect:_usernameLabel.bounds
                              byRoundingCorners:UIRectCornerBottomRight
                              cornerRadii:CGSizeMake(6, 6)
                              ];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
    _usernameLabel.layer.mask = maskLayer;
}

- (void) setUserName:(NSString *)username
{
    if (!username || username.length == 0)
    {
        [_usernameLabel setHidden:YES];
        [_usernameLabelShadow setHidden:YES];
    }
    else
    {
        username = [NSString stringWithFormat:@"@%@", username];
        [_usernameLabel setHidden:NO];
        [_usernameLabelShadow setHidden:NO];
        UIFont *font = [UIFont systemFontOfSize:13.0];
        CGSize stringBox = [username sizeWithAttributes:@{NSFontAttributeName: font}];
        CGRect usernameFrame = _usernameLabel.frame;
        stringBox.width += kTextMargin * 2;
        stringBox.height += kTextMargin;
        usernameFrame.size = stringBox;
        usernameFrame.origin.x = self.frame.size.width - stringBox.width;
        usernameFrame.origin.y = self.frame.size.height - stringBox.height;
        usernameFrame.size = stringBox;
        _usernameLabel.frame = usernameFrame;
        _usernameLabel.text = username;
        
        [self applyBottomCornerRadius];
    }
}

@end
