//
//  OASubscriptionBannerCardView.mm
//  OsmAnd
//
//  Created by Skalii on 13.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASubscriptionBannerCardView.h"
#import "OAIAPHelper.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

#define kButtonIconSideSize 30.
#define kIconSideSize 48.
#define kSeparatorHeight .5
#define kButtonPrimaryHeight 44.
#define kButtonSecondaryHeight 36.

@implementation OASubscriptionBannerCardView

- (instancetype)initWithType:(EOASubscriptionBannerType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
        [self commonInit];
    }
    return self;
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

- (void)commonInit
{
    [NSBundle.mainBundle loadNibNamed:@"OASubscriptionBannerCardView" owner:self options:nil];
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;

    self.backgroundColor = UIColorFromRGB(color_banner_background);

    self.separatorView.backgroundColor = [UIColor colorWithWhite:1. alpha:0.1];
    self.iconView.tintColor = UIColorFromRGB(color_primary_table_background);
}

- (void)updateView
{
    self.freeMapsCount = [OAIAPHelper freeMapsAvailable];
    self.titleLabel.attributedText = [self getAttributedTitleText:_type freeMapsCount:self.freeMapsCount];
    [self.buttonView setAttributedTitle:[self getAttributedButtonText:_type] forState:UIControlStateNormal];

    switch(_type)
    {
        case EOASubscriptionBannerFree:
        {
            self.separatorView.hidden = NO;
            self.descriptionLabel.hidden = NO;
            self.descriptionLabel.attributedText = [self getAttributedDescriptionText];

            self.iconView.image = [UIImage templateImageNamed:@"ic_custom_five_downloads_big"];
            self.iconView.tintColor = UIColor.whiteColor;

            self.buttonView.backgroundColor = UIColor.clearColor;
            self.buttonView.tintColor = UIColorFromRGB(color_banner_button);
            [self.buttonView setTitleColor:UIColorFromRGB(color_banner_button) forState:UIControlStateNormal];
            [self.buttonView setImage:nil forState:UIControlStateNormal];
            break;
        }
        case EOASubscriptionBannerNoFree:
        {
            self.separatorView.hidden = YES;
            self.descriptionLabel.hidden = NO;
            self.descriptionLabel.attributedText = [self getAttributedDescriptionText];

            self.iconView.image = [UIImage templateImageNamed:@"ic_custom_zero_downloads_big"];
            self.iconView.tintColor = UIColor.whiteColor;

            self.buttonView.backgroundColor = UIColorFromRGB(color_banner_button);
            self.buttonView.tintColor = UIColorFromRGB(color_primary_purple);
            [self.buttonView setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
            [self.buttonView setImage:[UIImage templateImageNamed:@"ic_custom_arrow_forward"]
                             forState:UIControlStateNormal];
            break;
        }
        case EOASubscriptionBannerUpdates:
        {
            self.separatorView.hidden = YES;
            self.descriptionLabel.hidden = YES;

            self.iconView.image = [UIImage templateImageNamed:@"ic_custom_osmand_pro_logo_monotone_big"];
            self.iconView.tintColor = UIColorFromRGB(color_banner_button);

            self.buttonView.backgroundColor = UIColorFromRGB(color_banner_button);
            self.buttonView.tintColor = UIColorFromRGB(color_primary_purple);
            [self.buttonView setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
            [self.buttonView setImage:[UIImage templateImageNamed:@"ic_custom_arrow_forward"]
                             forState:UIControlStateNormal];
            break;
        }
    }
    
    [self updateFrame];
}

- (void)updateFrame
{
    BOOL isFree = _type == EOASubscriptionBannerFree;

    CGSize titleSize = [OAUtilities calculateTextBounds:self.titleLabel.attributedText
                                                  width:DeviceScreenWidth - [OAUtilities getLeftMargin] * 2 - kPaddingOnSideOfContent - 16. - kIconSideSize];
    self.titleLabel.frame = CGRectMake([OAUtilities getLeftMargin] + 20., 16., titleSize.width, titleSize.height);

    CGSize buttonSize = [OAUtilities calculateTextBounds:[self.buttonView attributedTitleForState:UIControlStateNormal]
                                                   width:DeviceScreenWidth - ([OAUtilities getLeftMargin] + kPaddingOnSideOfContent + 12.) * 2 - kButtonIconSideSize - 16.];

    if (isFree && buttonSize.height < kButtonPrimaryHeight)
        buttonSize.height = kButtonPrimaryHeight;
    else if (isFree && buttonSize.height > kButtonPrimaryHeight)
        buttonSize.height += (11. * 2);
    else if (!isFree && buttonSize.height < kButtonSecondaryHeight)
        buttonSize.height = kButtonSecondaryHeight;
    else if (!isFree && buttonSize.height > kButtonSecondaryHeight)
        buttonSize.height += (9. * 2);

    CGFloat height = 0;

    if (isFree || _type == EOASubscriptionBannerNoFree)
    {
        self.iconView.frame = CGRectMake(DeviceScreenWidth - [OAUtilities getLeftMargin] - 10. - kIconSideSize, 16., kIconSideSize, kIconSideSize);
        CGFloat imageBlockHeight = self.iconView.frame.origin.y + kIconSideSize + 12.;
        CGFloat textBlockHeight = self.titleLabel.frame.origin.y + titleSize.height + 3.;
        CGSize descriptionSize = [OAUtilities calculateTextBounds:self.descriptionLabel.attributedText
                                                            width:DeviceScreenWidth - [OAUtilities getLeftMargin] * 2 - kPaddingOnSideOfContent - 16. - kIconSideSize];
        self.descriptionLabel.frame = CGRectMake([OAUtilities getLeftMargin] + kPaddingOnSideOfContent, textBlockHeight, descriptionSize.width, descriptionSize.height);
        textBlockHeight += descriptionSize.height;
        textBlockHeight += 12.;

        height = textBlockHeight > imageBlockHeight ? textBlockHeight : imageBlockHeight;

        if (isFree)
        {
            self.separatorView.frame = CGRectMake([OAUtilities getLeftMargin] + kPaddingOnSideOfContent,
                                                  height,
                                                  DeviceScreenWidth - [OAUtilities getLeftMargin] - kPaddingOnSideOfContent,
                                                  kSeparatorHeight);
            height += kSeparatorHeight;
        }

        self.buttonView.frame = CGRectMake([OAUtilities getLeftMargin] + kPaddingOnSideOfContent,
                                           height,
                                           DeviceScreenWidth - ([OAUtilities getLeftMargin] + kPaddingOnSideOfContent) * 2,
                                           buttonSize.height);
        height += buttonSize.height;

        if (isFree)
            height += 3.;
        else if (_type == EOASubscriptionBannerNoFree)
            height += 16.;
    }
    else if (_type == EOASubscriptionBannerUpdates)
    {
        self.iconView.frame = CGRectMake(DeviceScreenWidth - [OAUtilities getLeftMargin] - 10. - kIconSideSize, 10., kIconSideSize, kIconSideSize);
        CGFloat imageBlockHeight = self.iconView.frame.origin.y + kIconSideSize + 10.;
        CGFloat textBlockHeight = self.titleLabel.frame.origin.y + titleSize.height + 10.;

        height = textBlockHeight > imageBlockHeight ? textBlockHeight : imageBlockHeight;

        self.buttonView.frame = CGRectMake([OAUtilities getLeftMargin] + kPaddingOnSideOfContent,
                                           height,
                                           DeviceScreenWidth - ([OAUtilities getLeftMargin] + kPaddingOnSideOfContent) * 2,
                                           buttonSize.height);
        height += buttonSize.height;
        height += 16.;
    }

    CGRect bannerFrame = self.frame;
    bannerFrame.size.height = height;
    self.frame = bannerFrame;

    CGFloat contentHorizontalInset = isFree ? 0. : 12.;
    CGFloat iconWidth = isFree ? 0. : kButtonIconSideSize;
    if (@available(iOS 15.0, *))
    {
        CGFloat buttonTitleWidth = [OAUtilities calculateTextBounds:self.buttonView.titleLabel.attributedText
                                                              width:DeviceScreenWidth - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin] + contentHorizontalInset) * 2 - iconWidth].width;
        CGFloat imagePadding = DeviceScreenWidth - ((kPaddingOnSideOfContent + [OAUtilities getLeftMargin] + contentHorizontalInset) * 2 + buttonTitleWidth + iconWidth);

        UIButtonConfiguration *configuration = UIButtonConfiguration.plainButtonConfiguration;
        configuration.titleAlignment = UIButtonConfigurationTitleAlignmentLeading;
        configuration.imagePlacement = NSDirectionalRectEdgeTrailing;
        configuration.contentInsets = NSDirectionalEdgeInsetsMake(0., contentHorizontalInset, 0., contentHorizontalInset);
        configuration.imagePadding = imagePadding;

        self.buttonView.configuration = configuration;
        [self.buttonView setNeedsUpdateConfiguration];
    }
    else
    {
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0., contentHorizontalInset, 0., contentHorizontalInset);
        UIEdgeInsets titleInsets = UIEdgeInsetsMake(0., -iconWidth, 0., iconWidth + (isFree ? 0. : 16.));
        UIEdgeInsets imageInsets = UIEdgeInsetsMake(0., self.buttonView.frame.size.width - kButtonIconSideSize - contentHorizontalInset * 2, 0., 0.);

        self.buttonView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.buttonView.contentEdgeInsets = contentInsets;
        self.buttonView.titleEdgeInsets = titleInsets;
        self.buttonView.imageEdgeInsets = imageInsets;
    }
}

