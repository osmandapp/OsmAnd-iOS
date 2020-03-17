//
//  OAPublicTransportShieldsView.m
//  OsmAnd
//
//  Created by Paul on 13.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportShieldsView.h"
#import "OARouteSegmentShieldView.h"
#import "OAColors.h"

#define kRowHeight 44
#define kShieldHeight 32
#define kShieldY 6
#define kViewSpacing 3.0

@implementation OAPublicTransportShieldsView
{
    NSArray<UIView *> *_views;
    UIImage *_arrowIcon;
    NSNumber *_quantity;
    
    NSInteger _rowsCount;
}

/*
 TODO: change to actual data
 */
-(void) setData:(NSNumber *)data
{
    _arrowIcon = [[UIImage imageNamed:@"ic_small_arrow_forward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _quantity = data;
    [self buildViews];
}

- (void) buildViews
{
    if (_views)
    {
        for (UIView *vw in _views)
        {
            [vw removeFromSuperview];
        }
    }
    NSMutableArray<UIView *> *arr = [NSMutableArray new];
    for (NSInteger i = 0; i < _quantity.integerValue; i++)
    {
        OARouteSegmentShieldView *shield = [[OARouteSegmentShieldView alloc] initWithColor:UIColor.blueColor title:@"abcdefg" iconName:@"ic_small_pedestrian" type:EOATransportShiledPedestrian];
        
        [arr addObject:shield];
        [self addSubview:shield];
        
        if (i != _quantity.integerValue - 1)
        {
            UIImageView *arrowView = [self createArrowImageView];
            [arr addObject:arrowView];
            [self addSubview:arrowView];
        }
    }
    _views = [NSArray arrayWithArray:arr];
}

- (void)layoutSubviews
{
    CGFloat width = self.frame.size.width;
    CGFloat currWidth = 0.0;
    _rowsCount = 1;
    
    for (NSInteger i = 0; i < _views.count; i++)
    {
        UIView *currView = _views[i];
        CGRect viewFrame = currView.frame;
        viewFrame.size = currView.intrinsicContentSize;
        currWidth += viewFrame.size.width;
        if (i == 0)
        {
            viewFrame.origin = CGPointMake(0., kShieldY);
        }
        else
        {
            currWidth += kViewSpacing;
            if (currWidth < width)
            {
                CGFloat additionalHeight = kRowHeight * (_rowsCount - 1);
                CGRect prevRect = _views[i - 1].frame;
                viewFrame.origin = CGPointMake(CGRectGetMaxX(prevRect) + kViewSpacing, (i % 2) == 0 ? kShieldY + additionalHeight : (kShieldY * 2) + additionalHeight);
            }
            else
            {
                currWidth = viewFrame.size.width + kViewSpacing;
                _rowsCount++;
                CGFloat additionalHeight = kRowHeight * (_rowsCount - 1);
                viewFrame.origin = CGPointMake(0., (i % 2) == 0. ? kShieldY + additionalHeight : (kShieldY * 2) + additionalHeight);
            }
        }
        currView.frame = viewFrame;
    }
    
    [self invalidateIntrinsicContentSize];
}

- (UIImageView *) createArrowImageView
{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., 20., 20.)];
    imgView.tintColor = UIColorFromRGB(color_tint_gray);
    imgView.image = _arrowIcon;
    return imgView;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(self.frame.size.width, kRowHeight * _rowsCount);
}

@end
