//
//  OAMapRulerView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapRulerView.h"
#import <QuartzCore/QuartzCore.h>
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAOsmAndFormatter.h"
#import "OAColors.h"
#import "OAShapeLayer.h"

#define kAnimationDuration .2
#define kBlurBackgroundTag -999

@interface OAMapRulerView()

@property (strong, nonatomic) UILabel* textLabel;

@property UIView *bottomBorder;
@property UIView *leftBorder;
@property UIView *rightBorder;

@property UIVisualEffectView *blurView;

@end

@implementation OAMapRulerView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            // Add a bottomBorder.
            self.bottomBorder = [[UIView alloc] init];
            self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
            [self addSubview:self.bottomBorder];
            
            // Add a leftBorder.
            self.leftBorder = [[UIView alloc] init];
            self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
            [self addSubview:self.leftBorder];
            
            // Add a rightBorder.
            self.rightBorder = [[UIView alloc] init];
            self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
            [self addSubview:self.rightBorder];
            
            // Add border outline
            self.blurView.frame = CGRectMake(-2.5, self.frame.size.height - 12.5, self.frame.size.width + 5., 16.);
            [self applyBlurMask];
        }];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.frame.size.height - 20, self.frame.size.width - 10, 15)];
        [self.textLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        self.textLabel.adjustsFontForContentSizeCategory = YES;
        [self addSubview:self.textLabel];
        CGRect frame = self.frame;
        frame.size.width = 0;
        self.frame = frame;
        self.hidden = true;
        
        [self updateColors];
    }

    return self;
}

- (void) addBlurBackground:(BOOL)light cornerRadius:(CGFloat)cornerRadius padding:(CGFloat)padding
{
    self.backgroundColor = [UIColor clearColor];
    UIBlurEffect *blurEffect;

    blurEffect = [UIBlurEffect effectWithStyle:light
                ? UIBlurEffectStyleSystemUltraThinMaterialLight : UIBlurEffectStyleSystemUltraThinMaterialDark];

    UIView *blurView;
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        blurView = [[UIView alloc] init];
        blurView.backgroundColor = UIColorFromRGB(color_dialog_transparent_bg_argb_light);
    }
    blurView.tag = kBlurBackgroundTag;
    blurView.userInteractionEnabled = NO;
    if (cornerRadius > 0)
    {
        blurView.layer.cornerRadius = cornerRadius;
        blurView.layer.masksToBounds = YES;
    }

    [self insertSubview:blurView atIndex:0];

    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textLabel.leadingAnchor constraintEqualToAnchor:blurView.leadingAnchor constant:padding].active = YES;
    [self.textLabel.trailingAnchor constraintEqualToAnchor:blurView.trailingAnchor constant:-padding].active = YES;
    [self.textLabel.topAnchor constraintEqualToAnchor:blurView.topAnchor constant:padding / 2].active = YES;
    [self.textLabel.bottomAnchor constraintEqualToAnchor:blurView.bottomAnchor constant:-padding / 2].active = YES;
}

- (void) removeBlurBackground
{
    for (UIView *view in self.subviews)
    {
        if (view.tag == kBlurBackgroundTag)
        {
            [view removeFromSuperview];
            return;
        }
    }
}

- (BOOL) hasNoData
{
    return self.textLabel.text.length == 0;
}

- (void) updateColors
{
    if([OAAppSettings sharedManager].nightMode)
        [self setNight];
    else
        [self setDay];
}

- (void)setupRulerBlurView:(UIBlurEffectStyle)effect
{
    [self.blurView removeFromSuperview];
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:effect];
    UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.blurView.layer.masksToBounds = YES;
    [self.blurView.contentView addSubview:vibrancyView];
    [self insertSubview:self.blurView atIndex:0];
}

- (void) setDay
{
    self.bottomBorder.layer.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    self.leftBorder.layer.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    self.rightBorder.layer.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    self.textLabel.textColor = UIColor.blackColor;
    
    [self setupRulerBlurView:UIBlurEffectStyleSystemUltraThinMaterialLight];
    [self removeBlurBackground];
    [self addBlurBackground:YES cornerRadius:4. padding:2.];
}

- (void) setNight
{
    self.bottomBorder.layer.backgroundColor = UIColorFromRGB(color_icon_color_light).CGColor;
    self.leftBorder.layer.backgroundColor = UIColorFromRGB(color_icon_color_light).CGColor;
    self.rightBorder.layer.backgroundColor = UIColorFromRGB(color_icon_color_light).CGColor;
    self.textLabel.textColor = UIColorFromRGB(color_icon_color_light);
    
    [self setupRulerBlurView:UIBlurEffectStyleSystemUltraThinMaterialDark];
    [self removeBlurBackground];
    [self addBlurBackground:NO cornerRadius:4. padding:2.];
}

- (void)applyBlurMask
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:kAnimationDuration];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    [path addLineToPoint:CGPointMake(6., 0.)];
    [path addLineToPoint:CGPointMake(6., self.blurView.frame.size.height - 6.)];
    [path addLineToPoint:CGPointMake(self.blurView.frame.size.width - 6., self.blurView.frame.size.height - 6.)];
    [path addLineToPoint:CGPointMake(self.blurView.frame.size.width - 6., 0.)];
    [path addLineToPoint:CGPointMake(self.blurView.frame.size.width, 0.)];
    [path addLineToPoint:CGPointMake(self.blurView.frame.size.width, self.blurView.frame.size.height)];
    [path addLineToPoint:CGPointMake(0., self.blurView.frame.size.height)];
    [path addLineToPoint:CGPointZero];
    
    OAShapeLayer *maskLayer = [OAShapeLayer layer];
    maskLayer.frame = self.blurView.bounds;
    
    self.blurView.layer.mask = maskLayer;
    maskLayer.path = path.CGPath;
    [CATransaction commit];
}

- (void) invalidateLayout
{
    [UIView animateWithDuration:kAnimationDuration delay:0. options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
        self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
        self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
        self.blurView.frame = CGRectMake(-2.5, self.frame.size.height - 12.5, self.frame.size.width + 5., 16.);
        [self applyBlurMask];
    } completion:nil];
    
}

- (void) setRulerData:(float)metersPerPixel
{
    double metersPerMaxSize = metersPerPixel * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
    int rulerWidth = 0;
    NSString * vl = @"";
    if (metersPerPixel > 0 && metersPerPixel < 10000000.0)
    {
        double roundedDist = [OAOsmAndFormatter calculateRoundedDist:metersPerMaxSize];
        rulerWidth =  (roundedDist / metersPerPixel) / [[UIScreen mainScreen] scale];
        if (rulerWidth < 0)
            rulerWidth = 0;
        else
            vl = [OAOsmAndFormatter getFormattedDistance: roundedDist withParams:[OAOsmAndFormatterParams noTrailingZerosParams]];
    }
    CGRect frame = self.frame;
    self.hidden = rulerWidth == 0 ? true : false;
    frame.size.width = rulerWidth;
    self.frame = frame;
    [self invalidateLayout];
    [self.textLabel setText:vl];
    
    CGFloat labelWidth = [OAUtilities calculateTextBounds:_textLabel.text width:DeviceScreenWidth font:_textLabel.font].width;
    CGRect textLabelFrame = _textLabel.frame;
    textLabelFrame.size.width = labelWidth;
    _textLabel.frame = textLabelFrame;
}


@end
