//
//  OAPublicTransportRouteShieldCell.m
//  OsmAnd
//
//  Created by Paul on 17/10/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAPublicTransportRouteShieldCell.h"
#import "OAUtilities.h"

@implementation OAPublicTransportRouteShieldCell
{
    UITapGestureRecognizer *_tapRecognizer;
    UILongPressGestureRecognizer *_longTapRecognizer;
    
    UIColor *_color;
}

+ (NSString *) getCellIdentifier
{
    return @"OAPublicTransportRouteShieldCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    _routeShieldContainerView.layer.cornerRadius = 4.;
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTapped:)];
    _tapRecognizer.numberOfTapsRequired = 1;
    _longTapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPressed:)];
    _longTapRecognizer.numberOfTouchesRequired = 1;
    _longTapRecognizer.minimumPressDuration = .2;
    
    [_routeShieldContainerView addGestureRecognizer:_tapRecognizer];
    [_routeShieldContainerView addGestureRecognizer:_longTapRecognizer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setShieldColor:(UIColor *)color
{
    _color = color;
    _routeShieldContainerView.backgroundColor = _color;
    UIColor *tintColor = [OAUtilities isColorBright:_color] ? [UIColor.blackColor colorWithAlphaComponent:0.9] : UIColor.whiteColor;
    _iconView.tintColor = tintColor;
    _textView.textColor = tintColor;
}

- (void) onViewTapped:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self animatePress:NO];
        [_delegate onShileldPressed:_routeShieldContainerView.tag];
}

- (void) onViewPressed:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self animatePress:YES];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self restoreShieldState];
        [_delegate onShileldPressed:_routeShieldContainerView.tag];
    }
}

- (void)animatePress:(BOOL)longPress
{
    [UIView animateWithDuration:.2 animations:^{
        [_iconView setTintColor:UIColor.grayColor];
        _textView.textColor = UIColor.grayColor;
    } completion:^(BOOL finished) {
        if (!longPress)
        {
            [self restoreShieldState];
        }
    }];
}

- (void)restoreShieldState {
    [UIView animateWithDuration:.2 animations:^{
        UIColor *tintColor = [OAUtilities isColorBright:_color] ? [UIColor.blackColor colorWithAlphaComponent:0.9] : UIColor.whiteColor;
        _textView.textColor = tintColor;
        _iconView.tintColor = tintColor;
    }];
}

@end
