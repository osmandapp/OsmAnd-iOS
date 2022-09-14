//
//  OASubscriptionBannerCardView.mm
//  OsmAnd
//
//  Created by Skalii on 13.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASubscriptionBannerCardView.h"
#import "OAColors.h"

#define kSeparatorHeight .5
#define kButtonHeight 36.

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
    self.iconView.tintColor = UIColorFromRGB(color_bottom_sheet_background);
}

- (void)layoutSubviews
{
    switch(_type)
    {
        case EOASubscriptionBannerFree:
        {
            self.descriptionLabel.hidden = NO;
            self.separatorView.hidden = NO;

            self.titleBottomMargin.active = YES;
            self.separatorBottomMargin.active = YES;
            self.buttonBottomMargin.active = YES;
            self.buttonBottomNoSeparatorMargin.active = NO;

            self.buttonView.backgroundColor = UIColor.clearColor;
            self.buttonView.tintColor = UIColorFromRGB(color_banner_button);
            [self.buttonView setImage:nil forState:UIControlStateNormal];

            break;
        }
        case EOASubscriptionBannerNoFree:
        {
            self.descriptionLabel.hidden = NO;
            self.separatorView.hidden = YES;

            self.titleBottomMargin.active = YES;
            self.separatorBottomMargin.active = NO;
            self.buttonBottomMargin.active = NO;
            self.buttonBottomNoSeparatorMargin.active = YES;

            self.buttonView.backgroundColor = UIColorFromRGB(color_banner_button);
            self.buttonView.tintColor = UIColorFromRGB(color_primary_purple);
            [self.buttonView setImage:[UIImage templateImageNamed:@"ic_custom_arrow_forward"]
                             forState:UIControlStateNormal];

            break;
        }
        case EOASubscriptionBannerUpdates:
        {
            self.descriptionLabel.hidden = YES;
            self.separatorView.hidden = YES;

            self.titleBottomMargin.active = NO;
            self.separatorBottomMargin.active = NO;
            self.buttonBottomMargin.active = NO;
            self.buttonBottomNoSeparatorMargin.active = YES;

            self.buttonView.backgroundColor = UIColorFromRGB(color_banner_button);
            self.buttonView.tintColor = UIColorFromRGB(color_primary_purple);
            [self.buttonView setImage:[UIImage templateImageNamed:@"ic_custom_arrow_forward"]
                             forState:UIControlStateNormal];

            break;
        }
    }

    CGRect frame = self.frame;
    frame.size.height = [self calculateViewHeight];
    self.frame = frame;

    CGFloat horizontalInset = _type == EOASubscriptionBannerFree ? 0. : 12.;
    if (@available(iOS 15.0, *))
    {
        CGFloat buttonTitleWidth = [OAUtilities calculateTextBounds:self.buttonView.titleLabel.attributedText
                                                              width:self.frame.size.width - (20. + [OAUtilities getLeftMargin] + horizontalInset) * 2 - 30.].width;
        CGFloat imagePadding = self.frame.size.width - ((20. + [OAUtilities getLeftMargin] + horizontalInset) * 2 + buttonTitleWidth + 30.);

        UIButtonConfiguration *configuration = UIButtonConfiguration.plainButtonConfiguration;
        configuration.titleAlignment = UIButtonConfigurationTitleAlignmentLeading;
        configuration.imagePlacement = NSDirectionalRectEdgeTrailing;
        configuration.contentInsets = NSDirectionalEdgeInsetsMake(0., horizontalInset, 0., horizontalInset);
        configuration.imagePadding = imagePadding;

        self.buttonView.configuration = configuration;
    }
    else
    {
        UIEdgeInsets contentInsets = self.buttonView.contentEdgeInsets;
        UIEdgeInsets titleInsets = self.buttonView.titleEdgeInsets;
        UIEdgeInsets imageInsets = self.buttonView.imageEdgeInsets;

        self.buttonView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        contentInsets.left = horizontalInset;
        contentInsets.right = horizontalInset;
        titleInsets.left = -self.buttonView.imageView.frame.size.width;
        titleInsets.right = self.buttonView.imageView.frame.size.width + 16.;
        imageInsets.left = self.buttonView.frame.size.width - self.buttonView.imageView.frame.size.width - horizontalInset * 2;
        imageInsets.right = 0.;

        self.buttonView.contentEdgeInsets = contentInsets;
        self.buttonView.titleEdgeInsets = titleInsets;
        self.buttonView.imageEdgeInsets = imageInsets;
    }
}

