//
//  OACloudIntroductionHeaderView.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudIntroductionHeaderView.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kBorderWidth 2.

#define kFixedHeight 300
#define kLabelOffset 40.

#define kImageWidth 52.
#define kBaseImagesCount 5
#define kAnimationDuration 50.

@interface OACloudIntroductionHeaderView ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *bannerView;
@property (weak, nonatomic) IBOutlet UIImageView *bannerMainImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation OACloudIntroductionHeaderView
{
    NSMutableArray<UIView *> *_animatedViews;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)addAnimatedViews
{
    for (UIView *view in _animatedViews)
    {
        [view removeFromSuperview];
    }
    [_animatedViews removeAllObjects];
    NSArray<UIImage *> *myPlacesImages = @[[UIImage imageNamed:@"ic_custom_overlay_map"], [UIImage imageNamed:@"ic_custom_trip"],
                                           [UIImage imageNamed:@"ic_custom_settings"], [UIImage imageNamed:@"ic_custom_map_style"],
                                           [UIImage imageNamed:@"ic_custom_info"], [UIImage imageNamed:@"ic_profile_pedestrian"]];
    NSArray<UIImage *> *pluginsImages = @[[UIImage imageNamed:@"ic_custom_contour_lines"], [UIImage imageNamed:@"ic_custom_sound"],
                                          [UIImage imageNamed:@"ic_custom_osm_edits"], [UIImage imageNamed:@"ic_custom_routes"],
                                          [UIImage imageNamed:@"ic_custom_my_places"]];
    NSArray<UIImage *> *navImages = @[[UIImage imageNamed:@"ic_custom_favorites"], [UIImage imageNamed:@"ic_custom_map_languge"],
                                      [UIImage imageNamed:@"ic_custom_navigation"], [UIImage imageNamed:@"ic_custom_ruler"],
                                      [UIImage imageNamed:@"ic_profile_car"]];
    CGFloat maxY = [self animateBackground:myPlacesImages tintColor:UIColorFromRGB(color_banner_button) startY:0. rightToLeft:YES];
    maxY = [self animateBackground:pluginsImages tintColor:UIColorFromRGB(color_primary_purple) startY:maxY rightToLeft:NO];
    [self animateBackground:navImages tintColor:UIColorFromRGB(color_discount_save) startY:maxY rightToLeft:YES];
}

- (void)commonInit
{
    [NSBundle.mainBundle loadNibNamed:@"OACloudIntroductionHeaderView" owner:self options:nil];
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    
    _animatedViews = [NSMutableArray array];
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:34. weight:UIFontWeightBold];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        self.bannerMainImageView.layer.borderColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary].CGColor;
}

- (CGFloat)getCompoundImageWidth:(NSInteger)count
{
    CGFloat compoundImageWidth = kImageWidth * count;
    while (compoundImageWidth < DeviceScreenWidth) {
        compoundImageWidth += compoundImageWidth;
    }
    return compoundImageWidth;
}

- (CGFloat) animateBackground:(NSArray<UIImage *> *)images tintColor:(UIColor *)tintColor startY:(CGFloat)startY rightToLeft:(BOOL)rightToLeft
{
    CGFloat compoundImageWidth = [self getCompoundImageWidth:images.count];
    UIColor *fillColor = [self createPatternColorFromImages:images tintColor:tintColor];
    
    CGRect rect1 = CGRectMake(rightToLeft ? 0. : -compoundImageWidth, startY, compoundImageWidth, 52.);
    UIView *view1 = [[UIView alloc] initWithFrame:rect1];
    view1.backgroundColor = fillColor;
    [self.bannerView insertSubview:view1 belowSubview:self.bannerMainImageView];

    CGRect rect2 = CGRectMake(rightToLeft ? view1.frame.size.width : 0., startY, compoundImageWidth, 52.);
    UIView *view2 = [[UIView alloc] initWithFrame:rect2];
    view2.backgroundColor = fillColor;
    [self.bannerView insertSubview:view2 belowSubview:self.bannerMainImageView];
    
    [_animatedViews addObjectsFromArray:@[view1, view2]];
    CGFloat animationTimeCoef = compoundImageWidth / [self getCompoundImageWidth:kBaseImagesCount];
    [UIView animateWithDuration:kAnimationDuration * animationTimeCoef * UIScreen.mainScreen.scale delay:0. options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear animations:^{
        CGRect fr1;
        CGRect fr2;
        if (rightToLeft)
        {
            fr1 = CGRectOffset(view1.frame, -1 * view1.frame.size.width, 0.);
            fr2 = CGRectOffset(view2.frame, -1 * view2.frame.size.width, 0.);
        }
        else
        {
            fr1 = CGRectOffset(view1.frame, view1.frame.size.width, 0.);
            fr2 = CGRectOffset(view2.frame, view2.frame.size.width, 0.);
        }
        view1.frame = fr1;
        view2.frame = fr2;
    } completion:nil];
    
    return CGRectGetMaxY(rect1);
}

- (UIColor *) createPatternColorFromImages:(NSArray<UIImage *> *)images tintColor:(UIColor *)tintColor
{
    CGFloat circleWidth = 42.;
    CGSize size = CGSizeMake(kImageWidth * images.count, 52.);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    for (NSInteger i = 0; i < images.count; i++)
    {
        UIImage *img = [OAUtilities tintImageWithColor:images[i] color:tintColor];
        CGRect imgRect = CGRectMake(kImageWidth * i + 10., (size.height - img.size.height) / 2, img.size.width, img.size.height);
        [img drawInRect:imgRect];
        
        CGPoint center = CGPointMake(CGRectGetMidX(imgRect), CGRectGetMidY(imgRect));
        CGRect circleRect = CGRectMake(center.x - (circleWidth / 2), center.y - (circleWidth / 2), circleWidth, circleWidth);
        CGContextSetLineWidth(contextRef, 2.0);
        CGContextSetStrokeColorWithColor(contextRef, [[tintColor colorWithAlphaComponent:.1] CGColor]);
        CGContextStrokeEllipseInRect(contextRef, circleRect);
    }
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:resImage];
}

- (void)setUpViewWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image
{
    self.titleLabel.text = title;
    self.descriptionLabel.text = description;
    self.bannerMainImageView.image = image.imageFlippedForRightToLeftLayoutDirection;
    
    // Add border to main image
    self.bannerMainImageView.layer.borderWidth = kBorderWidth;
    self.bannerMainImageView.layer.borderColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary].CGColor;
}

- (CGFloat)calculateViewHeight
{
    CGFloat labelWidth = DeviceScreenWidth - kLabelOffset - (OAUtilities.getLeftMargin * 2);
    CGFloat titleHeight = [OAUtilities calculateTextBounds:self.titleLabel.text width:labelWidth font:[UIFont scaledSystemFontOfSize:34. weight:UIFontWeightBold]].height;
    CGFloat descriptionHeight = [OAUtilities calculateTextBounds:self.descriptionLabel.text width:labelWidth font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
    return titleHeight + descriptionHeight + kFixedHeight;
}

@end
