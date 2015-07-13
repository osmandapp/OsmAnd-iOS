//
//  OADirectionCardHeaderView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCardHeaderView.h"
#import "OAUtilities.h"

static const CGFloat topInset = 9.0;
static const CGFloat border = 14.0;


@implementation OADestinationCardHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, topInset, frame.size.width, frame.size.height - topInset)];
        _containerView.backgroundColor = [UIColor whiteColor];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [OAUtilities roundCornersOnView:self.containerView onTopLeft:YES topRight:YES bottomLeft:NO bottomRight:NO radius:4.0];
        
        [self addSubview:self.containerView];
        
        CGFloat w = _containerView.frame.size.width / 2.0 - border * 2.0;

        _title = [[UILabel alloc] initWithFrame:CGRectMake(border, 0.0, w, _containerView.frame.size.height)];
        _title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _title.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13];
        _title.textColor = UIColorFromRGB(0x000000);
        [_containerView addSubview:self.title];

        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(_containerView.frame.size.width - w - border, 0.0, w, _containerView.frame.size.height);
        _rightButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13];
        [_rightButton setTitleColor:UIColorFromRGB(0x587BF8) forState:UIControlStateNormal];
        _rightButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_containerView addSubview:self.rightButton];
    }
    return self;
}

- (void)setRightButtonTitle:(NSString *)title
{
    CGFloat w = [OAUtilities calculateTextBounds:title width:1000.0 font:_rightButton.titleLabel.font].width + border * 2.0;
    _rightButton.frame = CGRectMake(_containerView.frame.size.width - w, 0.0, w, _containerView.frame.size.height);
    [_rightButton setTitle:title forState:UIControlStateNormal];
}


@end