- (CGFloat)calculateViewHeight
{
    CGFloat titleHeight = [OAUtilities calculateTextBounds:self.titleLabel.text
                                                     width:self.frame.size.width - self.iconView.frame.size.width - 16. - self.titleLabel.frame.origin.x - 10.
                                                      font:self.titleLabel.font].height;

    CGFloat buttonHeight = [OAUtilities calculateTextBounds:self.buttonView.titleLabel.attributedText
                                                      width:DeviceScreenWidth - 20. * 2].height;
    if (buttonHeight < kButtonHeight)
        buttonHeight = kButtonHeight;

    CGFloat height = self.titleLabel.frame.origin.y;

    switch(_type)
    {
        case EOASubscriptionBannerFree:
        {
            CGFloat textBlockHeight = titleHeight;
            textBlockHeight += self.titleBottomMargin.constant;
            CGFloat descriptionHeight = [OAUtilities calculateTextBounds:self.descriptionLabel.text
                                                                   width:self.frame.size.width - self.iconView.frame.size.width - 16. - self.descriptionLabel.frame.origin.x - 10.
                                                                    font:self.descriptionLabel.font].height;
            textBlockHeight += descriptionHeight;
            textBlockHeight += self.descriptionBottomMargin.constant;

            CGFloat imageBlockHeight = self.iconView.frame.size.height + self.iconBottomMargin.constant;

            if (textBlockHeight > imageBlockHeight)
            {
                height += textBlockHeight;
                self.descriptionBottomMargin.active = YES;
                self.iconBottomMargin.active = NO;
            }
            else
            {
                height += imageBlockHeight;
                self.descriptionBottomMargin.active = NO;
                self.iconBottomMargin.active = YES;
            }

            height += kSeparatorHeight;
            height += self.separatorBottomMargin.constant;
            height += buttonHeight;
            height += self.buttonBottomMargin.constant;
            break;
        }
        case EOASubscriptionBannerNoFree:
        {
            CGFloat textBlockHeight = titleHeight;
            textBlockHeight += self.titleBottomMargin.constant;
            CGFloat descriptionHeight = [OAUtilities calculateTextBounds:self.descriptionLabel.text
                                                                   width:self.frame.size.width - self.iconView.frame.size.width - 16. - self.descriptionLabel.frame.origin.x - 10.
                                                                    font:self.descriptionLabel.font].height;
            textBlockHeight += descriptionHeight;
            textBlockHeight += self.descriptionBottomNoSeparatorMargin.constant;

            CGFloat imageBlockHeight = self.iconView.frame.size.height + self.iconBottomNoSeparatorMargin.constant;

            if (textBlockHeight > imageBlockHeight)
            {
                height += textBlockHeight;
                self.descriptionBottomNoSeparatorMargin.active = YES;
                self.iconBottomNoSeparatorMargin.active = NO;
            }
            else
            {
                height += imageBlockHeight;
                self.descriptionBottomNoSeparatorMargin.active = NO;
                self.iconBottomNoSeparatorMargin.active = YES;
            }

            height += buttonHeight;
            height += self.buttonBottomNoSeparatorMargin.constant;
            break;
        }
        case EOASubscriptionBannerUpdates:
        {
            CGFloat textBlockHeight = titleHeight;
            textBlockHeight += self.titleBottomNoDescriptionMargin.constant;

            CGFloat imageBlockHeight = self.iconView.frame.size.height + self.iconBottomNoSeparatorMargin.constant;
            if (textBlockHeight > imageBlockHeight)
            {
                height += textBlockHeight;
                self.titleBottomNoDescriptionMargin.active = YES;
                self.iconBottomNoSeparatorMargin.active = NO;
            }
            else
            {
                height += imageBlockHeight;
                self.titleBottomNoDescriptionMargin.active = NO;
                self.iconBottomNoSeparatorMargin.active = YES;
            }

            height += buttonHeight;
            height += self.buttonBottomNoSeparatorMargin.constant;
            break;
        }
    }

    return height;
}

- (IBAction)onButtonPressed
{
    if (self.delegate)
        [self.delegate onButtonPressed];
}

@end
