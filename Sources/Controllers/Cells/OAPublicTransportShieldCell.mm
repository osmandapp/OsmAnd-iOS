//
//  OAPublicTransportShieldCell.m
//  OsmAnd
//
//  Created by Paul on 13/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportShieldCell.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OARouteSegmentShieldView.h"
#import "OAColors.h"

#define kRowHeight 54
#define kShieldHeight 32
#define kShieldMargin 16.0
#define kShieldY 16.
#define kViewSpacing 3.0
#define kArrowY 25.0

static UIFont *_shieldFont;

@implementation OAPublicTransportShieldCell
{
    NSArray<UIView *> *_views;
    UIImage *_arrowIcon;
    NSNumber *_quantity;
    
    BOOL _needsSafeAreaInset;
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
    NSMutableArray<NSString *> *titles = [NSMutableArray new];
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
        [titles addObject:@"abcdefg"];
        
        [arr addObject:shield];
        [self addSubview:shield];
        
        if (i != _quantity.integerValue - 1)
        {
            UIImageView *arrowView = [self createArrowImageView];
            [arr addObject:arrowView];
            [self addSubview:arrowView];
        }
    }
    _titles = [NSArray arrayWithArray:titles];
    _views = [NSArray arrayWithArray:arr];
}

- (void)layoutSubviews
{
    CGFloat margin = _needsSafeAreaInset ? OAUtilities.getLeftMargin : 0.;
    CGFloat width = self.frame.size.width - margin - kShieldMargin * 2;
    CGFloat currWidth = 0.0;
    NSInteger rowsCount = 1;
    
    for (NSInteger i = 0; i < _views.count; i++)
    {
        UIView *currView = _views[i];
        CGRect viewFrame = currView.frame;
        if ([currView isKindOfClass:OARouteSegmentShieldView.class])
        {
            OARouteSegmentShieldView *shieldView = (OARouteSegmentShieldView *) currView;
            viewFrame.size = CGSizeMake([OARouteSegmentShieldView getViewWidth:shieldView.shieldLabel.text], 36.);
        }
        else
        {
            viewFrame.size = CGSizeMake(20., 20.);
        }
        
        currWidth += viewFrame.size.width;
        if (i == 0)
        {
            viewFrame.origin = CGPointMake(margin + kShieldMargin, kShieldY);
        }
        else
        {
            currWidth += kViewSpacing;
            if (currWidth < width)
            {
                CGFloat additionalHeight = kRowHeight * (rowsCount - 1);
                CGRect prevRect = _views[i - 1].frame;
                viewFrame.origin = CGPointMake(CGRectGetMaxX(prevRect) + kViewSpacing, (i % 2) == 0 ? kShieldY + additionalHeight : kArrowY + additionalHeight);
            }
            else
            {
                currWidth = viewFrame.size.width + kViewSpacing;
                rowsCount++;
                CGFloat additionalHeight = kRowHeight * (rowsCount - 1);
                viewFrame.origin = CGPointMake(margin + kShieldMargin, (i % 2) == 0. ? kShieldY + additionalHeight : (kShieldY * 2) + additionalHeight);
            }
        }
        currView.frame = viewFrame;
    }
}

- (UIImageView *) createArrowImageView
{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., 20., 20.)];
    imgView.tintColor = UIColorFromRGB(color_tint_gray);
    imgView.image = _arrowIcon;
    return imgView;
}

+ (CGFloat) getCellHeight:(CGFloat)width shields:(NSArray<NSString *> *)shields
{
    return [self getCellHeight:width shields:shields needsSafeArea:YES];
}

+ (CGFloat) getCellHeight:(CGFloat)width shields:(NSArray<NSString *> *)shields needsSafeArea:(BOOL)needsSafeArea
{
    CGFloat margin = needsSafeArea ? OAUtilities.getLeftMargin : 0.;
    width = width - margin - kShieldMargin * 2;
    if (!_shieldFont)
        _shieldFont = [UIFont systemFontOfSize:15];
    
    CGFloat currWidth = 0.0;
    NSInteger rowsCount = 1;
    
    for (NSInteger i = 0; i < shields.count; i++)
    {
        NSString *shieldTitle = shields[i];
        currWidth += [OARouteSegmentShieldView getViewWidth:shieldTitle];
        
        if (i != shields.count - 1)
        {
            currWidth += 20.;
        }
        
        currWidth += kViewSpacing;
        if (currWidth >= width)
        {
            rowsCount++;
            currWidth = 0.;
        }
    }
    return kRowHeight * rowsCount;
}

/*
 This method is required because auto-layout doesn't take safe area into consideration
 when the tableview is embedded into UIPageViewController
 */

- (void) needsSafeAreaInsets:(BOOL)needsInsets
{
    _needsSafeAreaInset = needsInsets;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _needsSafeAreaInset = YES;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
