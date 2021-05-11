//
//  OAIconTextTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIconTextTableViewCell.h"

@implementation OAIconTextTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAIconTextTableViewCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.arrowIconView.image = self.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;
}

- (void) updateConstraints
{
    BOOL hasImage = self.iconView.image != nil && !self.iconView.hidden;
    BOOL hasSecondaryImage = self.arrowIconView.image != nil && !self.arrowIconView.hidden;

    self.textLeftMargin.active = hasImage;
    self.textLeftMarginNoImage.active = !hasImage;
    self.textRightMargin.active = hasSecondaryImage;
    self.textRightMarginNoImage.active = !hasSecondaryImage;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.iconView.image != nil && !self.iconView.hidden;
        BOOL hasSecondaryImage = self.arrowIconView.image != nil && !self.arrowIconView.hidden;

        res = res || self.textLeftMargin.active != hasImage;
        res = res || self.textLeftMarginNoImage.active != !hasImage;
        res = res || self.textRightMargin.active != hasSecondaryImage;
        res = res || self.textRightMarginNoImage.active != !hasSecondaryImage;
    }
    return res;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void) showImage:(BOOL)show
{
    self.iconView.hidden = !show;
}

@end