- (NSAttributedString *)getAttributedTitleText:(EOASubscriptionBannerType)type freeMapsCount:(NSInteger)freeMapsCount
{
    BOOL isUpdates = type == EOASubscriptionBannerUpdates;
    NSString *text = isUpdates ? OALocalizedString(@"subscription_banner_osmand_pro_title")
        : type == EOASubscriptionBannerFree ? [NSString stringWithFormat:OALocalizedString(@"subscription_banner_free_maps_title"), freeMapsCount]
        : OALocalizedString(@"subscription_banner_no_free_maps_title");
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = isUpdates ? 23.8 : 20.4;
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{
        NSParagraphStyleAttributeName: paragraphStyle,
        NSFontAttributeName: [UIFont scaledSystemFontOfSize:17. weight:isUpdates ? UIFontWeightRegular : UIFontWeightSemibold],
        NSForegroundColorAttributeName: UIColor.whiteColor }];
}

- (NSAttributedString *)getAttributedDescriptionText
{
    NSString *text = OALocalizedString(@"subscription_banner_free_maps_description");
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18.;
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{
        NSParagraphStyleAttributeName: paragraphStyle,
        NSFontAttributeName: [UIFont scaledSystemFontOfSize:15.],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1. alpha:.5] }];
}

- (NSAttributedString *)getAttributedButtonText:(EOASubscriptionBannerType)type
{
    NSString *text = type == EOASubscriptionBannerUpdates ? OALocalizedString(@"shared_string_get") : OALocalizedString(@"get_unlimited_access");
    BOOL isFree = type == EOASubscriptionBannerFree;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = isFree ? 22. : 18.;
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{
        NSParagraphStyleAttributeName: paragraphStyle,
        NSFontAttributeName: [UIFont scaledSystemFontOfSize:isFree ? 17. : 15. weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: isFree ? UIColorFromRGB(color_banner_button) : UIColorFromRGB(color_primary_purple) }];
}

- (IBAction)onButtonPressed
{
    if (self.delegate)
        [self.delegate onButtonPressed];
}

@end
