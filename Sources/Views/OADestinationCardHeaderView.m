//
//  OADirectionCardHeaderView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCardHeaderView.h"
#import "OAUtilities.h"


@implementation OADestinationCardHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, DESTINATION_CARD_TOP_INSET, frame.size.width, frame.size.height - DESTINATION_CARD_TOP_INSET)];
        _containerView.backgroundColor = [UIColor whiteColor];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [self addSubview:self.containerView];
        
        CGFloat w = _containerView.frame.size.width - DESTINATION_CARD_BORDER * 2.0;

        _title = [[UILabel alloc] initWithFrame:CGRectMake(DESTINATION_CARD_BORDER, 0.0, w, _containerView.frame.size.height)];
        _title.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        _title.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
        _title.textColor = UIColorFromRGB(0x000000);
        [_containerView addSubview:self.title];

        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(_containerView.frame.size.width - 10.0, 0.0, 10.0, _containerView.frame.size.height);
        _rightButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_rightButton setTitleColor:UIColorFromRGB(0x587BF8) forState:UIControlStateNormal];
        _rightButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _rightButton.hidden = YES;
        [_containerView addSubview:self.rightButton];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [OAUtilities roundCornersOnView:self.containerView onTopLeft:YES topRight:YES bottomLeft:NO bottomRight:NO radius:4.0];
}

- (void)setRightButtonTitle:(NSString *)title
{
    CGFloat w = [OAUtilities calculateTextBounds:title width:1000.0 font:_rightButton.titleLabel.font].width + DESTINATION_CARD_BORDER * 2.0;
    _rightButton.frame = CGRectMake(_containerView.frame.size.width - w, _rightButton.frame.origin.y, w, _rightButton.frame.size.height);
    [_rightButton setTitle:title forState:UIControlStateNormal];
    _rightButton.hidden = NO;
    
    _title.frame = CGRectMake(DESTINATION_CARD_BORDER, 0.0, _rightButton.frame.origin.x - DESTINATION_CARD_BORDER * 2.0, _containerView.frame.size.height);
}


@end
