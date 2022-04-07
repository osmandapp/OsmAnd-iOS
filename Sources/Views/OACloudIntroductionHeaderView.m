//
//  OACloudIntroductionHeaderView.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudIntroductionHeaderView.h"
#import "OAColors.h"

#define kBorderWidth 2.

#define kFixedHeight 338.
#define kLabelOffset 40.

@interface OACloudIntroductionHeaderView ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *bannerView;
@property (weak, nonatomic) IBOutlet UIImageView *bannerMainImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@end

@implementation OACloudIntroductionHeaderView

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

- (void)commonInit
{
    [NSBundle.mainBundle loadNibNamed:@"OACloudIntroductionHeaderView" owner:self options:nil];
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
}

- (void)setUpViewWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image topButtonTitle:(NSString *)topButtonTitle bottomButtonTitle:(NSString *)bottomButtonTitle
{
    self.titleLabel.text = title;
    self.descriptionLabel.text = description;
    self.bannerMainImageView.image = image;
    [self.topButton setTitle:topButtonTitle forState:UIControlStateNormal];
    [self.bottomButton setTitle:bottomButtonTitle forState:UIControlStateNormal];
    
    // Add border to main image
    self.bannerMainImageView.layer.borderWidth = kBorderWidth;
    self.bannerMainImageView.layer.borderColor = UIColorFromARGB(color_purple_border).CGColor;
}

- (CGFloat)calculateViewHeight
{
    CGFloat labelWidth = DeviceScreenWidth - kLabelOffset - (OAUtilities.getLeftMargin * 2);
    CGFloat titleHeight = [OAUtilities calculateTextBounds:self.titleLabel.text width:labelWidth font:[UIFont systemFontOfSize:34. weight:UIFontWeightBold]].height;
    CGFloat descriptionHeight = [OAUtilities calculateTextBounds:self.descriptionLabel.text width:labelWidth font:[UIFont systemFontOfSize:15.]].height;
    return titleHeight + descriptionHeight + kFixedHeight;
}

- (IBAction)topButtonPressed
{
    if (self.delegate)
    {
        [self.delegate getOrRegisterButtonPressed];
    }
}

- (IBAction)bottomButtonPressed
{
    if (self.delegate)
    {
        [self.delegate logInButtonPressed];
    }
}

@end
