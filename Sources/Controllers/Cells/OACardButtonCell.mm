//
//  OACardButtonCell.mm
//  OsmAnd
//
//  Created by Skalii on 27.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACardButtonCell.h"
#import "OAColors.h"

@implementation OACardButtonCell

- (void) awakeFromNib
{
    [super awakeFromNib];

    self.buttonView.backgroundColor = UIColorFromARGB(color_primary_purple_10);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat horizontalInset = 12.;
    if (@available(iOS 15.0, *))
    {
        CGFloat buttonTitleWidth = [OAUtilities calculateTextBounds:self.buttonView.titleLabel.attributedText
                                                              width:self.buttonView.frame.size.width - horizontalInset * 2 - self.buttonView.imageView.frame.size.width].width;
        CGFloat imagePadding = self.buttonView.frame.size.width - (horizontalInset * 2 + buttonTitleWidth + 30.);

        UIButtonConfiguration *configuration = self.buttonView.configuration;
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

- (void) updateConstraints
{
    BOOL hasIcon = !self.iconView.hidden;
    BOOL hasDescription = !self.descriptionView.hidden;

    self.titleLeftMargin.active = hasIcon;
    self.titleNoIconLeftMargin.active = !hasIcon;

    self.descriptionLeftMargin.active = hasIcon;
    self.descriptionNoIconLeftMargin.active = !hasIcon;

    self.buttonLeftMargin.active = hasIcon;
    self.buttonNoIconLeftMargin.active = !hasIcon;

    self.titleBottomMargin.active = hasDescription;
    self.titleBottomNoDescriptionMargin.active = !hasDescription;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasIcon = !self.iconView.hidden;
        BOOL hasDescription = !self.descriptionView.hidden;

        res = res || self.titleLeftMargin.active != hasIcon;
        res = res || self.titleNoIconLeftMargin.active != !hasIcon;

        res = res || self.descriptionLeftMargin.active != hasIcon;
        res = res || self.descriptionNoIconLeftMargin.active != !hasIcon;

        res = res || self.buttonLeftMargin.active != hasIcon;
        res = res || self.buttonNoIconLeftMargin.active != !hasIcon;

        res = res || self.titleBottomMargin.active != hasDescription;
        res = res || self.titleBottomNoDescriptionMargin.active != !hasDescription;
    }
    return res;
}

- (void)showIcon:(BOOL)show
{
    self.iconView.hidden = !show;
}

- (void)showDescription:(BOOL)show
{
    self.descriptionView.hidden = !show;
}

@end
