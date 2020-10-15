//
//  OASettingSwitchCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASettingSwitchCell.h"

@implementation OASettingSwitchCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateConstraints
{
    BOOL hasImage = self.imgView.image != nil && !self.imageView.hidden;
    BOOL hasSecondaryImage = self.secondaryImgView.image != nil;

    self.textLeftMargin.active = hasImage;
    self.textLeftMarginNoImage.active = !hasImage;
    self.textRightMargin.active = hasSecondaryImage;
    self.textRightMarginNoImage.active = !hasSecondaryImage;

    self.descrLeftMargin.active = hasImage;
    self.descrLeftMarginNoImage.active = !hasImage;
    self.descrRightMargin.active = hasSecondaryImage;
    self.descrRightMarginNoImage.active = !hasSecondaryImage;

    self.textHeightPrimary.active = self.descriptionView.hidden;
    self.textHeightSecondary.active = !self.descriptionView.hidden;
    self.descrTopMargin.active = !self.descriptionView.hidden;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.imgView.image != nil && !self.imageView.hidden;
        BOOL hasSecondaryImage = self.secondaryImgView.image != nil;

        res = res || self.textLeftMargin.active != hasImage;
        res = res || self.textLeftMarginNoImage.active != !hasImage;
        res = res || self.textRightMargin.active != hasSecondaryImage;
        res = res || self.textRightMarginNoImage.active != !hasSecondaryImage;

        res = res || self.descrLeftMargin.active != hasImage;
        res = res || self.descrLeftMarginNoImage.active != !hasImage;
        res = res || self.descrRightMargin.active != hasSecondaryImage;
        res = res || self.descrRightMarginNoImage.active != !hasSecondaryImage;

        res = res || self.textHeightPrimary.active != self.descriptionView.hidden;
        res = res || self.textHeightSecondary.active != !self.descriptionView.hidden;
        res = res || self.descrTopMargin.active != !self.descriptionView.hidden;
    }
    return res;
}

- (void) setSecondaryImage:(UIImage *)image
{
    self.secondaryImgView.image = image.imageFlippedForRightToLeftLayoutDirection;
}

@end
